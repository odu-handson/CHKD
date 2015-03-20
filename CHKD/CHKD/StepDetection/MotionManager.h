//
//  StepDetectionContorller.h
//  CHKD
//
//  Created by ravi pitapurapu on 10/27/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kUpdateFrequency 60.0

@protocol StepDetectionProtocol

@optional

- (void)stepDetectedWithStepCount:(int)step_count;
- (void)stepDetectedWithStepCount:(int)step_count andSampleSize:(int)sampleSize;
- (void)strideDetectedWithCount:(int)stride_count andDuration:(double)duration;
- (void)strideDetectedWithCount:(int)stride_count duration:(double)duration andAngle:(double)angle;

@end

@interface MotionManager : NSObject

+(MotionManager *) sharedManager;
- (void)stopCountingSteps;
- (void)startCountingSteps;

@property (nonatomic,weak) id<StepDetectionProtocol> stepDelegate;

@end
