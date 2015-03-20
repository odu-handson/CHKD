//
//  TrainingInfo.h
//  CHKD
//
//  Created by ravi pitapurapu on 9/16/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TrainingInfo : NSObject

+(TrainingInfo *) sharedInfo;

@property (nonatomic,assign) double trainingDistance1;
@property (nonatomic,assign) double trainingDistance2;
@property (nonatomic,assign) double trainingDistance3;

@property (nonatomic,assign) double numStepsFast;
@property (nonatomic,assign) double numStepsNormal;
@property (nonatomic,assign) double numStepsSlow;

@property (nonatomic,assign) double timeTakenFast;
@property (nonatomic,assign) double timeTakenNormal;
@property (nonatomic,assign) double timeTakenSlow;

@property (nonatomic,assign) double stepRateFast;
@property (nonatomic,assign) double stepRateNormal;
@property (nonatomic,assign) double stepRateSlow;

@property (nonatomic,assign) double distancePerStepFast;
@property (nonatomic,assign) double distancePerStepNormal;
@property (nonatomic,assign) double distancePerStepSlow;

@property (nonatomic,assign) double a;
@property (nonatomic,assign) double b;

@end
