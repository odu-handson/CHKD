//
//  DemoViewController.m
//  CHKD
//
//  Created by ravi pitapurapu on 10/27/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import "DemoViewController.h"

#import <AVFoundation/AVFoundation.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#import "MotionManager.h"
#import "RBVolumeButtons.h"
#import "ServiceManager.h"
#import "UserData.h"
#import "BluetoothBeacon.h"
#import <CoreLocation/CoreLocation.h>
#import "AppDelegate.h"
#import "IQDropDownTextField.h"
#import "Locations.h"

//Nano second precision
#define timeUnit 1000000000
#define quadratic @"2"
#define linear @"1"

@interface DemoViewController () <StepDetectionProtocol,ServiceProtocol,CLLocationManagerDelegate,UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UILabel    *lblSteps;
@property (nonatomic, weak) IBOutlet UITextView *txtStepDistance;
@property (nonatomic, weak) IBOutlet UIButton   *btnStartStop;
@property (nonatomic, weak) IBOutlet UILabel    *lblTotalDistance;
@property (weak, nonatomic) IBOutlet  IQDropDownTextField *txtLocations;
@property (weak, nonatomic) IBOutlet UILabel *showSelectLabel;

@property (nonatomic, strong) NSString          *locationId;
@property (nonatomic, strong) NSString          *mapId;
@property (nonatomic, strong) UserData          *userData;
@property (nonatomic, strong) NSMutableArray    *elapsedTimestamps;
@property (nonatomic, strong) NSMutableArray    *anglesMeasured;
@property (nonatomic, strong) NSMutableArray    *sampleSizes;
@property (nonatomic, strong) MotionManager     *motionManager;
@property (nonatomic, assign) BOOL              isCountingSteps;
@property (nonatomic, strong) RBVolumeButtons   *buttonStealer;
@property (nonatomic, strong) NSString          *readingsData;
@property (nonatomic, strong) ServiceManager    *serviceManager;
@property (nonatomic,strong) AppDelegate *appDelegate;
@property (nonatomic,strong)  NSMutableDictionary *beaconList;
@property (nonatomic,strong) BluetoothBeacon *beaconDetails;
@property (nonatomic,strong) NSMutableDictionary *totalDataDictionary;
@property (nonatomic,strong) NSMutableArray *totalDataList;


@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic,strong) NSString *walkId;
@property BOOL isPaused;

@end

@implementation DemoViewController

double A;
double B;
double C;
mach_timebase_info_data_t info;
double start;
double end;
double elapsed;
double totalDistance;
int processedIndex;

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
     self.beaconDetails = [[BluetoothBeacon alloc] init];
    self.beaconList =[self.beaconDetails prepareBeacons];
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
   // [ self createFileWithName:@"rawdata"];
    
    [self prepareButtonStealer];
    [self prepareUI];
    [self fetchConstants];
    
    [self prepareTextField];
    self.btnStartStop.alpha = 0;
    self.txtLocations.delegate = self;
    
    self.totalDataList = [[NSMutableArray alloc] init];

   }

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.buttonStealer stopStealingVolumeButtonEvents];
}

-(void) prepareTextField
{
   
    NSMutableArray *locationArray = [[NSMutableArray alloc] init];
    for(Locations *locations in [self.userData locations])
    {
        [locationArray addObject:locations.locationName];
    }
    [self.txtLocations setItemList:[[NSArray alloc] initWithArray:locationArray]];
    
    [self.txtLocations becomeFirstResponder];
}

- (void)prepareButtonStealer
{
    self.buttonStealer = [[RBVolumeButtons alloc] init];
    __weak DemoViewController *weakSelf = self;
    self.buttonStealer.upBlock = ^{
        [weakSelf btnStartStopTapped:weakSelf.btnStartStop];
    };
    self.buttonStealer.downBlock = ^{
        [weakSelf btnStartStopTapped:weakSelf.btnStartStop];
    };
    
    [self.buttonStealer startStealingVolumeButtonEvents];
}
- (void)prepareUI
{
    self.navigationItem.title = @"Demo View";
    self.btnStartStop.layer.cornerRadius = 5.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStartStopTapped:(id)sender
{
    [self monitorBeacons];
    if(self.isCountingSteps)
    {
        [self stopCountingSteps];
        
        //Service Call
        
//        NSMutableDictionary *parameterArray =[[NSMutableDictionary alloc] init];
//        [parameterArray setObject:self.totalDataList forKey:@"walk_data"];
//        
//        [self.serviceManager postRequestCallWithURL:@"http://128.82.5.142:8080/walk_data/add" andParameters:parameterArray];
        for(id key in self.beaconDetails.beaconsList)
        {
             CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[self.beaconDetails.beaconsList valueForKey:key] identifier:key];
            [self.appDelegate.locationManager stopMonitoringForRegion:beaconRegion];
            [self.appDelegate.locationManager stopRangingBeaconsInRegion:beaconRegion];
            [self.appDelegate.locationManager stopUpdatingLocation];
        }
        [self fetchDetailsFromPersistance];
        
    }
    else if(self.isCountingSteps == NO)
    {
        [self startCountingSteps];
    }
    
    self.isCountingSteps = !self.isCountingSteps;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event

{
    NSUInteger numTaps = [[touches anyObject] tapCount];
    float delay = 0.2;
    if(numTaps == 2)
    {
        [self toogleIsPaused];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(handleDoubleTap) withObject:nil afterDelay:delay ];
    }
}
-(void) handleDoubleTap
{
    if(_isPaused)
    {
        [self stopMonitorBeacons];
        [self stopCountingSteps];
        self.showSelectLabel.text =@"Paused.Please Select Location";
        
    }
    else
    {
        [self startCoutingAfterPaused];
        [self monitorBeacons];
        self.showSelectLabel.text =@"Select Starting Location";
    }
    
}

-(NSMutableDictionary *) prepareParametersToInitiateWalk
{
    NSString *userId = [self.defaults valueForKey:@"user_id"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:userId forKey:@"user_id"];
    [dict setObject:quadratic forKey:@"walk_model_id"];
    [dict setObject:self.locationId forKey:@"starting_point_id"];
    [dict setObject:self.mapId forKey:@"map_id"];
    NSMutableDictionary *walkDict = [[NSMutableDictionary alloc] init];
    [walkDict setObject:dict forKey:@"walk"];
    return walkDict;
    
}

-(void) monitorBeacons
{
    
    self.appDelegate.locationManager.delegate = self;
    self.appDelegate.locationManager.pausesLocationUpdatesAutomatically = NO;
    
    for(id key in self.beaconDetails.beaconsList)
    {
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[self.beaconDetails.beaconsList valueForKey:key] identifier:key];
        [self.appDelegate.locationManager startMonitoringForRegion:beaconRegion];
        [self.appDelegate.locationManager startRangingBeaconsInRegion:beaconRegion];
        [self.appDelegate.locationManager startUpdatingLocation];
    }
}

-(void) stopMonitorBeacons
{
    
    for(id key in self.beaconDetails.beaconsList)
    {
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[self.beaconDetails.beaconsList valueForKey:key] identifier:key];
        [self.appDelegate.locationManager stopMonitoringForRegion:beaconRegion];
        [self.appDelegate.locationManager stopRangingBeaconsInRegion:beaconRegion];
        [self.appDelegate.locationManager stopUpdatingLocation];
    }
    
}

- (void)stopCountingSteps
{
    [self.motionManager stopCountingSteps];
    //[self processStoredTimeStamps];
    
    if(self.readingsData.length > 0)
        //[self.serviceManager makeServiceCallWithData:self.readingsData];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //Do any updates to your label here
        self.btnStartStop.titleLabel.text = @"Start";
         self.btnStartStop.alpha = 0;
    }];

}

- (void)startCountingSteps
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //Do any updates to your label here
        if(!_isPaused)
            self.btnStartStop.titleLabel.text = @"Stop";
        self.btnStartStop.alpha = 1;
    }];
    
    self.readingsData = @"";
    self.elapsedTimestamps = [[NSMutableArray alloc] init];
    self.anglesMeasured = [[NSMutableArray alloc] init];
    self.sampleSizes = [[NSMutableArray alloc] init];
    [self prepareTimer];
    [self.motionManager startCountingSteps];
    
}
-(void) startCoutingAfterPaused
{
    self.readingsData = @"";
    self.elapsedTimestamps = [[NSMutableArray alloc] init];
    self.anglesMeasured = [[NSMutableArray alloc] init];
    self.sampleSizes = [[NSMutableArray alloc] init];
    [self prepareTimer];
    [self.motionManager startCountingSteps];

}


#pragma mark - Computing Distance
- (void)processStoredTimeStamps
{
    for (int i=0; i<self.elapsedTimestamps.count; i++)
    {
        processedIndex = i;
        //[self calculateDistanceForCurrentStepWithTime:((NSString *)[self.elapsedTimestamps objectAtIndex:i]).doubleValue];
    }
    NSLog(@"****************************************************************");
    NSLog(@"%@",self.txtStepDistance.text);
    NSLog(@"****************************************************************");
}

- (void)calculateDistanceForCurrentStepWithTime:(double)time andAngle:(double) angle
{
    double distance;
    distance = [self getDistancefromConstatnsWithX:time];
    [self updateUIWithDistance:distance andAngle:angle];
}

- (double)getDistancefromConstatnsWithX:(double)X
{
    double Y;
    Y = A * X * X + B * X + C;
    totalDistance += Y;
    
    // Commented below to disable distance correction
//    if(Y < 2.5 || Y > 7.5)
//        Y = 5.0;
    return Y;
}

- (void)updateUIWithDistance:(double)distance andAngle:(double) angle
{
//    double timeElapsedForStep = [(NSString *)([self.elapsedTimestamps objectAtIndex:processedIndex]) doubleValue];
    self.totalDataDictionary = [[NSMutableDictionary alloc] init];
    double angleForStep = angle;
    NSNumber *myDoubleNumber = [NSNumber numberWithDouble:angleForStep];
    [self.totalDataDictionary setValue:[myDoubleNumber stringValue] forKey:@"angle"];
   
    NSString *stringToAppend = [NSString stringWithFormat:@"%d      %f   -   %f ",processedIndex+1,distance,angleForStep];
    //self.txtStepDistance.text = [NSString stringWithFormat:@"%f \n %@",distance,stringToAppend];
       NSNumber *doubleDistance = [NSNumber numberWithDouble:distance];
     [self.totalDataDictionary setValue:[doubleDistance stringValue] forKey:@"distance"];
     [self.totalDataDictionary setValue:self.walkId forKey:@"walk_id"];
    [self.totalDataDictionary setValue:@"" forKey:@"bib_uuid"];
    [self.totalDataDictionary setValue:[self getcurrentTimeAsUTCFormat] forKey:@"created_at"];
   // self.lblTotalDistance.text = [NSString stringWithFormat:@"%f",totalDistance];
    self.readingsData = [NSString stringWithFormat:@"%@\n%f\t%f",self.readingsData,distance,angleForStep];

    [self saveDatatToPersistance:self.totalDataDictionary];
    [self.totalDataList addObject:self.totalDataDictionary];
    
//    if(self.totalDataList.count >=10)
//    {
//        NSMutableDictionary *parameterArray =[[NSMutableDictionary alloc] init];
//        [parameterArray setObject:self.totalDataList forKey:@"walk_data"];
//        
//        [self.serviceManager postRequestCallWithURL:@"http://128.82.5.142:8080/walk_data/add" andParameters:parameterArray];
//        for(id key in self.beaconDetails.beaconsList)
//        {
//            CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[self.beaconDetails.beaconsList valueForKey:key] identifier:key];
//            [self.appDelegate.locationManager stopMonitoringForRegion:beaconRegion];
//            [self.appDelegate.locationManager stopRangingBeaconsInRegion:beaconRegion];
//            [self.appDelegate.locationManager stopUpdatingLocation];
//        }
//        self.totalDataList = [[NSMutableArray alloc] init];
//    }
}


-(void) saveDatatToPersistance:(NSMutableDictionary *) totalData
{
        NSManagedObjectContext *context =
        [self.appDelegate managedObjectContext];
        NSManagedObject *eachData;
        eachData = [NSEntityDescription
                      insertNewObjectForEntityForName:@"RawData"
                      inManagedObjectContext:context];
        [eachData setValue: [totalData valueForKey:@"angle"] forKey:@"angle"];
        [eachData setValue: [totalData valueForKey:@"distance"] forKey:@"distance"];
        [eachData setValue: [totalData valueForKey:@"walk_id"] forKey:@"walk_id"];
        [eachData setValue: [totalData valueForKey:@"created_at"] forKey:@"created_at"];
        [eachData setValue: [totalData valueForKey:@"bib_uuid"] forKey:@"bib_uuid"];

    
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            [context save:&error];;
        });
    }
    
}

-(void) flushDatabase{
   
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self.appDelegate managedObjectContext];
    NSArray *stores = [self.appDelegate.persistentStoreCoordinator  persistentStores];
    for(NSPersistentStore *store in stores) {
        [self.appDelegate.persistentStoreCoordinator  removePersistentStore:store error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    }
    [self.appDelegate persistentStoreCoordinator];
}

-(void) fetchDetailsFromPersistance
{
    
    NSManagedObjectContext *context =
    [self.appDelegate managedObjectContext];
    NSEntityDescription *entityDesc =
    [NSEntityDescription entityForName:@"RawData"
                inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSError *error = nil;
    
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    if (error != nil) {
        
        //Deal with failure
    }
    else {
        
        self.totalDataList = [[NSMutableArray alloc] init];
        for (NSManagedObject *eachObect in results)
        {
           
            self.totalDataDictionary = [[NSMutableDictionary alloc] init];
            if(![[eachObect valueForKey:@"bib_uuid"] isEqualToString:@""])
            {
                [self.totalDataDictionary setValue:@"" forKey:@"angle"];
                [self.totalDataDictionary setValue:@"" forKey:@"distance"];
                [self.totalDataDictionary setValue:[eachObect valueForKey:@"bib_uuid"] forKey:@"bib_uuid"];
            }
            else
            {
                [self.totalDataDictionary setValue:[eachObect valueForKey:@"angle"]  forKey:@"angle"];
                //NSNumber *doubleDistance = [NSNumber numberWithDouble:distance];
                [self.totalDataDictionary setValue:[eachObect valueForKey:@"distance"] forKey:@"distance"];
                [self.totalDataDictionary setValue:@"" forKey:@"bib_uuid"];
            }
            
            [self.totalDataDictionary setValue:self.walkId forKey:@"walk_id"];
            [self.totalDataDictionary setValue:[self getcurrentTimeAsUTCFormat] forKey:@"created_at"];
            [self.totalDataList addObject:self.totalDataDictionary];

        }
    }
    
    NSMutableDictionary *parameterArray =[[NSMutableDictionary alloc] init];
    [parameterArray setObject:self.totalDataList forKey:@"walk_data"];
    
    [self.serviceManager postRequestCallWithURL:@"http://128.82.5.142:8080/walk_data/add" andParameters:parameterArray];
    self.totalDataList = [[NSMutableArray alloc] init];
    
}

-(NSString *) getcurrentTimeAsUTCFormat
{
   // NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
    NSDate *currentDate = [[NSDate alloc] init];
   
    // or specifc Timezone: with name
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSString *localDateString = [dateFormatter stringFromDate:currentDate];
    return localDateString;
}

#pragma mark - StepDetectionProtocol methods
- (void)strideDetectedWithCount:(int)stride_count andDuration:(double)duration
{
    if(stride_count)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            //Do any updates to your label here
            self.lblSteps.text = [NSString stringWithFormat:@"%d",stride_count];
        }];
        [self.elapsedTimestamps addObject:[NSString stringWithFormat:@"%f",duration]];
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
            self.lblSteps.text = [NSString stringWithFormat:@"%d",stride_count];
        }];
        [self.elapsedTimestamps addObject:[NSString stringWithFormat:@"%f",duration]];
        
        [self.anglesMeasured addObject:[NSString stringWithFormat:@"%f",angle]];
        [self calculateDistanceForCurrentStepWithTime:duration andAngle:angle];
        
        
    }
    else
    {
        //[self calculateDistanceForCurrentStepWithTime:duration andAngle:angle];
        AudioServicesPlaySystemSound(1007);
    }
    
}


#pragma mark - Utils
- (void)fetchConstants
{
#warning Fetch from server in the future
    //[self mockConstants];
    A = self.userData.A;
    B = self.userData.B;
    C = self.userData.C;
}

- (void)mockConstants
{
    //Propably Ravi's data
//    [self.userData saveA:0.173578];
//    [self.userData saveB:17.535324];
//    [self.userData saveC:-10.093729];

    //Ramesh Constatnts 20 samples
//    [self.userData saveA:0.414276];
//    [self.userData saveB:10.984113];
//    [self.userData saveC:-6.046445];

//    //Ravis Constatns 50 samples
//    [self.userData saveA:-0.063118];
//    [self.userData saveB:12.223839];
//    [self.userData saveC:-8.207292];

    //Ravi Quadratic with Gyro step detector
    [self.userData saveA:-0.180905];
    [self.userData saveB:-5.104435];
    [self.userData saveC:10.808544];
    
//    //Ramesh Quadratic with Gyro step detector
//    [self.userData saveA:-0.10715];
//    [self.userData saveB:-6.667098];
//    [self.userData saveC:12.223272];
    
}

- (void)prepareTimer
{
    mach_timebase_info(&info);
    [self resetTimers];
}

- (void)resetTimers
{
//    start = [self convertToNanoSeconds:mach_absolute_time()];
//    end = start;
//    elapsed = start;
    totalDistance = 0.0f;
}

- (double)convertToNanoSeconds:(uint64_t)timeInMachs
{
    // Get elapsed time in nanoseconds:
    double elapsedNS = (double)timeInMachs * (double)info.numer / (double)info.denom;
    return elapsedNS;
}

#pragma mark - ServiceProtocol Methods
- (void)serviceCallCompletedWithResponse:(NSString *)response
{
    self.readingsData=@"";
    
    UIAlertView *alert  = [[UIAlertView alloc] initWithTitle:@"Response" message:response delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}


#pragma mark -CLLocationManager Delegate

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    for(int i=0;i<beacons.count;i++)
    {
        CLBeacon *beaconObj = beacons[i];
       if(beaconObj.rssi > -70)
       {
           self.totalDataDictionary = [[NSMutableDictionary alloc] init];
           [self.totalDataDictionary setValue:@"" forKey:@"angle"];
           [self.totalDataDictionary setValue:@"" forKey:@"distance"];
           [self.totalDataDictionary setValue:self.walkId forKey:@"walk_id"];
           [self.totalDataDictionary setValue:beaconObj.proximityUUID.UUIDString  forKey:@"bib_uuid"];
           [self.totalDataDictionary setValue:[self getcurrentTimeAsUTCFormat] forKey:@"created_at"];
           [self saveDatatToPersistance:self.totalDataDictionary];
           [self.totalDataList addObject:self.totalDataDictionary];
       }
        NSLog(@"Beacon UDID:%@\n",beaconObj.proximityUUID.UUIDString);
        NSLog(@"Beacon Detected:zxczxcZXc %ld\n",(long)beaconObj.rssi);//instead of logging trigger an event to report to server.
    }
}

#pragma mark - ServiceProtocol Methods
- (void)serviceCallCompletedWithResponseObject:(id)response
{
   
     NSDictionary *data = (NSDictionary *)response;
    NSString *walkData = [data valueForKey:@"id"];
    if(walkData)
    {
        [self saveWalkId:walkData];
        self.btnStartStop.alpha = 1;

    }
    else
    {
        [self flushDatabase];
        
    }
    
}

- (void)serviceCallCompletedWithError:(NSError *)error
{
    
}

-(void) toogleIsPaused
{
    if(_isPaused)
        _isPaused = NO;
    else
        _isPaused = YES;
}

- (void)saveWalkId:(NSString *)walkid
{
    [self.defaults setObject:walkid  forKey:@"walkId"];
    self.walkId = walkid;
}

#pragma UITextFieldDelegate Methods

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(![textField.text isEqualToString:@""])
    {
        
        if(!_isPaused)
        {
            [self getMapIdAndLocationId:textField.text];
            NSMutableDictionary * dict = [self prepareParametersToInitiateWalk];
            [self.serviceManager postRequestCallWithURL:@"http://128.82.5.142:8080/walks" andParameters:dict];
        }  
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location is Invalid"
                                                            message:@"Please select Location"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
        //[alertView setDelegate:self];
        [alertView show];
    }
    
}

-(void) getMapIdAndLocationId:(NSString *) locationName
{
   
    for(Locations *location in self.userData.locations)
    {
        if([location.locationName isEqualToString:locationName])
        {
            self.locationId = location.locationId;
            self.mapId = location.mapId;
        }
    }
    
}

@end
