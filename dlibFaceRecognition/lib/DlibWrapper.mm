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
#include "dlib/image_transforms.h"

#include "dlib/dnn.h"
#include "dlib/clustering.h"
#include "dlib/string.h"
#include "dlib/image_processing/frontal_face_detector.h"

#import "test.hpp"


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

   
    
    // MARK: - 여기서부터 feature extract
//    NSLog(@"=== start feature extract ===");
//    dlib::array2d<dlib::rgb_pixel> img2;
//
//    CVImageBufferRef imageBuffer2 = CMSampleBufferGetImageBuffer(sampleBuffer);
//    CVPixelBufferLockBaseAddress(imageBuffer2, kCVPixelBufferLock_ReadOnly);
//
//    size_t width2 = CVPixelBufferGetWidth(imageBuffer2);
//    size_t height2 = CVPixelBufferGetHeight(imageBuffer2);
//    char *baseBuffer2 = (char *)CVPixelBufferGetBaseAddress(imageBuffer2);
//    // set_size expects rows, cols format
//    img2.set_size(height2, width2);
//
//    // copy samplebuffer image data into dlib image format
//    img2.reset();
//    long position2 = 0;
//    while (img2.move_next()) {
//        dlib::rgb_pixel& pixel = img2.element();
//
//        // assuming bgra format here
//        long bufferLocation = position2 * 4; //(row * width + column) * 4;
//        char r = baseBuffer2[bufferLocation];
//        char g = baseBuffer2[bufferLocation + 1];
//        char b = baseBuffer2[bufferLocation + 2];
//
//        dlib::rgb_pixel newpixel(r,g,b);
//        pixel = newpixel;
//        position2++;
//    }
//
//    dlib::array2d<dlib::matrix<float,31,1>> hog;
//    extract_fhog_features(img2, hog);
//    NSLog(@"hog image has %ld rows and %ld columns", hog.nr(), hog.nc());
//
//
//    NSLog(@"=== end extract ===");

    
    
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

- (void)executeFaceRecognize:(char *)url {
    NSLog(@"=== start extract ===");
    test(url);
    NSLog(@"=== end extract ===");
}

@end
