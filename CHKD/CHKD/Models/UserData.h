//
//  UserData.h
//  CHKD
//
//  Created by ravi pitapurapu on 10/27/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserData : NSObject

+(UserData *) sharedData;

@property (nonatomic,assign) double trainingDistance1;
@property (nonatomic,assign) double trainingDistance2;
@property (nonatomic,assign) double trainingDistance3;

@property (nonatomic,assign) double numSteps1;
@property (nonatomic,assign) double numSteps2;
@property (nonatomic,assign) double numSteps3;

@property (nonatomic,assign) double timeTaken1;
@property (nonatomic,assign) double timeTaken2;
@property (nonatomic,assign) double timeTaken3;

@property (nonatomic,assign) double stepRate1;
@property (nonatomic,assign) double stepRate2;
@property (nonatomic,assign) double stepRate3;

@property (nonatomic,assign) double distancePerStep1;
@property (nonatomic,assign) double distancePerStep2;
@property (nonatomic,assign) double distancePerStep3;

@property (nonatomic,assign) double A;
@property (nonatomic,assign) double B;
@property (nonatomic,assign) double C;

@property (nonatomic, assign) double x1;
@property (nonatomic, assign) double x2;
@property (nonatomic, assign) double x3;

@property (nonatomic, assign) double y1;
@property (nonatomic, assign) double y2;
@property (nonatomic, assign) double y3;


@property (nonatomic,assign) NSString *userId;
@property (nonatomic,assign) NSDate *createdAt;
@property (nonatomic,assign) NSDate *updatedAt;
@property (nonatomic,strong) NSMutableArray *locations;


- (void)saveA:(double)A;
- (void)saveB:(double)B;
- (void)saveC:(double)C;

- (void)saveUserId:(NSString *) userId;
- (void)saveCreatedAt:(NSDate *)createdAt;
- (void)saveUpdatedAt:(NSDate *)updatedAt;

@end
