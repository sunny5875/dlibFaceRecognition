////
////  test.cpp
////  faceRecognition
////
////  Created by 현수빈 on 2023/02/07.
////
//// The contents of this file are in the public domain. See LICENSE_FOR_EXAMPLE_PROGRAMS.txt
//
//#include "dlib/dnn.h"
//#include "dlib/clustering.h"
//#include "dlib/string.h"
//#include "dlib/image_io.h"
//#include "dlib/image_processing/frontal_face_detector.h"
//
//
//using namespace dlib;
//using namespace std;
//
//template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
//using residual = add_prev1<block<N,BN,1,tag1<SUBNET>>>;
//
//template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
//using residual_down = add_prev2<avg_pool<2,2,2,2,skip1<tag2<block<N,BN,2,tag1<SUBNET>>>>>>;
//
//template <int N, template <typename> class BN, int stride, typename SUBNET>
//using block  = BN<con<N,3,3,1,1,relu<BN<con<N,3,3,stride,stride,SUBNET>>>>>;
//
//template <int N, typename SUBNET> using ares      = relu<residual<block,N,affine,SUBNET>>;
//template <int N, typename SUBNET> using ares_down = relu<residual_down<block,N,affine,SUBNET>>;
//
//template <typename SUBNET> using alevel0 = ares_down<256,SUBNET>;
//template <typename SUBNET> using alevel1 = ares<256,ares<256,ares_down<256,SUBNET>>>;
//template <typename SUBNET> using alevel2 = ares<128,ares<128,ares_down<128,SUBNET>>>;
//template <typename SUBNET> using alevel3 = ares<64,ares<64,ares<64,ares_down<64,SUBNET>>>>;
//template <typename SUBNET> using alevel4 = ares<32,ares<32,ares<32,SUBNET>>>;
//
//using anet_type = loss_metric<fc_no_bias<128,avg_pool_everything<
//                            alevel0<
//                            alevel1<
//                            alevel2<
//                            alevel3<
//                            alevel4<
//                            max_pool<3,3,2,2,relu<affine<con<32,7,7,2,2,
//                            input_rgb_image_sized<150>
//                            >>>>>>>>>>>>;
//
//std::vector<matrix<rgb_pixel>> jitter_image(
//    const matrix<rgb_pixel>& img
//);
//
//void test(char* url){
//    try
//    {
////        if (argc != 2)
////        {
////            cout << "Run this example by invoking it like this: " << endl;
////            cout << "   ./dnn_face_recognition_ex faces/bald_guys.jpg" << endl;
////            cout << endl;
////            cout << "You will also need to get the face landmarking model file as well as " << endl;
////            cout << "the face recognition model file.  Download and then decompress these files from: " << endl;
////            cout << "http://dlib.net/files/shape_predictor_5_face_landmarks.dat.bz2" << endl;
////            cout << "http://dlib.net/files/dlib_face_recognition_resnet_model_v1.dat.bz2" << endl;
////            cout << endl;
////            return 1;
////        }
//
//        frontal_face_detector detector = get_frontal_face_detector();
//        shape_predictor sp;
//        deserialize("shape_predictor_5_face_landmarks.dat") >> sp;
//        anet_type net;
//        deserialize("dlib_face_recognition_resnet_model_v1.dat") >> net;
//
//        matrix<rgb_pixel> img;
//        load_image(img, url);
//
//        std::vector<matrix<rgb_pixel>> faces;
//        for (auto face : detector(img))
//        {
//            auto shape = sp(img, face);
//            matrix<rgb_pixel> face_chip;
//            extract_image_chip(img, get_face_chip_details(shape,150,0.25), face_chip);
//            faces.push_back(move(face_chip));
//        }
//
//        if (faces.size() == 0)
//        {
//            cout << "No faces found in image!" << endl;
//            return;
//        }
//        std::vector<matrix<float,0,1>> face_descriptors = net(faces);
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
//
//        cout << "number of people found in the image: "<< num_clusters << endl;
//        cout << "face descriptor for one face: " << trans(face_descriptors[0]) << endl;
//        matrix<float,0,1> face_descriptor = mean(mat(net(jitter_image(faces[0]))));
//        cout << "jittered face descriptor for one face: " << trans(face_descriptor) << endl;
//        cout << "feknfkdnfknskd" << endl;
//    }
//    catch (std::exception& e)
//    {
//        cout << e.what() << endl;
//    }
//
//}
//std::vector<matrix<rgb_pixel>> jitter_image(const matrix<rgb_pixel>& img) {
//    thread_local dlib::rand rnd;
//
//    std::vector<matrix<rgb_pixel>> crops;
//    for (int i = 0; i < 100; ++i)
//        crops.push_back(jitter_image(img,rnd));
//
//    return crops;
//}
