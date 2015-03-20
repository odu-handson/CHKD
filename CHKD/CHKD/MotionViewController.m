//
//  MotionViewController.m
//  CHKD
//
//  Created by ravi pitapurapu on 9/16/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import "MotionViewController.h"

#import <CoreMotion/CoreMotion.h>

#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>

#import "TrainingInfo.h"

#include <mach/mach.h>
#include <mach/mach_time.h>

#define kUpdateFrequency    60.0
#define kLowerThreshold     0.82
#define kUpperThreshold     2.5

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

//Nano second precision
#define timeUnit 1000000000

@interface MotionViewController () <UITextFieldDelegate>

@property (nonatomic,weak) IBOutlet UITextField *txtDistance1;
@property (nonatomic,weak) IBOutlet UITextField *txtDistance2;
@property (nonatomic,weak) IBOutlet UITextField *txtDistance3;
@property (nonatomic,weak) IBOutlet UILabel *lblNumSteps;
@property (nonatomic,weak) IBOutlet UITextField *txtFastNumSteps;
@property (nonatomic,weak) IBOutlet UITextField *txtNormalNumSteps;
@property (nonatomic,weak) IBOutlet UITextField *txtSlowNumSteps;
@property (nonatomic,weak) IBOutlet UITextField *txtTimeTakenFast;
@property (nonatomic,weak) IBOutlet UITextField *txtTimeTakenNormal;
@property (nonatomic,weak) IBOutlet UITextField *txtTimeTakenSlow;
@property (nonatomic,weak) IBOutlet UILabel *lblConstantA;
@property (nonatomic,weak) IBOutlet UILabel *lblConstantb;
@property (nonatomic,weak) IBOutlet UIButton *btnStart;
@property (nonatomic,weak) IBOutlet UIButton *btnStop;
@property (nonatomic,weak) IBOutlet UIButton *btnProceed;
@property (nonatomic,weak) IBOutlet UILabel *lblDelta;

@property (nonatomic,strong,retain) CLLocationManager *locationManager;
@property (nonatomic,strong,retain) CMMotionManager *motionManager;
@property (nonatomic,assign) NSInteger numSteps;
@property (nonatomic,strong) TrainingInfo *trainingInfo;

@property float px;
@property float py;
@property float pz;
@property BOOL isSleeping;

@end

@implementation MotionViewController

@synthesize px,py,pz,numSteps,isSleeping;

BOOL toggleIsOn;
double start;
double end;
double elapsed;
// Get information for converting from MTU to nanoseconds
mach_timebase_info_data_t info;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initializeVariables];
    [self prepareLocationManager];
    [self prepareMotionManager];
    self.trainingInfo = [TrainingInfo sharedInfo];
    mach_timebase_info(&info);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - Utility Methods
- (void)initializeVariables
{
    px = py = pz = 0;
    numSteps = 0;
}

- (void)prepareLocationManager
{
    //Prepare location manager to deliver updates on heading
    self.locationManager=[[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.headingFilter = 1;
    [self.locationManager startUpdatingHeading];
}

- (void)prepareMotionManager
{
    self.motionManager = [[CMMotionManager alloc] init];
    //Configure Accelerometer
    
    if ([self.motionManager isAccelerometerAvailable])
        self.motionManager.accelerometerUpdateInterval = 1.0 / kUpdateFrequency;
        
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Accelerometer Unavailable" message:@"Device accelerometer not supported" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
    }
}

 -(void)playSound
{
    NSString *path = [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] pathForResource:@"Beep" ofType:@"aiff"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:path]), &soundID);
    AudioServicesPlaySystemSound(soundID);
    AudioServicesDisposeSystemSoundID(soundID);
}

-(void)handleAccelerationData:(CMAcceleration)acceleration
{
    float xx = acceleration.x;
    float yy = acceleration.y;
    float zz = acceleration.z;
    
    float dot = (self.px * xx) + (self.py * yy) + (self.pz * zz);
    float a = ABS(sqrt(self.px * self.px + self.py * self.py + self.pz * self.pz));
    float b = ABS(sqrt(xx * xx + yy * yy + zz * zz));
    
    dot /= (a * b);
    // NSLog(@"***** %f",dot);
    if (dot <= 0.82)
    {
        if (!isSleeping)
        {
            isSleeping = YES;
            [self performSelector:@selector(wakeUp) withObject:nil afterDelay:0.3];
            numSteps += 1;
            [self handleStepDetection];
        }
    }
    
    self.px = xx; self.py = yy; self.pz = zz;
}

- (void)wakeUp
{
    isSleeping = NO;
}

- (void)startAccelerometerUpdates
{
    start = [self convertToNanoSeconds:mach_absolute_time()];
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
     {
         [self handleAccelerationData:accelerometerData.acceleration];
         if(error)
         {
             NSLog(@"%@", error);
         }
     }];
}

- (void)stopAccelerometerUpdates
{
    [self.motionManager stopAccelerometerUpdates];
    [self calculateTimeTaken];
}

- (void)calculateTimeTaken
{
    end = [self convertToNanoSeconds:mach_absolute_time()];
    elapsed = (end - start)/timeUnit;
    if([self.txtTimeTakenFast.text isEqual: @""] && [self.txtTimeTakenNormal.text isEqual:@""] && [self.txtTimeTakenSlow.text isEqual: @""])
    {
        self.txtTimeTakenFast.text = [NSString stringWithFormat:@"%f",elapsed];
        self.trainingInfo.timeTakenFast = elapsed;
    }
    else if(![self.txtTimeTakenFast.text isEqual: @""] && [self.txtTimeTakenNormal.text isEqual:@""] && [self.txtTimeTakenSlow.text isEqual: @""])
    {
        self.txtTimeTakenNormal.text = [NSString stringWithFormat:@"%f",elapsed];
        self.trainingInfo.timeTakenNormal = elapsed;
    }
    else if(![self.txtTimeTakenFast.text isEqual: @""] && ![self.txtTimeTakenNormal.text isEqual:@""] && [self.txtTimeTakenSlow.text isEqual: @""])
    {
        self.txtTimeTakenSlow.text = [NSString stringWithFormat:@"%f",elapsed];
        self.trainingInfo.timeTakenSlow = elapsed;
    }
    start = 0;
    end = 0;
    elapsed = 0;
}

#pragma mark - Step lenght estimation methods
- (IBAction)btnStartTrainngTapped:(id)sender
{
    [self startAccelerometerUpdates];
    AudioServicesDisposeSystemSoundID(1005);
    self.btnStart.userInteractionEnabled = NO;
    self.btnStop.userInteractionEnabled = YES;
}

- (IBAction)btnStopTapped:(id)sender
{
    [self stopAccelerometerUpdates];
    AudioServicesDisposeSystemSoundID(1006);
    self.btnStop.userInteractionEnabled = NO;
    self.btnStart.userInteractionEnabled = YES;
}

- (void)handleStepDetection
{
//    if(numSteps == 1)
//        start = [self convertToNanoSeconds:mach_absolute_time()];
    
    self.lblNumSteps.text = [NSString stringWithFormat:@"%ld",(long)numSteps];
}

- (IBAction)btnProceedTapped:(id)sender
{
    self.trainingInfo.trainingDistance1 = [self.txtDistance1.text doubleValue];
    self.trainingInfo.trainingDistance2 = [self.txtDistance2.text doubleValue];
    self.trainingInfo.trainingDistance3 = [self.txtDistance3.text doubleValue];
    
    self.trainingInfo.numStepsFast = [self.txtFastNumSteps.text doubleValue];
    self.trainingInfo.numStepsNormal = [self.txtNormalNumSteps.text doubleValue];
    self.trainingInfo.numStepsSlow = [self.txtSlowNumSteps.text doubleValue];
    
    self.trainingInfo.stepRateFast = self.trainingInfo.numStepsFast / self.trainingInfo.timeTakenFast;
    self.trainingInfo.stepRateNormal = self.trainingInfo.numStepsNormal / self.trainingInfo.timeTakenNormal;
    self.trainingInfo.stepRateSlow = self.trainingInfo.numStepsSlow / self.trainingInfo.timeTakenSlow;
    
    self.trainingInfo.distancePerStepFast = [self.txtDistance1.text doubleValue] / self.trainingInfo.numStepsFast;
    self.trainingInfo.distancePerStepNormal = [self.txtDistance2.text doubleValue] / self.trainingInfo.numStepsNormal;
    self.trainingInfo.distancePerStepSlow = [self.txtDistance3.text doubleValue] / self.trainingInfo.numStepsSlow;
    
//    double y1 = self.trainingInfo.trainingDistance1 / self.trainingInfo.timeTakenFast;
//    double y2 = self.trainingInfo.trainingDistance2 / self.trainingInfo.timeTakenNormal;
//    double y3 = self.trainingInfo.trainingDistance3 / self.trainingInfo.timeTakenSlow;
//    
//    double x1 = self.trainingInfo.stepRateFast;
//    double x2 = self.trainingInfo.stepRateNormal;
//    double x3 = self.trainingInfo.stepRateSlow;
    
    //self.trainingInfo.a = (x1 * y2 - x2 * y1)/(x1 * x2);
    //self.trainingInfo.b = (x1* y1 * x2 + x1 * x1 * y2 - x2 * y1)/(x1 * x2);
    
    double y1 = [self.txtDistance1.text doubleValue] / [self.txtTimeTakenFast.text doubleValue] ;
    double y2 = [self.txtDistance2.text doubleValue] / [self.txtTimeTakenNormal.text doubleValue];
    //double y3 = [self.txtDistance1.text doubleValue] / [self.txtTimeTakenFast.text doubleValue];
    
//    double x1 = self.trainingInfo.stepRateFast;
//    double x2 = self.trainingInfo.stepRateNormal;
    //double x3 = self.trainingInfo.stepRateSlow;
    
    double x1 = [self.txtFastNumSteps.text doubleValue] / [self.txtTimeTakenFast.text doubleValue] ;
    double x2 = [self.txtNormalNumSteps.text doubleValue] / [self.txtTimeTakenNormal.text doubleValue];

    
    self.trainingInfo.a = ((x2 * y1) - (x1 * y2))/((x1 * x2)*(x1 - x2));
    self.trainingInfo.b = (y1/x1)- (((x2 * y1) - (x1 * y2))/(x2 *(x1 - x2)));
    
    
    //double calculatedy3 = (self.trainingInfo.a * x3 * x3) + (self.trainingInfo.b * x3);
    
    //double diff = y3 - calculatedy3;
    
    self.lblConstantA.text = [NSString stringWithFormat:@"%f",self.trainingInfo.a];
    self.lblConstantb.text = [NSString stringWithFormat:@"%f",self.trainingInfo.b];
    //self.lblDelta.text = [NSString stringWithFormat:@"Delta - %f",diff];
}

- (double)convertToNanoSeconds:(uint64_t)timeInMachs
{
    // Get elapsed time in nanoseconds:
    double elapsedNS = (double)timeInMachs * (double)info.numer / (double)info.denom;
    return elapsedNS;
}

@end
