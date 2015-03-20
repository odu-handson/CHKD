//
//  UserData.m
//  CHKD
//
//  Created by ravi pitapurapu on 10/27/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import "UserData.h"

@interface UserData ()

@property (nonatomic, strong) NSUserDefaults *defaults;

@end

@implementation UserData

+(UserData *) sharedData
{
    static UserData *sharedData;
    @synchronized(self)
    {
        if (!sharedData)
            sharedData = [[UserData alloc] init];
        return sharedData;
    }
}

- (NSUserDefaults *)defaults
{
    if(!_defaults)
        _defaults = [NSUserDefaults standardUserDefaults];
    
    return _defaults;
}

- (void)saveA:(double)A
{
    [self.defaults setObject:[NSString stringWithFormat:@"%f",A] forKey:@"constantA"];
    self.A = A;
}

- (double)A
{
    double returnVal = [[self.defaults objectForKey:@"constantA"] doubleValue];
    return returnVal;
}

- (void)saveB:(double)B
{
    [self.defaults setObject:[NSString stringWithFormat:@"%f",B] forKey:@"constantB"];
    self.B = B;
}

- (double)B
{
    double returnVal = [[self.defaults objectForKey:@"constantB"] doubleValue];
    return returnVal;
}

- (void)saveC:(double)C
{
    [self.defaults setObject:[NSString stringWithFormat:@"%f",C] forKey:@"constantC"];
    self.C = C;
}

- (double)C
{
    double returnVal = [[self.defaults objectForKey:@"constantC"] doubleValue];
    return returnVal;
}

@end
