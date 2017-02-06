//
//  RCTRongCloud.h
//  RCTRongCloud
//
//  Created by LvBingru on 1/26/16.
//  Copyright © 2016 erica. All rights reserved.
//


#if __has_include(<React/RCTEventEmitter.h>)
#import <React/RCTEventEmitter.h>
#elif __has_include("RCTEventEmitter.h")
#import "RCTEventEmitter.h"
#else
#import "React/RCTEventEmitter.h"   // Required when used as a Pod in a Swift project
#endif



@interface RCTRongCloud : RCTEventEmitter

+ (void)registerAPI:(NSString *)aString;
+ (void)setDeviceToken:(NSData *)aToken;

@end
