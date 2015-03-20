//
//  TrainingInfo.m
//  CHKD
//
//  Created by ravi pitapurapu on 9/16/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import "TrainingInfo.h"

@implementation TrainingInfo

+(TrainingInfo *) sharedInfo
{
    static TrainingInfo *trainingInfo;
    @synchronized(self)
    {
        if (!trainingInfo)
            trainingInfo = [[TrainingInfo alloc] init];
        return trainingInfo;
    }
}

@end
