//
//  ServiceManager.h
//  Qwyvr
//
//  Created by ravi pitapurapu on 9/12/14.
//  Copyright (c) 2014 Qwyvr. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServiceProtocol

@optional

- (void)serviceCallCompletedWithResponseObject:(id)response;
- (void)serviceCallCompletedWithError:(NSError *)error;

@end

@interface ServiceManager : NSObject

+ (ServiceManager *)defaultManager;

- (void)serviceCallWithURL:(NSString *)URL andParameters:(NSObject *)params;
- (void)postRequestCallWithURL:(NSString *)URL andParameters:(NSObject *)params;

@property (nonatomic,weak) id<ServiceProtocol> serviceDelegate;

@end

