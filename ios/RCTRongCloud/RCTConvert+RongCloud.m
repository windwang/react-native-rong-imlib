//
//  RCTCovert+RongCloud.m
//  RCTRongCloud
//
//  Created by LvBingru on 1/26/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import "RCTConvert+RongCloud.h"
#import <Photos/Photos.h>
@implementation RCTConvert(RongCloud)

+ (RCMessageContent *)RCMessageContent:(id)json;
{
    json = [self NSDictionary:json];
    
   // NSDictionary *user=json[@"userInfo" ];
    
    NSString *type = [RCTConvert NSString:json[@"type"]];
    
    if ([@"text" isEqualToString:type]) {
        RCTextMessage* ret = [RCTextMessage messageWithContent:json[@"content"]];
        ret.extra = [RCTConvert NSString:json[@"extra"]];
        // [ret setSenderUserInfo:[RCTConvert RCUserInfo:user]];
        return ret;
    } else if ([@"voice" isEqualToString:type]) {
        NSString *base64 = [RCTConvert NSString:json[@"base64"]];
        NSData *voice = [[NSData alloc] initWithBase64EncodedString:base64 options:0];
        long long duration = [RCTConvert int64_t:json[@"duration"]];
        
        RCVoiceMessage *ret = [RCVoiceMessage messageWithAudio:voice duration:duration];
        ret.extra = [RCTConvert NSString:json[@"extra"]];
     //    [ret setSenderUserInfo:[RCTConvert RCUserInfo:user]];
        return ret;
    } else if ([@"image" isEqualToString:type]) {
        NSString * uri = [RCTConvert NSString:json[@"imageUrl"]];
        RCImageMessage *ret = [RCImageMessage messageWithImageURI:uri];
      
        ret.full = [json[@"full"] boolValue];
        ret.extra = [RCTConvert NSString:json[@"extra"]];
       //  [ret setSenderUserInfo:[RCTConvert RCUserInfo:user]];
        return ret;
    } else if ([@"notify" isEqualToString:type]) {
        NSString * name = [RCTConvert NSString:json[@"name"]];
        NSString * data =[RCTConvert NSString:json[@"data"]];
        RCCommandNotificationMessage* ret = [RCCommandNotificationMessage notificationWithName:name data:data];
      //   [ret setSenderUserInfo:[RCTConvert RCUserInfo:user]];
        return ret;
    }else if ([@"rich" isEqualToString:type]){
        NSString *title=json[@"title"];
        NSString *content=json[@"content"];
        NSString *imgUrl=json[@"imageUrl"];
        NSString *url=json[@"url"];
        NSString *extra=json[@"extra"];
        
        RCRichContentMessage *ret=[RCRichContentMessage messageWithTitle:title digest:content imageURL:imgUrl  url:url extra:extra  ];
        
      //  [ret setSenderUserInfo:[RCTConvert RCUserInfo:user]];
        return ret;
    } else if([@"location" isEqualToString:type]){
        CLLocationCoordinate2D location=CLLocationCoordinate2DMake([[json objectForKey:@"lat"] doubleValue],[[json objectForKey:@"lng"] doubleValue]);
        RCLocationMessage *ret = [RCLocationMessage messageWithLocationImage:nil location:location locationName:[json valueForKey:@"poi"]];
        ret.extra=[RCTConvert NSString:json[@"extra"]];
        // [ret setSenderUserInfo:[RCTConvert RCUserInfo:user]];
        return ret;
    }else if([@"media" isEqualToString:type]){
        RCFileMessage *ret=[RCFileMessage messageWithFile:[json objectForKey:@"mediaUrl"]];
        if(json[@"contentType"]){
            ret.type=json[@"contentType"];
            //[ret setType:json[@"contentType"]];
        }
        
        NSMutableDictionary *dic = [NSMutableDictionary new];
        dic[@"__type__"]=@"media";
        dic[@"extra"]=json[@"extra"];
        
        if(json[@"thumb"]){
            
            UIImage *image= [UIImage imageWithContentsOfFile:json[@"thumb"]];
       
            NSData *data=[RCUtilities compressedImageAndScalingSize:image targetSize:CGSizeMake(30, 40) percent:0.8];
            
            NSString *contentString=[data base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
            
            dic[@"thumb"]=contentString;
        }
        NSData *extraData=[NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        
        ret.extra=[[NSString alloc]initWithData:extraData encoding:NSUTF8StringEncoding];

      
        
        return ret;
    }else {
        RCTextMessage* ret = [RCTextMessage messageWithContent:@"[未知消息]"];
        return ret;
    }
        
        
//    RCUserInfo *userInfo = [[RCUserInfo alloc] initWithUserId:json[@"userId"] name:json[@"name"] portrait:json[@"portraitUri"]];
//    return userInfo;
}

+(RCUserInfo *)RCUserInfo:(id)json;
{
    if(json==NULL)return NULL;
    json = [self NSDictionary:json];
    RCUserInfo *userInfo = [[RCUserInfo alloc] initWithUserId:json[@"userId"] name:json[@"name"] portrait:json[@"portraitUri"]];
    return userInfo;
}

///*!
// 未读
// */
//ReceivedStatus_UNREAD = 0,
//
///*!
// 已读
// */
//ReceivedStatus_READ = 1,
//
///*!
// 已听
// 
// @discussion 仅用于语音消息
// */
//ReceivedStatus_LISTENED = 2,
//
///*!
// 已下载
// */
//ReceivedStatus_DOWNLOADED = 4,
//
///*!
// 该消息已经被其他登录的多端收取过。（即改消息已经被其他端收取过后。当前端才登录，并重新拉取了这条消息。客户可以通过这个状态更新
// UI，比如不再提示）。
// */
//ReceivedStatus_RETRIEVED = 8,
//
///*!
// 该消息是被多端同时收取的。（即其他端正同时登录，一条消息被同时发往多端。客户可以通过这个状态值更新自己的某些
// UI状态）。
// */
//ReceivedStatus_MULTIPLERECEIVE = 16,

//RCT_ENUM_CONVERTER(RCReceivedStatus, (@{
//                                          @"unread": @(ReceivedStatus_UNREAD),
//                                          @"read": @(ReceivedStatus_READ),
//                                          @"listened": @(ReceivedStatus_LISTENED),
//                                          @"downloaded": @(ReceivedStatus_DOWNLOADED),
//                                          @"retrieved": @(ReceivedStatus_RETRIEVED),
//                                          @"multiplereceive": @(ReceivedStatus_MULTIPLERECEIVE)
//                                          }), ReceivedStatus_READ, unsignedIntegerValue)


RCT_ENUM_CONVERTER(RCConversationType, (@{
                                          @"private": @(ConversationType_PRIVATE),
                                          @"discussion": @(ConversationType_DISCUSSION),
                                          @"group": @(ConversationType_GROUP),
                                          @"chatroom": @(ConversationType_CHATROOM),
                                          @"customer_service": @(ConversationType_CUSTOMERSERVICE),
                                          @"system": @(ConversationType_SYSTEM),
                                          @"app_service": @(ConversationType_APPSERVICE),
                                          @"publish_service": @(ConversationType_PUBLICSERVICE),
                                          @"push_service": @(ConversationType_PUSHSERVICE)
                                 }), ConversationType_PRIVATE, unsignedIntegerValue)

@end
