//
//  StepViewController.m
//  CHKD
//
//  Created by ravi pitapurapu on 10/26/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import "TrainingViewController.h"

#import <AudioToolbox/AudioToolbox.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#import "MotionManager.h"
#import "RBVolumeButtons.h"
#import "UserData.h"
#import "ServiceManager.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
//Nano second precision
#define timeUnit 1000000000

@interface TrainingViewController () <StepDetectionProtocol,ServiceProtocol>

@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, weak) IBOutlet UILabel            *lblStepCount;
@property (nonatomic, weak) IBOutlet UITextField        *txtDistance1;
@property (nonatomic, weak) IBOutlet UITextField        *txtDistance2;
@property (nonatomic, weak) IBOutlet UITextField        *txtDistance3;
@property (nonatomic, weak) IBOutlet UITextField        *txtSteps1;
@property (nonatomic, weak) IBOutlet UITextField        *txtSteps2;
@property (nonatomic, weak) IBOutlet UITextField        *txtSteps3;
@property (nonatomic, weak) IBOutlet UITextField        *txtTimeTaken1;
@property (nonatomic, weak) IBOutlet UITextField        *txtTimeTaken2;
@property (nonatomic, weak) IBOutlet UITextField        *txtTimeTaken3;
@property (nonatomic, weak) IBOutlet UILabel            *lblConstantA;
@property (nonatomic, weak) IBOutlet UILabel            *lblConstantB;
@property (nonatomic, weak) IBOutlet UILabel            *lblConstantC;
@property (nonatomic, weak) IBOutlet UIButton           *btnStartStop;
@property (nonatomic, weak) IBOutlet UIButton           *btnCalculate;
@property (nonatomic, strong) RBVolumeButtons           *buttonStealer;


@property (nonatomic, strong) NSMutableArray            *timeStamps;
@property (nonatomic, strong) UserData                  *userData;
@property (nonatomic, strong) MotionManager             *motionManager;
@property (nonatomic,assign) BOOL                       isCountingSteps;
@property (nonatomic, strong) ServiceManager    *serviceManager;
@property (nonatomic, strong) NSUserDefaults *defaults;



@end

@implementation TrainingViewController

double start;
double end;
double elapsed;
// Get information for converting from MTU to nanoseconds
mach_timebase_info_data_t info;

- (NSUserDefaults *)defaults
{
    if(!_defaults)
        _defaults = [NSUserDefaults standardUserDefaults];
    
    return _defaults;
}

- (UserData *)userData
{
    if(!_userData)
        _userData = [UserData sharedData];
    
    return _userData;
}

- (MotionManager *)motionManager
{
    if(!_motionManager)
    {
        _motionManager = [MotionManager sharedManager];
        _motionManager.stepDelegate = self;
    }
    
    return _motionManager;
}

- (ServiceManager *)serviceManager
{
    if(!_serviceManager)
    {
        _serviceManager = [ServiceManager defaultManager];
        _serviceManager.serviceDelegate = self;
    }
    
    return  _serviceManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self prepareButtonStealer];
    [self prepareUI];
    [self resetTimers];
    //[self mockInputs];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.buttonStealer stopStealingVolumeButtonEvents];
}

- (void)prepareButtonStealer
{
    self.buttonStealer = [[RBVolumeButtons alloc] init];
    __weak TrainingViewController *weakSelf = self;
    self.buttonStealer.upBlock = ^{
        [weakSelf btnStartStopTapped:weakSelf.btnStartStop];
    };
    self.buttonStealer.downBlock = ^{
        [weakSelf btnStartStopTapped:weakSelf.btnStartStop];
    };
    
    [self.buttonStealer startStealingVolumeButtonEvents];
}

- (void)mockInputs
{
    self.txtDistance1.text = @"550.750";
    self.txtDistance2.text = @"670.625";
    self.txtDistance3.text = @"458.6625r";
    
    self.txtSteps1.text = @"10";
    self.txtSteps2.text = @"10";
    self.txtSteps3.text = @"10";
    
    self.txtTimeTaken1.text = @"11.277603";
    self.txtTimeTaken2.text = @"11.230932";
    self.txtTimeTaken3.text = @"11.621187";
}

- (void)prepareUI
{
    [self prepareNav];
    [self prepareFields];
}

- (void)prepareNav
{
    self.navigationItem.title = @"Training View";
}

- (void)prepareFields
{
    [self addCustomButtonToKeyBoardWithField:self.txtDistance1];
    [self addCustomButtonToKeyBoardWithField:self.txtDistance2];
    [self addCustomButtonToKeyBoardWithField:self.txtDistance3];
    
    [self addCustomButtonToKeyBoardWithField:self.txtSteps1];
    [self addCustomButtonToKeyBoardWithField:self.txtSteps2];
    [self addCustomButtonToKeyBoardWithField:self.txtSteps3];
    
    [self addCustomButtonToKeyBoardWithField:self.txtTimeTaken1];
    [self addCustomButtonToKeyBoardWithField:self.txtTimeTaken2];
    [self addCustomButtonToKeyBoardWithField:self.txtTimeTaken3];
    
    self.btnStartStop.layer.cornerRadius = 5.0f;
    self.btnCalculate.layer.cornerRadius = 5.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStartStopTapped:(id)sender
{
    if(self.isCountingSteps)
        [self stopCountingSteps];
    else if(self.isCountingSteps == NO)
        [self startCountingSteps];
    
    self.isCountingSteps = !self.isCountingSteps;
}

- (void)stopCountingSteps
{
    [self calculateTimeTaken];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //Do any updates to your label here
        self.btnStartStop.titleLabel.text = @"Start";
    }];
    NSLog(@"****************************************************************");
    NSLog(@"Total Time Taken : %@",self.txtTimeTaken1.text);
    for (int i=0; i<self.timeStamps.count; i++)
        NSLog(@"%@",(NSString *)[self.timeStamps objectAtIndex:i]);
    NSLog(@"****************************************************************");
    [self.motionManager stopCountingSteps];
}

- (void)startCountingSteps
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //Do any updates to your label here
        self.lblStepCount.text=@"0";
        self.btnStartStop.titleLabel.text = @"Stop";
    }];
    
    [self prepareTimer];
    self.timeStamps = [[NSMutableArray alloc] init];
    [self.motionManager startCountingSteps];
}

- (void)prepareTimer
{
    mach_timebase_info(&info);
}

- (IBAction)btnCalculateTapped:(id)sender
{
    ((UIButton *)sender).userInteractionEnabled = NO;
    self.userData.timeTaken1 = [self.txtTimeTaken1.text doubleValue];
    self.userData.numSteps1 = [self.txtSteps1.text integerValue];
    self.userData.trainingDistance1 = [self.txtDistance1.text doubleValue]/12;
    
    self.userData.timeTaken2 = [self.txtTimeTaken2.text doubleValue];
    self.userData.numSteps2 = [self.txtSteps2.text integerValue];
    self.userData.trainingDistance2 = [self.txtDistance2.text doubleValue]/12;
    
    self.userData.timeTaken3 = [self.txtTimeTaken3.text doubleValue];
    self.userData.numSteps3 = [self.txtSteps3.text integerValue];
    self.userData.trainingDistance3 = [self.txtDistance3.text doubleValue]/12;
    
    self.userData.stepRate1 = self.userData.numSteps1/self.userData.timeTaken1;
    self.userData.stepRate2 = self.userData.numSteps2/self.userData.timeTaken2;
    self.userData.stepRate3 = self.userData.numSteps3/self.userData.timeTaken3;
    
    self.userData.distancePerStep1 = self.userData.trainingDistance1/self.userData.numSteps1;
    self.userData.distancePerStep2 = self.userData.trainingDistance2/self.userData.numSteps2;
    self.userData.distancePerStep3 = self.userData.trainingDistance3/self.userData.numSteps3;
    
////////////////////////////////////////////////////////////////////////////////////////////////
//
//    //For x = s/t and y = d/t
//    self.userData.y1 = self.userData.trainingDistance1 / self.userData.timeTaken1;
//    self.userData.y2 = self.userData.trainingDistance2 / self.userData.timeTaken2;
//    self.userData.y3 = self.userData.trainingDistance3 / self.userData.timeTaken3;
//    
////    self.userData.x1 = self.userData.numSteps1 / self.userData.timeTaken1;
////    self.userData.x2 = self.userData.numSteps2 / self.userData.timeTaken2;
////    self.userData.x3 = self.userData.numSteps3 / self.userData.timeTaken3;
//
//    self.userData.x1 = self.userData.timeTaken1 / self.userData.numSteps1;
//    self.userData.x2 = self.userData.timeTaken2 / self.userData.numSteps2;
//    self.userData.x3 = self.userData.timeTaken3 / self.userData.numSteps3;
////////////////////////////////////////////////////////////////////////////////////////////////
    //For x = t/s and y = d/s
    self.userData.y1 = self.userData.trainingDistance1 / self.userData.numSteps1;
    self.userData.y2 = self.userData.trainingDistance2 / self.userData.numSteps2;
    self.userData.y3 = self.userData.trainingDistance3 / self.userData.numSteps3;
    
//    self.userData.x1 = self.userData.numSteps1/self.userData.timeTaken1;
//    self.userData.x2 = self.userData.numSteps2/self.userData.timeTaken2;
//    self.userData.x3 = self.userData.numSteps3/self.userData.timeTaken3;

        self.userData.x1 = self.userData.timeTaken1/self.userData.numSteps1;
        self.userData.x2 = self.userData.timeTaken2/self.userData.numSteps2;
        self.userData.x3 = self.userData.timeTaken3/self.userData.numSteps3;

////////////////////////////////////////////////////////////////////////////////////////////////
    
    double x1 = self.userData.x1;
    double x2 = self.userData.x2;
    double x3 = self.userData.x3;

    double y1 = self.userData.y1;
    double y2 = self.userData.y2;
    double y3 = self.userData.y3;
    
    
    //Calculation of 3 constants for equation Y=AX^2+BX+C
    double A = ((x1 * (y2 - y3)) + (x2 * (y3 - y1)) + (x3 * (y1-y2))) / ((x1*x3*(x1-x3)) - (x2*x3*(x3 - x2)) - (x1*x2*(x1-x2)));
    double B = ((y1 - y2)/(x1 - x2)) - (A * (x1 + x2));
    double C = (((x1 * y2) - (x2* y1)) / (x1 - x2)) + (A * x1 * x2);
    
//    //Calculation of 2 constants for equation Y=AX^2+BX
//    double A = ((x1*y2)-(x2*y1))/((x1*x2)*(x2-x1));
//    double B = (y1-(A*(x1*x1)))/(x1);
//    double C = (y2-(A*(x2*x2)))/(x2);
    
    
//    double C = ((y1*x2*x3*(x3-x2))+(y2*x1*x3*(x1-x3))+(y3*x1*x2*(x2-x1)))/((x2-x1)*(x3-x1)*(x3-x2));
//    double B = ((y1*((x2*x2) - (x3*x3)))+(y2*((x3*x3) - (x1*x1)))+(y3*((x1*x1) - (x2*x2))))/((x2-x1)*(x3-x1)*(x3-x2));
//    double A = ((y1*(x2-x3))+(y2*(x1-x3))+(y3*(x2-x1)))/((x2-x1)*(x3-x1)*(x3-x2));
    
    [self.userData saveA:A];
    [self.userData saveB:B];
    [self.userData saveC:C];
    
    self.lblConstantA.text = [NSString stringWithFormat:@"%f",self.userData.A];
    self.lblConstantB.text = [NSString stringWithFormat:@"%f",self.userData.B];
    self.lblConstantC.text = [NSString stringWithFormat:@"%f",self.userData.C];
    NSMutableDictionary *parameters =[self prepareParameters];
    
    [self.serviceManager postRequestCallWithURL:@"http://128.82.5.142:8080/user_calibrations" andParameters:parameters];
    
}
-(NSMutableDictionary *) prepareParameters
{
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    
    [parameters setObject:self.lblConstantA.text forKey:@"a"];
    [parameters setObject:self.lblConstantB.text forKey:@"b"];
    [parameters setObject:self.lblConstantC.text forKey:@"c"];
    NSString *userId = [self.defaults valueForKey:@"user_id"];
    [parameters setObject:userId forKey:@"user_id"];
    [parameters setObject:@"2" forKey:@"walk_model_id"];
    
    return parameters;
}



- (void)calculateTimeTaken
{
    if([self.txtTimeTaken1.text isEqual: @""] && [self.txtTimeTaken2.text isEqual:@""] && [self.txtTimeTaken3.text isEqual: @""])
    {
        self.txtTimeTaken1.text = [NSString stringWithFormat:@"%f",elapsed];
        self.userData.timeTaken1 = elapsed;
    }
    else if(![self.txtTimeTaken1.text isEqual: @""] && [self.txtTimeTaken2.text isEqual:@""] && [self.txtTimeTaken3.text isEqual: @""])
    {
        self.txtTimeTaken2.text = [NSString stringWithFormat:@"%f",elapsed];
        self.userData.timeTaken2 = elapsed;
    }
    else if(![self.txtTimeTaken1.text isEqual: @""] && ![self.txtTimeTaken2.text isEqual:@""] && [self.txtTimeTaken3.text isEqual: @""])
    {
        self.txtTimeTaken3.text = [NSString stringWithFormat:@"%f",elapsed];
        self.userData.timeTaken3 = elapsed;
    }
    
    [self resetTimers];
}

- (void)resetTimers
{
    start = 0.0f;
    end = 0.0f;
    elapsed = 0.0f;
}


#pragma mark - StepDetectionProtocol
//- (void)stepDetectedWithStepCount:(int)step_count
//{
//    if(step_count>1)
//    {
//        end = [self convertToNanoSeconds:mach_absolute_time()];
//        elapsed = (end - start)/timeUnit;
//        [self.timeStamps addObject:[NSString stringWithFormat:@"%f",elapsed]];
//    }
//    else
//    {
//        AudioServicesPlaySystemSound(1005);
//        start = [self convertToNanoSeconds:mach_absolute_time()];    }
//    
//    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        self.lblStepCount.text =  [NSString stringWithFormat:@"%d",step_count];
//    }];
//}

//- (void)stepDetectedWithStepCount:(int)step_count andSampleSize:(int)sampleSize
//{
//    if(step_count)
//    {
//        elapsed += ((int)sampleSize) /kUpdateFrequency;
//        [self.timeStamps addObject:[NSString stringWithFormat:@"%f",elapsed]];
//    }
//    
//    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        self.lblStepCount.text =  [NSString stringWithFormat:@"%d",step_count];
//    }];
//}

- (void)strideDetectedWithCount:(int)stride_count andDuration:(double)duration
{
    if(stride_count)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            //Do any updates to your label here
            self.lblStepCount.text = [NSString stringWithFormat:@"%d",stride_count];
        }];
        elapsed += duration;
        [self.timeStamps addObject:[NSString stringWithFormat:@"%f",elapsed]];
    }
    else
    {
        AudioServicesPlaySystemSound(1007);
    }
}

- (void)strideDetectedWithCount:(int)stride_count duration:(double)duration andAngle:(double)angle
{
    if(stride_count)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            //Do any updates to your label here
            self.lblStepCount.text = [NSString stringWithFormat:@"%d",stride_count];
        }];
        [self.timeStamps addObject:[NSString stringWithFormat:@"%f",duration]];
        
    }
    else
    {
        //[self calculateDistanceForCurrentStepWithTime:duration andAngle:angle];
        AudioServicesPlaySystemSound(1007);
    }
    
}


#pragma mark - Utils
- (double)convertToNanoSeconds:(uint64_t)timeInMachs
{
    // Get elapsed time in nanoseconds:
    double elapsedNS = (double)timeInMachs * (double)info.numer / (double)info.denom;
    return elapsedNS;
}

- (double)convertMetersToFt:(double)distInMeters
{
    double distInFt = distInMeters * 3.28084;
    return distInFt;
}

- (void)addCustomButtonToKeyBoardWithField:(UITextField *)textField
{
    // My app is restricted to portrait-only, so the following works
    UIToolbar *numberPadAccessoryInputView      = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0f)];
    
    // My app-wide tint color is a gold-ish color, so darkGray contrasts nicely
    numberPadAccessoryInputView.barTintColor    = [UIColor lightGrayColor];
    
    // A basic "Done" button, that calls [self.textField resignFirstResponder]
    UIBarButtonItem *numberPadDoneButton        = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:textField action:@selector(resignFirstResponder)];
    
    // It's the only item in the UIToolbar's items array
    numberPadAccessoryInputView.items           = @[numberPadDoneButton];
    
    // In case the background of the view is similar to [UIColor darkGrayColor], this
    // is put as a contrasting edge line at the top of the UIToolbar
    UIView *topBorderView                       = [[UIView alloc] initWithFrame:CGRectMake(0, 0, numberPadAccessoryInputView.frame.size.width, 1.0f)];
    topBorderView.backgroundColor               = [UIColor whiteColor];
    [numberPadAccessoryInputView addSubview:topBorderView];
    
    // Make it so that this UITextField shows the UIToolbar
    textField.inputAccessoryView           = numberPadAccessoryInputView;
}
- (void)resignFirstResponder:(id)sender
{
    [sender resignFirstResponder];
}

#pragma mark - ServiceProtocol Methods
- (void)serviceCallCompletedWithResponseObject:(id)response
{
    
}

- (void)serviceCallCompletedWithError:(NSError *)error
{
    
}

@end
