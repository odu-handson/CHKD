//
//  StepDetectionContorller.m
//  CHKD
//
//  Created by ravi pitapurapu on 10/27/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import "MotionManager.h"

#import <AudioToolbox/AudioToolbox.h>
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>
#import "kalman.h"
#include <mach/mach.h>
#include "ServiceManager.h"

#define timeUnit 1000000000
#define NZEROS 6
#define NPOLES 6
#define GAIN   4.322819570e+04
#define kGYRORATE 1.0323
#define kSampleThreshold 30

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)


@interface MotionManager () <ServiceProtocol>

@property (nonatomic, strong) CMMotionManager           *gmotionManager;
@property (nonatomic, strong) CMAttitude                *currentAttitude;
@property (nonatomic, strong) NSOperationQueue          *motionQueue;
@property (nonatomic, strong) ServiceManager            *serviceManager;
@property (nonatomic, strong) CMAttitude                *referenceAttitude;
@property (nonatomic, strong) CMAttitude                *prevAttitude;
@property (nonatomic, assign) double                    prevHeading;
@property (nonatomic, assign) double                    headingCorrectionEstimate;
@property (nonatomic, strong) NSMutableString           *finalDataPoint;

@end
@implementation MotionManager

struct gyroDP
{
    double rawPitch;
    double rawRoll;
    double rawYaw;
    double filteredPitch;
    double filteredRoll;
    double filteredYaw;
    double filteredPRYCombined;
    double xyz;
    long timestamp;
};

struct reading
{
    double reading;
    double index;
    double timeStamp;
};

struct gyroDP temp;
BOOL goodToStart;
BOOL peakDownDetected;
BOOL peakUpDetected;
int sampleNumber;
int strideCount;
int angleResetCounter;
struct reading currentSample;
struct reading previousSample;
struct reading beforePreviousSample;
struct reading maximum;
struct reading minimum;
NSString *readingsData;
NSString *indexReadings;
mach_timebase_info_data_t info;


// END OF MASROOR'S IMPLEMENTATION FOR GYRO STEP DETECTION


//Gyro step detector
static float xv[NZEROS + 1], yv[NPOLES + 1];
static float xvroll[NZEROS + 1], yvroll[NPOLES + 1];
static float xvYaw[NZEROS + 1], yvYaw[NPOLES + 1];
static float xvaccel[NZEROS + 1], yvaccel[NPOLES + 1];
NSArray *array;

+(MotionManager *) sharedManager
{
    static MotionManager *sharedManager;
    @synchronized(self)
    {
        if (!sharedManager)
            sharedManager = [[MotionManager alloc] init];
        return sharedManager;
    }
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

- (void)stopCountingSteps
{
    AudioServicesPlaySystemSound(1006);
    [self stopUpdates];
}

- (void)startCountingSteps
{
    self.finalDataPoint = [[NSMutableString alloc] init];
    [self prepareMotionManager];
    [self prepareRequiredVariables];
    [self startAngleUpdates];
    [self startReadingValuesFromSensors];
}

- (void)prepareMotionManager
{
    self.gmotionManager = [[CMMotionManager alloc] init];
    self.gmotionManager.deviceMotionUpdateInterval = 1.0 / kUpdateFrequency;
    // Tell CoreMotion to show the compass calibration HUD when required to provide true north-referenced attitude
    self.gmotionManager.showsDeviceMovementDisplay = YES;
    self.motionQueue = [[NSOperationQueue alloc] init];
}

- (void)startAngleUpdates
{
//    [self.gmotionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
    self.currentAttitude = self.gmotionManager.deviceMotion.attitude;
}

- (void)stopAngleUpdates
{
    if(self.gmotionManager.deviceMotionActive)
    {
        [self.gmotionManager stopGyroUpdates];
        [self.gmotionManager stopDeviceMotionUpdates];
    }
}

- (void)stopUpdates
{
    [self stopSensors];
    [self deallocateManagers];
    
    //NSString *reportData = [NSString stringWithFormat:@"%@ \n\n\n %@",readingsData,indexReadings];
    //[self.serviceManager makeServiceCallWithData:self.finalDataPoint];
}

- (void)stopSensors
{
    if (self.gmotionManager.accelerometerActive == YES || self.gmotionManager.gyroActive || self.gmotionManager.deviceMotionActive)
    {
        [self.gmotionManager stopAccelerometerUpdates];
        [self.gmotionManager stopGyroUpdates];
        [self.gmotionManager stopDeviceMotionUpdates];
    }
}

- (void)deallocateManagers
{
    self.gmotionManager = nil;
}

- (void)prepareRequiredVariables
{
    sampleNumber = 0;
    strideCount = 0;
    angleResetCounter = 0;
    self.headingCorrectionEstimate = 0;

    currentSample.reading = 0;
    currentSample.index = -1;
    currentSample.timeStamp = 0;
    previousSample = currentSample;
    beforePreviousSample = currentSample;
    
    maximum.reading = 0;
    maximum.index = 0;
    maximum.timeStamp = 0;
    minimum = maximum;
    
    goodToStart = NO;
    peakUpDetected = YES;
    peakDownDetected = YES;
    
}

double roundToDecimals(const double x, const int numDecimals) {
    int y=x;
    double z=x-y;
    double m=pow(10,numDecimals);
    double q=z*m;
    double r=round(q);
    
    return (y)+(1.0/m)*r;
}

- (void)setInitiationFlagTrue
{
    goodToStart = YES;
    AudioServicesPlaySystemSound(1005);
}

- (void)startReadingValuesFromSensors
{
    
    //[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(setInitiationFlagTrue) userInfo:nil repeats:NO];
    if([self.gmotionManager isGyroAvailable] == YES)
    {
        kalmanInit();
            AudioServicesPlaySystemSound(1005);
        //double rate = RADIANS_TO_DEGREES(self.gmotionManager.gyroData.rotationRate.y);
        //[self.gmotionManager startDeviceMotionUpdatesToQueue:self.motionQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
            
        [self.gmotionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical
                                                                 toQueue:self.motionQueue
                                                             withHandler:^(CMDeviceMotion *motion, NSError *error) {
            temp.rawPitch = motion.attitude.pitch;
            temp.rawRoll = motion.attitude.roll;
            temp.rawYaw = motion.attitude.yaw;
            temp.filteredPitch = filterloopPitch(motion.attitude.pitch);
            temp.filteredRoll = filterloopRoll(motion.attitude.roll);
            temp.filteredYaw = filterloopYaw(motion.attitude.yaw);
            double x = motion.userAcceleration.x;
            double y = motion.userAcceleration.y;
            double z = motion.userAcceleration.z;
            double xyz = sqrt(x*x+y*y+z*z);
            xyz = filterloopAccel(xyz);
            temp.xyz = xyz;
            
            [self filterData];
            
                                                                 
        [self.finalDataPoint appendFormat:@"%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n",temp.rawPitch,temp.rawRoll,temp.rawYaw,temp.filteredPitch,temp.filteredRoll,temp.filteredYaw,temp.filteredPRYCombined,x,y,z,xyz];
                                                                 
                                                                 
            
//            //Donot Delete - This code snippet is used to mock the input for testing purposes
//            for(int i =0;i < array.count ;i++){
//            
//            if(sampleNumber < array.count)
//                temp.filteredPRCombined = [(NSString *)[array objectAtIndex:sampleNumber] doubleValue];
//            
//            [self calculateAngle];
            sampleNumber++;
            if(sampleNumber > 2)// && sampleNumber < array.count)
            {
                beforePreviousSample = previousSample;
                previousSample = currentSample;
                currentSample.reading = temp.filteredPRYCombined;
                currentSample.index = sampleNumber;
                currentSample.timeStamp = [self convertToNanoSeconds:mach_absolute_time()];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self processData];
                });
            }
            else
            {
                if((currentSample.index > 0) && (previousSample.index < 0))
                    previousSample = currentSample;
                
                currentSample.reading = temp.filteredPRYCombined;
                currentSample.index = sampleNumber;
                currentSample.timeStamp = [self convertToNanoSeconds:mach_absolute_time()];
                maximum = currentSample;
                minimum = currentSample;
            }
            //        }
        }];
    
    }
}

- (void)initiateStepDetection
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self processData];
    });
}

-(void)processData
{
//    NSString *str = [NSString stringWithFormat:@"%f\t%f",temp.filteredPRYCombined,temp.xyz];
//    readingsData = [NSString stringWithFormat:@"%@\n%@",readingsData,str];
    if(temp.xyz > 0.1)
    {
        //Trough Detected
        if((previousSample.reading <= currentSample.reading) && (previousSample.reading < beforePreviousSample.reading))
        {
            //If known minimum index  is not farther than 30 samples from previous Index minimum is minimum (minimum,previous)
            if((previousSample.index - minimum.index) <= kSampleThreshold)
            {
                if((previousSample.reading < minimum.reading))
                {
                    double mintimeStamp = minimum.timeStamp;
                    minimum = previousSample;
                    minimum.timeStamp = mintimeStamp;
                }
            }
            else
            {
                //if(known minimum and previous sample are spaced enough)
                peakDownDetected = true;
                
                if(peakDownDetected && peakUpDetected)
                {
                    double duration = (previousSample.timeStamp - minimum.timeStamp)/timeUnit;
                    NSLog(@"duration :%f",duration);
                    indexReadings = [NSString stringWithFormat:@"%@\n%f\t%f\t%f",indexReadings,minimum.index,maximum.index,previousSample.index];
                    //TO-DO Calculate angle here in future. Consider peakreading(Maximum) - previous sample(current minimum) to be small and measure angle
//                  [self.stepDelegate strideDetectedWithCount:strideCount andDuration:duration];
                    double angleCalculated = [self calculateAngle];
                    [self.stepDelegate strideDetectedWithCount:strideCount duration:duration andAngle:angleCalculated];
                    [self resetReferenceFrameIfRequired];
                    strideCount++;
                }
                minimum = previousSample;
                peakUpDetected=false;
            }
        }
        //Crest Detected
        else if((previousSample.reading >= currentSample.reading) && (previousSample.reading > beforePreviousSample.reading))
        {
            //If known maximum index  is not farther than 30 samples from previous Index minimmaximumum is maximum (maximum,previous)
            if(previousSample.index - maximum.index <= kSampleThreshold)
            {
                if(previousSample.reading > maximum.reading)
                    maximum = previousSample;
            }
            else
            {
                if(peakDownDetected)
                {
                    peakUpDetected = true;
                    peakDownDetected = false;
                }
                maximum = previousSample;
            }
        }
    }
}

-(void)filterData
{
    double PRY = sqrt((temp.filteredPitch * temp.filteredPitch) + (temp.filteredRoll * temp.filteredRoll));// + (temp.filteredYaw * temp.filteredYaw));
    double newAngle = RADIANS_TO_DEGREES(PRY);
    double outAngle = getAngle(newAngle, kGYRORATE, 1/kUpdateFrequency);
//    temp.filteredPRCombined = roundToDecimals(DEGREES_TO_RADIANS(outAngle),3);
    temp.filteredPRYCombined = DEGREES_TO_RADIANS(outAngle);
}

#pragma mark - Butterworth Filter Methods
static double filterloopPitch(double input)
{
    xv[0] = xv[1]; xv[1] = xv[2]; xv[2] = xv[3]; xv[3] = xv[4]; xv[4] = xv[5]; xv[5] = xv[6];
    xv[6] = input/GAIN;
    yv[0] = yv[1]; yv[1] = yv[2]; yv[2] = yv[3]; yv[3] = yv[4]; yv[4] = yv[5]; yv[5] = yv[6];
    yv[6] = (xv[0] + xv[6]) + 6 * (xv[1] + xv[5]) + 15 * (xv[2] + xv[4])
    + 20 * xv[3]
    + (-0.2304689873 * yv[0]) + (1.7181353495 * yv[1])
    + (-5.3861730594 * yv[2]) + (9.0983763199 * yv[3])
    + (-8.7463975969 * yv[4]) + (4.5450474591 * yv[5]);
    return yv[6];
}

static double filterloopRoll(double input)
{
    xvroll[0] = xvroll[1]; xvroll[1] = xvroll[2]; xvroll[2] = xvroll[3]; xvroll[3] = xvroll[4]; xvroll[4] = xvroll[5]; xvroll[5] = xvroll[6];
    xvroll[6] = input/GAIN;
    yvroll[0] = yvroll[1]; yvroll[1] = yvroll[2]; yvroll[2] = yvroll[3]; yvroll[3] = yvroll[4]; yvroll[4] = yvroll[5]; yvroll[5] = yvroll[6];
    yvroll[6] = (xvroll[0] + xvroll[6]) + 6 * (xvroll[1] + xvroll[5]) + 15 * (xvroll[2] + xvroll[4])
    + 20 * xvroll[3]
    + (-0.2304689873 * yvroll[0]) + (1.7181353495 * yvroll[1])
    + (-5.3861730594 * yvroll[2]) + (9.0983763199 * yvroll[3])
    + (-8.7463975969 * yvroll[4]) + (4.5450474591 * yvroll[5]);
    return yvroll[6];
}

static double filterloopYaw(double input)
{
    xvYaw[0] = xvYaw[1]; xvYaw[1] = xvYaw[2]; xvYaw[2] = xvYaw[3]; xvYaw[3] = xvYaw[4]; xvYaw[4] = xvYaw[5]; xvYaw[5] = xvYaw[6];
    xvYaw[6] = input/GAIN;
    yvYaw[0] = yvYaw[1]; yvYaw[1] = yvYaw[2]; yvYaw[2] = yvYaw[3]; yvYaw[3] = yvYaw[4]; yvYaw[4] = yvYaw[5]; yvYaw[5] = yvYaw[6];
    yvYaw[6] = (xvYaw[0] + xvYaw[6]) + 6 * (xvYaw[1] + xvYaw[5]) + 15 * (xvYaw[2] + xvYaw[4])
    + 20 * xvYaw[3]
    + (-0.2304689873 * yvYaw[0]) + (1.7181353495 * yvYaw[1])
    + (-5.3861730594 * yvYaw[2]) + (9.0983763199 * yvYaw[3])
    + (-8.7463975969 * yvYaw[4]) + (4.5450474591 * yvYaw[5]);
    return yvYaw[6];
}

static double filterloopAccel(double input)
{
    xvaccel[0] = xvaccel[1]; xvaccel[1] = xvaccel[2]; xvaccel[2] = xvaccel[3]; xvaccel[3] = xvaccel[4]; xvaccel[4] = xvaccel[5]; xvaccel[5] = xvaccel[6];
    xvaccel[6] = input/GAIN;
    yvaccel[0] = yvaccel[1]; yvaccel[1] = yvaccel[2]; yvaccel[2] = yvaccel[3]; yvaccel[3] = yvaccel[4]; yvaccel[4] = yvaccel[5]; yvaccel[5] = yvaccel[6];
    yvaccel[6] = (xvaccel[0] + xvaccel[6]) + 6 * (xvaccel[1] + xvaccel[5]) + 15 * (xvaccel[2] + xvaccel[4])
    + 20 * xvaccel[3]
    + (-0.2304689873 * yvaccel[0]) + (1.7181353495 * yvaccel[1])
    + (-5.3861730594 * yvaccel[2]) + (9.0983763199 * yvaccel[3])
    + (-8.7463975969 * yvaccel[4]) + (4.5450474591 * yvaccel[5]);
    return yvaccel[6];
}


#pragma mark - Angle calculation methods
-(double)calculateAngle
{
    if(!self.referenceAttitude)
        self.referenceAttitude = self.gmotionManager.deviceMotion.attitude;
    
    if(!self.prevHeading)
        self.prevHeading = 0;
    
    CMAttitude *currentAttitude = self.gmotionManager.deviceMotion.attitude;
    
    [currentAttitude multiplyByInverseOfAttitude:self.referenceAttitude];
//    double heading = RADIANS_TO_DEGREES(GLKQuaternionAngle((GLKQuaternionMake(currentAttitude.quaternion.x, currentAttitude.quaternion.y, currentAttitude.quaternion.z, currentAttitude.quaternion.w))));
    
    double x = currentAttitude.quaternion.x;
    double y = currentAttitude.quaternion.x;
    double z = currentAttitude.quaternion.z;
    double w = currentAttitude.quaternion.w;
    
    double currentHeading = RADIANS_TO_DEGREES(atan2(((2*y*w)-(2*x*z)) , (1 - 2*y*y) - (2*z*z)));
    
    //Do not shuffle the next lines of code - Order is very important for functioning
    angleResetCounter++;
    double tempCurrent = currentHeading;
    
    if(angleResetCounter == 5)
    {
        self.referenceAttitude = self.gmotionManager.deviceMotion.attitude;
        angleResetCounter = 0;
        self.headingCorrectionEstimate = currentHeading;
    }
    
    if(angleResetCounter == 1)
    {
        currentHeading = currentHeading + self.headingCorrectionEstimate;
    }
    
    currentHeading = currentHeading - self.prevHeading;
    self.prevHeading = tempCurrent;
    
    if((currentHeading < 8  && currentHeading > 0 ) || (currentHeading > -8 && currentHeading < 0))
        currentHeading = 0;

    
    /*
     if([self getLeftOrRightWith:currentAttitude])
     {
     str = [NSString stringWithFormat:@"%@ | %f ",self.txtReadings.text,-(fabsf(RADIANS_TO_DEGREES(currentHeading)-self.prevHeading))];
     }
     else
     {
     str = [NSString stringWithFormat:@"%@ | %f ",self.txtReadings.text,fabsf(RADIANS_TO_DEGREES(currentHeading)-self.prevHeading)];
     }
     */

    NSLog(@"%f",currentHeading);


    return currentHeading;
}

- (void)resetReferenceFrameIfRequired
{

}

//-(BOOL)TOTgetLeftOrRightWith:(CMAttitude *)currAttitude
//{
//    if(RADIANS_TO_DEGREES(currAttitude.roll) < 0)
//    {
//        if(self.prevRoll < 0)
//        {
//            if(RADIANS_TO_DEGREES(currAttitude.roll) < (double)self.prevRoll)
//            {
//                //Turning Right
//                return YES;
//            }
//            else
//            {
//                //Turning Left
//                return NO;
//            }
//        }
//        else
//        {
//            if(self.prevRoll < 90)
//            {
//                //Turn Right
//                return YES;
//            }
//            else
//            {
//                //Turn Left
//                return NO;
//            }
//        }
//    }
//    else
//    {
//        if(self.prevRoll > 0)
//        {
//            if(RADIANS_TO_DEGREES(currAttitude.roll) > self.prevRoll)
//            {
//                //Turning Left
//                return NO;
//            }
//            else
//            {
//                //Turning Right
//                return YES;
//            }
//        }
//        else
//        {
//            if(self.prevRoll > -90)
//            {
//                //Turn Left
//                return NO;
//            }
//            else
//            {
//                //Turn Right
//                return YES;
//            }
//        }
//    }
//}


#pragma mark - Utils
- (double)convertToNanoSeconds:(uint64_t)timeInMachs
{
    // Get elapsed time in nanoseconds:
    double elapsedNS = (double)timeInMachs * (double)info.numer / (double)info.denom;
    return elapsedNS;
}

- (NSString *) timeStamp {
    return [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];
}

#pragma mark - ServiceProtocol Methods
- (void)serviceCallCompletedWithResponse:(NSString *)response
{
    readingsData=@"";
    indexReadings=@"";
    
    UIAlertView *alert  = [[UIAlertView alloc] initWithTitle:@"Response" message:response delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}


@end
