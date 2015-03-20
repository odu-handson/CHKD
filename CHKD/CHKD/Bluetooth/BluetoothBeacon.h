//
//  BluetoothBeacon.h
//  iBeaconTemplate
//
//  Created by handson MacPro on 12/15/14.
//  Copyright (c) 2014 iBeaconModules.us. All rights reserved.
//

#ifndef iBeaconTemplate_BluetoothBeacon_h
#define iBeaconTemplate_BluetoothBeacon_h
#import <CoreLocation/CoreLocation.h>

@interface BluetoothBeacon : NSObject

@property (nonatomic,strong) NSMutableDictionary *beaconsList;

-(NSString *) beaconDetails:(CLBeacon*) beacon;
-(NSMutableDictionary *) prepareBeacons;


@end
#endif
