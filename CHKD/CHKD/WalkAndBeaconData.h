//
//  WalkAndBeaconData.h
//  CHKD
//
//  Created by Bharath Kongara on 2/23/15.
//  Copyright (c) 2015 Old Dominion University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WalkAndBeaconData : NSObject

@property (nonatomic,strong) NSString *angle;
@property (nonatomic,strong) NSString *distance;
@property (nonatomic,strong) NSString *walk_id;
@property (nonatomic,strong) NSString *bib_uuid;
@property (nonatomic,strong) NSString *created_at;

@end
