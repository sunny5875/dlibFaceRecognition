//
//  DlibWrapper.h
//  faceRecognition
//
//  Created by 현수빈 on 2023/01/31.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#import "test.hpp"


@interface DlibWrapper : NSObject

- (instancetype)init;
- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects;
- (void)prepare;
- (void)executeFaceRecognize:(char*)url;


@end
