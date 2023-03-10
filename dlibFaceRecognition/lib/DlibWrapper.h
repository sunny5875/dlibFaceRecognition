//
//  DlibWrapper.h
//  faceRecognition
//
//  Created by νμλΉ on 2023/01/31.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface DlibWrapper : NSObject
- (instancetype)init;
- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects;
- (void)prepare;
- (NSMutableArray*)executeFaceRecognize;
- (NSMutableArray*)checkUserValid;
@end
