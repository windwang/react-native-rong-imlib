//
//  RCTRongCloud.h
//  RCTRongCloud
//
//  Created by LvBingru on 1/26/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import "RCTBridgeModule.h"
#import "RCTEventEmitter.h"

@interface RCTRongCloud : RCTEventEmitter<RCTBridgeModule>

+ (void)registerAPI:(NSString *)aString;
+ (void)setDeviceToken:(NSData *)aToken;

@end
