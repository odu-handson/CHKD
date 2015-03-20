//
//  BluetoothBeacon.m
//  iBeaconTemplate
//
//  Created by handson MacPro on 12/15/14.
//  Copyright (c) 2014 iBeaconModules.us. All rights reserved.
//

//#import <Foundation/Foundation.h>

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
    
    beaconUUID = [[NSUUID alloc] initWithUUIDString:@"B3A93989-AA51-456F-8C9D-CCDBB052A493"];
    [self.beaconsList setValue:beaconUUID forKey:@"Beacon2"];
    
    beaconUUID = [[NSUUID alloc] initWithUUIDString:@"3760E003-5827-4463-AD2E-F1CF70709DEE"];
    [self.beaconsList setValue:beaconUUID forKey:@"Beacon4"];
    
    beaconUUID = [[NSUUID alloc] initWithUUIDString:@"12396142-B0C8-49AF-97FC-37F0046C82EE"];
    [self.beaconsList setValue:beaconUUID forKey:@"Beacon1"];
    
    //    [beaconList setValue:@"B00B1E51-AA51-456F-8C9D-CCDBB052A493" forKey:@"Beacon1"];
    //    [beaconList setValue:@"E00B1E51-AA51-456F-8C9D-CCDBB052A493" forKey:@"Beacon3"];
    //    [beaconList setValue:@"C00B1E51-AA51-456F-8C9D-CCDBB052A493" forKey:@"Beacon4"];
    //    [beaconList setValue:@"D00B1E51-AA51-456F-8C9D-CCDBB052A493" forKey:@"Beacon5"];
    
    return self.beaconsList;
}

@end