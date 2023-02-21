//
//  DlibWrapper.mm
//  faceRecognition
//
//  Created by 현수빈 on 2023/01/31.
//

#import "DlibWrapper.h"
#import <UIKit/UIKit.h>

#include "dlib/image_processing.h"
#include "dlib/image_io.h"
#include "test.hpp"

// for extract
#include "dlib/dnn.h"
#include "dlib/clustering.h"
#include "dlib/string.h"
#include "dlib/image_processing/frontal_face_detector.h"


using namespace dlib;
using namespace std;

template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual = add_prev1<block<N,BN,1,tag1<SUBNET>>>;

template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual_down = add_prev2<avg_pool<2,2,2,2,skip1<tag2<block<N,BN,2,tag1<SUBNET>>>>>>;

template <int N, template <typename> class BN, int stride, typename SUBNET>
using block  = BN<con<N,3,3,1,1,relu<BN<con<N,3,3,stride,stride,SUBNET>>>>>;

template <int N, typename SUBNET> using ares      = relu<residual<block,N,affine,SUBNET>>;
template <int N, typename SUBNET> using ares_down = relu<residual_down<block,N,affine,SUBNET>>;

template <typename SUBNET> using alevel0 = ares_down<256,SUBNET>;
template <typename SUBNET> using alevel1 = ares<256,ares<256,ares_down<256,SUBNET>>>;
template <typename SUBNET> using alevel2 = ares<128,ares<128,ares_down<128,SUBNET>>>;
template <typename SUBNET> using alevel3 = ares<64,ares<64,ares<64,ares_down<64,SUBNET>>>>;
template <typename SUBNET> using alevel4 = ares<32,ares<32,ares<32,SUBNET>>>;

using anet_type = loss_metric<fc_no_bias<128,avg_pool_everything<
                            alevel0<
                            alevel1<
                            alevel2<
                            alevel3<
                            alevel4<
                            max_pool<3,3,2,2,relu<affine<con<32,7,7,2,2,
                            input_rgb_image_sized<150>
                            >>>>>>>>>>>>;



@interface DlibWrapper ()

@property (assign) BOOL prepared;

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects;

@end


@implementation DlibWrapper {
    dlib::shape_predictor sp;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
    }
    return self;
}

- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
    
    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
}

- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects {
    
    if (!self.prepared) {
        [self prepare];
    }
    
    dlib::array2d<dlib::bgr_pixel> img;

    // MARK: magic
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);

    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);

    // set_size expects rows, cols format
    img.set_size(height, width);

    // copy samplebuffer image data into dlib image format
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();

        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];

        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;

        position++;
    }

    // unlock buffer again until we need it again
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);

    // convert the face bounds list to dlib format
    std::vector<dlib::rectangle> convertedRectangles = [DlibWrapper convertCGRectValueArray:rects];

    // for every detected face
    for (unsigned long j = 0; j < convertedRectangles.size(); ++j)
    {
        dlib::rectangle oneFaceRect = convertedRectangles[j];

        // detect all landmarks
        dlib::full_object_detection shape = sp(img, oneFaceRect);

        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            dlib::point p = shape.part(k);
            draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 255));
        }
    }


    // lets put everything back where it belongs
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    // copy dlib image data back into samplebuffer
    img.reset();
    position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();

        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        baseBuffer[bufferLocation] = pixel.blue;
        baseBuffer[bufferLocation + 1] = pixel.green;
        baseBuffer[bufferLocation + 2] = pixel.red;
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];

        position++;
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects {
    std::vector<dlib::rectangle> myConvertedRects;
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        long left = rect.origin.x;
        long top = rect.origin.y;
        long right = left + rect.size.width;
        long bottom = top + rect.size.height;
        dlib::rectangle dlibRect(left, top, right, bottom);

        myConvertedRects.push_back(dlibRect);
    }
    return myConvertedRects;
}

- (NSMutableArray*)executeFaceRecognize {
//    NSMutableString* arrayString = @"";
    NSMutableArray *arrayString=[[NSMutableArray alloc]init];
    
    try
    {
        frontal_face_detector detector = get_frontal_face_detector();
        shape_predictor sp;
        anet_type net;
        matrix<rgb_pixel> img;
        
        // MARK: -load shape_predictor_5_face_landmarks.dat
        NSURL *datUrl = [[NSBundle mainBundle] URLForResource:@"shape_predictor_5_face_landmarks" withExtension:@".dat"];
        NSLog(@"shape 주소: %@", datUrl.path);
        if (datUrl.path)    {
            char const *pPath = [datUrl.path cStringUsingEncoding:NSASCIIStringEncoding];
            if (pPath) {
                deserialize(pPath) >> sp;
            }
        }
        
        // MARK: -load dlib_face_recognition_resnet_model_v1.dat
        NSURL *datUrl2 = [[NSBundle mainBundle] URLForResource:@"dlib_face_recognition_resnet_model_v1" withExtension:@".dat"];
        NSLog(@"dlib 주소: %@", datUrl.path);
        
        if (datUrl2.path)    {
            char const *pPath = [datUrl2.path cStringUsingEncoding:NSASCIIStringEncoding];
            if (pPath) {
                deserialize(pPath) >> net;
            }
        }
        
        // MARK: -load image
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:@"face.jpeg"];
        
        NSLog(@"image 주소: %@", savedImagePath);
        
        if (savedImagePath)    {
            char const *pPath = [savedImagePath cStringUsingEncoding:NSASCIIStringEncoding];
            if (pPath) {
                load_image(img, pPath);
            }
        }
        
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        std::vector<matrix<rgb_pixel>> faces;
        for (auto face : detector(img))
        {
            auto shape = sp(img, face);
            matrix<rgb_pixel> face_chip;
            extract_image_chip(img, get_face_chip_details(shape,150,0.25), face_chip);
            faces.push_back(move(face_chip));
        }
        
        if (faces.size() == 0)
        {
            cout << "Not faces found in image!" << endl;
            return arrayString;
        }
        
        cout << faces.size() << endl;
        
        
         NSTimeInterval endtimeStamp = [[NSDate date] timeIntervalSince1970];

        std::vector<matrix<float,0,1>> face_descriptors = net(faces);
        
        
//        std::vector<sample_pair> edges;
//        for (size_t i = 0; i < face_descriptors.size(); ++i)
//        {
//            for (size_t j = i; j < face_descriptors.size(); ++j)
//            {
//                if (length(face_descriptors[i]-face_descriptors[j]) < 0.6)
//                    edges.push_back(sample_pair(i,j));
//            }
//        }
//        std::vector<unsigned long> labels;
//        const auto num_clusters = chinese_whispers(edges, labels);
//        cout << "number of people found in the image: "<< num_clusters << endl;
        
        
        for(int i = 0; i < faces.size(); i++) {
            matrix_op<op_trans<dlib::matrix<float, 0, 1>>> result = trans(face_descriptors[i]);

            cout << "face descriptor for one face: " << result << endl;
            
            for(auto it = result.begin(); it != result.end(); ++it) {
                NSString* str = [NSString stringWithFormat:@"%.7f", *it];
                [arrayString addObject:str];
            }
        }
        
        NSTimeInterval endtimeStamp1 = [[NSDate date] timeIntervalSince1970];
        NSLog(@"face detector time: %f", endtimeStamp-timeStamp);
        NSLog(@"net time: %f", endtimeStamp1-endtimeStamp);
      
        return arrayString;

    }
    catch (std::exception& e)
    {
        cout << e.what() << endl;
    }
    return arrayString;
}






@end
