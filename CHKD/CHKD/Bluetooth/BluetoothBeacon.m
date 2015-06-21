//
//  BluetoothBeacon.m
//  iBeaconTemplate
//
//  Created by handson MacPro on 12/15/14.
//  Copyright (c) 2014 iBeaconModules.us. All rights reserved.
//

//#import <Foundation/Foundation.h>

#define kBeacon1UUID @"CF7B8FD9-8938-4D82-9CA0-C14DE072CE41"
#define kBeacon2UUID @"04329774-831D-41FC-995D-7496E001E890"
#define kBeacon3UUID @"3CD62F16-6DA3-4ED7-8DAE-544CB6CB4E77"
#define kBeacon4UUID @"D6A596A2-DB33-4324-81E3-18A571CB1125"
#define kBeacon5UUID @"F6A632FF-CE2D-4F1F-807A-F531A8F62922"

#import "BluetoothBeacon.h"

@implementation BluetoothBeacon
-(NSString *) beaconDetails:(CLBeacon*) beacon
{
    
    NSString *proximityLabel = @"";
    switch (beacon.proximity) {
        case CLProximityFar:
            proximityLabel = [NSString stringWithFormat:@"Major: %d, Minor: %d, RSSI: %d, Accuracy: %f",/*beacon.proximityUUID.UUIDString,*/beacon.major.intValue, beacon.minor.intValue, (int)beacon.rssi, beacon.accuracy * 3.28084];
            break;
        case CLProximityNear:
            proximityLabel = [NSString stringWithFormat:@"Major: %d, Minor: %d, RSSI: %d, Accuracy: %f",/*beacon.proximityUUID.UUIDString,*/beacon.major.intValue, beacon.minor.intValue, (int)beacon.rssi, beacon.accuracy * 3.28084];
            break;
        case CLProximityImmediate:
            proximityLabel = [NSString stringWithFormat:@"Major: %d, Minor: %d, RSSI: %d, Accuracy: %f",/*beacon.proximityUUID.UUIDString,*/beacon.major.intValue, beacon.minor.intValue, (int)beacon.rssi, beacon.accuracy * 3.28084];
            break;
        case CLProximityUnknown:
            proximityLabel = @"Unknown";
            break;
    }
    
    return proximityLabel;
    
}

-(NSMutableDictionary *) prepareBeacons{
    
    NSUUID *beaconUUID ;
    
    self.beaconsList = [[NSMutableDictionary alloc] init];
    
    beaconUUID = [[NSUUID alloc] initWithUUIDString:kBeacon1UUID];
    [self.beaconsList setValue:beaconUUID forKey:@"Beacon1"];
    
    beaconUUID = [[NSUUID alloc] initWithUUIDString:kBeacon2UUID];
    [self.beaconsList setValue:beaconUUID forKey:@"Beacon2"];
    
    beaconUUID = [[NSUUID alloc] initWithUUIDString:kBeacon3UUID];
    [self.beaconsList setValue:beaconUUID forKey:@"Beacon3"];
    
    beaconUUID = [[NSUUID alloc] initWithUUIDString:kBeacon4UUID];
    [self.beaconsList setValue:beaconUUID forKey:@"Beacon4"];

    beaconUUID = [[NSUUID alloc] initWithUUIDString:kBeacon5UUID];
    [self.beaconsList setValue:beaconUUID forKey:@"Beacon5"];
    
    
    beaconUUID = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
    [self.beaconsList setValue:beaconUUID forKey:@"Beacon6"];

    
    //    [beaconList setValue:@"B00B1E51-AA51-456F-8C9D-CCDBB052A493" forKey:@"Beacon1"];
    //    [beaconList setValue:@"E00B1E51-AA51-456F-8C9D-CCDBB052A493" forKey:@"Beacon3"];
    //    [beaconList setValue:@"C00B1E51-AA51-456F-8C9D-CCDBB052A493" forKey:@"Beacon4"];
    //    [beaconList setValue:@"D00B1E51-AA51-456F-8C9D-CCDBB052A493" forKey:@"Beacon5"];
    
    return self.beaconsList;
}

@end