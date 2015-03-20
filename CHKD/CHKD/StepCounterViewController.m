//
//  ViewController.m
//  CHKD
//
//  Created by ravi pitapurapu on 9/15/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import "StepCounterViewController.h"

#import <CoreMotion/CoreMotion.h>

@interface StepCounterViewController ()

@property (weak, nonatomic) IBOutlet UILabel *lblSteps;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UITextView *txtTimeStamps;

@property (nonatomic, strong) CMStepCounter *stepCounter;
@property (nonatomic, strong) NSOperationQueue *motionQueue;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) NSDictionary *stepData;
@property (nonatomic, strong) NSMutableArray *stepsInfo;

@property (nonatomic,assign) NSInteger previousStepCount;

@end

@implementation StepCounterViewController

- (CMStepCounter *)stepCounter
{
    if(!_stepCounter)
        _stepCounter = [[CMStepCounter alloc] init];;
    
    return _stepCounter;
}

- (NSOperationQueue *)motionQueue
{
    if (_motionQueue == nil)
        _motionQueue = [NSOperationQueue new];
    
    return _motionQueue;
}

- (NSDateFormatter *)dateFormatter
{
    if(!_dateFormatter)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss.sss"];
    }
    
    return _dateFormatter;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.previousStepCount = 0;
    self.stepsInfo = [[NSMutableArray alloc] init];
}

- (void)updateStepLableWithCountedSteps:(NSInteger)numberOfSteps atTime:(NSDate *)timeStamp
{
    self.lblSteps.text = [NSString stringWithFormat:@"%ld", (long)numberOfSteps];
    self.txtTimeStamps.text = [NSString stringWithFormat:@"%@ \n %@",self.txtTimeStamps.text,[self getDateStringForDate:timeStamp]];
    
    NSInteger stepsInCurrentUpdate = [self getStepsInCurrentUpdateWithTotalNumberOfSteps:numberOfSteps];
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:[self getDateStringForDate:timeStamp],@"date",[NSNumber numberWithInt:(int)stepsInCurrentUpdate],@"steps",nil];
    //NSDictionary *data = @{@"date":[self getDateStringForDate:timeStamp],@"steps":[NSNumber numberWithInt:(int)stepsInCurrentUpdate]};
    [self.stepsInfo addObject:data];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStartTapped:(id)sender
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        [self.stepCounter startStepCountingUpdatesToQueue:self.motionQueue updateOn:1 withHandler:^(NSInteger numberOfSteps, NSDate *timestamp, NSError *error)
         {
             dispatch_async(dispatch_get_main_queue(), ^(void){
                 //Run UI Updates
                 [self updateStepLableWithCountedSteps:numberOfSteps atTime:timestamp];
             });
         }];
    });
}


- (IBAction)btnStopTapped:(id)sender
{
    [self.stepCounter stopStepCountingUpdates];
}


#pragma mark - Utility Methods
- (NSString *)getDateStringForDate:(NSDate *)date
{
    NSString *dateString = [self.dateFormatter stringFromDate:date];
    return dateString;
}

- (void)showStepCountingUnavailableAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Step Counter Unavailable" message:@"Step Counting unavailable for this device." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

- (NSInteger)getStepsInCurrentUpdateWithTotalNumberOfSteps:(NSInteger)totalSteps
{
    NSInteger returnVal = totalSteps;
    if(self.previousStepCount == 0)
        returnVal = totalSteps;
    else
        returnVal = totalSteps - self.previousStepCount;
    
    self.previousStepCount = totalSteps;
    return returnVal;
}

@end
