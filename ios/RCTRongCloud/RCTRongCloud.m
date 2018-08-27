//
//  RCTRongCloud.m
//  RCTRongCloud
//
//  Created by LvBingru on 1/26/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import "RCTRongCloud.h"
#import <React/RCTEventEmitter.h>
#import <RongIMLib/RongIMLib.h>
#import "RCTConvert+RongCloud.h"
#import <React/RCTUtils.h>
#import <React/RCTEventDispatcher.h>
#import "RCTRongCloudVoiceManager.h"
#import <React/RCTImageLoader.h>

#define OPERATION_FAILED (@"operation returns false.")

@interface RCTRongCloud()<RCIMClientReceiveMessageDelegate, RCConnectionStatusChangeDelegate>

@property (nonatomic, strong) RCUserInfo *userInfo;
@property (nonatomic, strong) RCTRongCloudVoiceManager *voiceManager;

@end

@implementation RCTRongCloud

RCT_EXPORT_MODULE(RCTRongIMLib)

- (NSArray<NSString *> *)supportedEvents {
    return @[@"rongIMMsgRecved",@"rongIMConnectionStatus",@"msgSendOk",@"msgSendFailed"];
}
- (NSDictionary *)constantsToExport
{
    return @{};
};

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[RCIMClient sharedRCIMClient] setReceiveMessageDelegate:self object:nil];
        [[RCIMClient sharedRCIMClient] setRCConnectionStatusChangeDelegate:self];
        _voiceManager = [RCTRongCloudVoiceManager new];
    }
    return self;
}

- (void)dealloc
{
    RCIMClient* client = [RCIMClient sharedRCIMClient];
    [client disconnect];
}

+ (void)registerAPI:(NSString *)aString
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[RCIMClient sharedRCIMClient] initWithAppKey:aString];
    });
}

+ (void)setDeviceToken:(NSData *)aToken
{
    NSString *token =
    [[[[aToken description] stringByReplacingOccurrencesOfString:@"<"
                                                      withString:@""]
      stringByReplacingOccurrencesOfString:@">"
      withString:@""]
     stringByReplacingOccurrencesOfString:@" "
     withString:@""];
    
    [[RCIMClient sharedRCIMClient] setDeviceToken:token];
}
RCT_EXPORT_METHOD(setCurrentUserInfo:(NSDictionary*) json){
    _userInfo=[RCTConvert RCUserInfo:json];
    [[RCIMClient sharedRCIMClient] setCurrentUserInfo:_userInfo];
}

RCT_EXPORT_METHOD(connect:(NSString *)token resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [[RCIMClient sharedRCIMClient] connectWithToken:token success:^(NSString *userId) {
        // Connect 成功
        resolve(userId);
    } error:^(RCConnectErrorCode status) {
        // Connect 失败
        reject([NSString stringWithFormat:@"%d", (int)status], @"Connection error", nil);
    }
                                     tokenIncorrect:^() {
                                         // Token 失效的状态处理
                                         reject(@"tokenIncorrect", @"Incorrect token provided.", nil);
                                     }];
}

// 断开与融云服务器的连接，并不再接收远程推送
RCT_EXPORT_METHOD(logout:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [[RCIMClient sharedRCIMClient] logout];
    resolve(nil);
}

// 断开与融云服务器的连接，但仍然接收远程推送
RCT_EXPORT_METHOD(disconnect:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [[RCIMClient sharedRCIMClient] disconnect];
    resolve(nil);
}

RCT_EXPORT_METHOD(getConversation:(RCConversationType)type targetId:(NSString*)targetId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject){
    RCConversation *conversation=  [[RCIMClient sharedRCIMClient] getConversation:type targetId:targetId];
    resolve([self.class _convertConversation:conversation]);
}

RCT_EXPORT_METHOD(getConversationList:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    NSArray *array = [[RCIMClient sharedRCIMClient] getConversationList:@[@(ConversationType_PRIVATE),
                                                                          @(ConversationType_DISCUSSION),
                                                                          @(ConversationType_GROUP),
                                                                          @(ConversationType_CHATROOM),
                                                                          @(ConversationType_CUSTOMERSERVICE),
                                                                          @(ConversationType_SYSTEM),
                                                                          @(ConversationType_APPSERVICE),
                                                                          @(ConversationType_PUBLICSERVICE),
                                                                          @(ConversationType_PUSHSERVICE)]];
    NSMutableArray *newArray = [NSMutableArray new];
    for (RCConversation *conv in array) {
        NSDictionary *convDic = [self.class _convertConversation:conv];
        [newArray addObject:convDic];
    }
    resolve(newArray);
}

RCT_EXPORT_METHOD(getHistoryMessages: (RCConversationType) type targetId:(NSString*) targetId objectName:(NSString*) objectName oldestMessageId:(int) oldestMessageId count:(int) count
                  resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    NSArray *array;
    
    if(objectName==NULL||objectName.length==0){
        array=[[RCIMClient sharedRCIMClient] getHistoryMessages:type targetId:targetId oldestMessageId:oldestMessageId count:count];
    }else{
        array=[[RCIMClient sharedRCIMClient] getHistoryMessages:type targetId:targetId objectName:objectName oldestMessageId:oldestMessageId count:count];
    }
    
    NSMutableArray* newArray = [NSMutableArray new];
    for (RCMessage* msg in array) {
        NSDictionary* convDic = [self.class _convertMessage:msg];
        [newArray addObject:convDic];
    }
    resolve(newArray);
}


RCT_EXPORT_METHOD(getLatestMessages: (RCConversationType) type targetId:(NSString*) targetId count:(int) count
                  resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    NSArray* array = [[RCIMClient sharedRCIMClient] getLatestMessages:type targetId:targetId count:count];
    
    NSMutableArray* newArray = [NSMutableArray new];
    for (RCMessage* msg in array) {
        NSDictionary* convDic = [self.class _convertMessage:msg];
        [newArray addObject:convDic];
    }
    resolve(newArray);
}
- (void)sendImageMessage:(RCConversationType) type targetId:(NSString*) targetId content:(NSDictionary*) json pushContent: (NSString*) pushContent pushData:(NSString*) pushData
                 resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject{
    
    RCIMClient* client = [RCIMClient sharedRCIMClient];
    NSString * uri = [RCTConvert NSString:json[@"imageUrl"]];
    
    
    RCImageMessage *content = [RCImageMessage messageWithImageURI:uri];
    [content setSenderUserInfo:_userInfo];
    [content setFull:[json[@"full"] boolValue]];
    [content setExtra:[RCTConvert NSString:json[@"extra"]]];
    
    
    
    
    
    RCMessage *msg=[client sendMediaMessage:type targetId:targetId content:content pushContent:nil pushData:nil progress:^(int progress, long messageId) {
    
    } success:^(long messageId) {
        [self sendEventWithName:@"msgSendOk" body:@(messageId)];
    } error:^(RCErrorCode errorCode, long messageId) {
        NSMutableDictionary* dic = [NSMutableDictionary new];
        dic[@"messageId"] = @(messageId);
        dic[@"errCode"] = @((int)errorCode);
        [self sendEventWithName:@"msgSendFailed" body:dic];
    } cancel:^(long messageId) {
        
    }];
    resolve([self.class _convertMessage:msg]);
    
    
    
    
    return;
}
- (void)sendLocationMessage:(RCConversationType) type targetId:(NSString*) targetId content:(NSDictionary*) json pushContent: (NSString*) pushContent pushData:(NSString*) pushData resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject{
    
    
    CLLocationCoordinate2D location=CLLocationCoordinate2DMake([[json objectForKey:@"lat"] doubleValue],[[json objectForKey:@"lng"] doubleValue]);
    RCLocationMessage *content = [RCLocationMessage messageWithLocationImage:nil location:location locationName:[json valueForKey:@"poi"]];
    [content setSenderUserInfo:_userInfo];
    
    RCIMClient* client = [RCIMClient sharedRCIMClient];
    RCMessage *msg=[client sendMessage:type targetId:targetId content:content pushContent:pushContent pushData:pushData success:^(long messageId) {
        [self sendEventWithName:@"msgSendOk" body:@(messageId)];
    } error:^(RCErrorCode nErrorCode, long messageId) {
        NSMutableDictionary* dic = [NSMutableDictionary new];
        dic[@"messageId"] = @(messageId);
        dic[@"errCode"] = @((int)nErrorCode);
        [self sendEventWithName:@"msgSendFailed" body:dic];
        
    }];
    
    resolve([self.class _convertMessage:msg]);
    
    
    
    
    return;
}
-(void)sendMediaMessage:(RCConversationType) type targetId:(NSString*) targetId content:(NSDictionary*) json pushContent: (NSString*) pushContent pushData:(NSString*) pushData resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject{
    
    RCImageMessage *content = [RCTConvert RCMessageContent:json];
    [content setSenderUserInfo:_userInfo];
   
    
    
    RCIMClient* client = [RCIMClient sharedRCIMClient];
    
    
    RCMessage *msg=[client sendMediaMessage:type targetId:targetId content:content pushContent:nil pushData:nil progress:^(int progress, long messageId) {
        
    } success:^(long messageId) {
        [self sendEventWithName:@"msgSendOk" body:@(messageId)];
    } error:^(RCErrorCode errorCode, long messageId) {
        NSMutableDictionary* dic = [NSMutableDictionary new];
        dic[@"messageId"] = @(messageId);
        dic[@"errCode"] = @((int)errorCode);
        [self sendEventWithName:@"msgSendFailed" body:dic];
    } cancel:^(long messageId) {
        
    }];
    resolve([self.class _convertMessage:msg]);
    

}

RCT_EXPORT_METHOD(sendMessage: (RCConversationType) type targetId:(NSString*) targetId content:(NSDictionary*) json
                  pushContent: (NSString*) pushContent pushData:(NSString*) pushData
                  resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    
    if ([[json valueForKey:@"type"] isEqualToString:@"image"]) {
        [self sendImageMessage:type targetId:targetId content:json pushContent:pushContent pushData:pushData resolve:resolve reject:reject];
        
        return;
    }
    if ([[json valueForKey:@"type"] isEqualToString:@"media"]) {
        [self sendMediaMessage:type targetId:targetId content:json pushContent:pushContent pushData:pushData resolve:resolve reject:reject];
        
        return;
    }
    /*if ([[json valueForKey:@"type"] isEqualToString:@"location"]) {
     [self sendLocationMessage:type targetId:targetId content:json pushContent:pushContent pushData:pushData resolve:resolve reject:reject];
     return;
     }*/
    RCMessageContent* content = [RCTConvert RCMessageContent:json];
    [content setSenderUserInfo:_userInfo];
    RCIMClient* client = [RCIMClient sharedRCIMClient];
    RCMessage *msg=[client sendMessage:type targetId:targetId content:content pushContent:pushContent pushData:pushData success:^(long messageId) {
        [self sendEventWithName:@"msgSendOk" body:@(messageId)];
    } error:^(RCErrorCode nErrorCode, long messageId) {
        NSMutableDictionary* dic = [NSMutableDictionary new];
        dic[@"messageId"] = @(messageId);
        dic[@"errCode"] = @((int)nErrorCode);
        [self sendEventWithName:@"msgSendFailed" body:dic];
        
    }];
    
    resolve([self.class _convertMessage:msg]);
}

RCT_EXPORT_METHOD(insertMessage: (RCConversationType) type targetId:(NSString*) targetId senderId:(NSString*) senderId content:(NSDictionary*) json
                  resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    RCMessageContent* content = [RCTConvert RCMessageContent:json];
    RCIMClient* client = [RCIMClient sharedRCIMClient];
    RCMessage *msg=[client insertOutgoingMessage:type targetId:targetId sentStatus:SentStatus_SENT content:content];
    // RCMessage* msg = [client insertMessage:type targetId:targetId senderUserId:senderId sendStatus:SentStatus_SENT content:content];
    resolve([self.class _convertMessage:msg]);
}

RCT_EXPORT_METHOD(setMessageReceivedStatus:(NSInteger) messageId receivedStatus:(NSInteger) receivedStatus resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject){
    [[RCIMClient sharedRCIMClient] setMessageReceivedStatus:messageId receivedStatus:receivedStatus];
    resolve(nil);
    
}
RCT_EXPORT_METHOD(clearMessageUnreadStatus: (RCConversationType) type targetId:(NSString*) targetId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    RCIMClient* client = [RCIMClient sharedRCIMClient];
    [client clearMessagesUnreadStatus:type targetId:targetId];
    resolve(nil);
}

RCT_EXPORT_METHOD(canRecordVoice:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [_voiceManager canRecordVoice:^(NSError *error, NSDictionary *result) {
        if (error) {
            reject([NSString stringWithFormat:@"%ld", error.code], error.description, error);
        }
        else {
            resolve(result);
        }
    }];
}

RCT_EXPORT_METHOD(startRecordVoice:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [_voiceManager startRecord:^(NSError *error,NSDictionary *result) {
        if (error) {
            reject([NSString stringWithFormat:@"%ld", error.code], error.description, error);
        }
        else {
            resolve(result);
        }
    }];
}

RCT_EXPORT_METHOD(cancelRecordVoice)
{
    [_voiceManager cancelRecord];
}

RCT_EXPORT_METHOD(finishRecordVoice)
{
    [_voiceManager finishRecord];
}

RCT_EXPORT_METHOD(startPlayVoice:(NSDictionary*)json rosolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    RCVoiceMessage* voice = (RCVoiceMessage *)[RCTConvert RCMessageContent:json];
    [_voiceManager startPlayVoice:voice result:^(NSError *error, NSDictionary *result) {
        if (error) {
            reject([NSString stringWithFormat:@"%ld", error.code], error.description, error);
        }
        else {
            resolve(result);
        }
    }];
}

RCT_EXPORT_METHOD(stopPlayVoice)
{
    [_voiceManager stopPlayVoice];
}

#pragma mark - delegate
- (void)onReceived:(RCMessage *)message
              left:(int)nLeft
            object:(id)object
{
    [self sendEventWithName:@"rongIMMsgRecved" body:[self.class _convertMessage:message]];
}

- (void)onConnectionStatusChanged:(RCConnectionStatus)status
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    switch (status){
        case ConnectionStatus_UNKNOWN:
            [dict setObject:@(-2) forKey:@"code"];
            [dict setObject:@"Unknown" forKey:@"message"];
            break;
        case ConnectionStatus_NETWORK_UNAVAILABLE:
            [dict setObject:@(-1) forKey:@"code"];
            [dict setObject:@"Network is unavailable." forKey:@"message"];
            break;
        case ConnectionStatus_Connected:
            [dict setObject:@(0) forKey:@"code"];
            [dict setObject:@"Connect Success." forKey:@"message"];
            break;
        case ConnectionStatus_Connecting:
            [dict setObject:@(1) forKey:@"code"];
            [dict setObject:@"Connecting" forKey:@"message"];
            break;
        case ConnectionStatus_Unconnected:
        case ConnectionStatus_SignUp:
            [dict setObject:@(2) forKey:@"code"];
            [dict setObject:@"Disconnected" forKey:@"message"];
            break;
        case ConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT:
            [dict setObject:@(3) forKey:@"code"];
            [dict setObject:@"Login on the other device, and be kicked offline." forKey:@"message"];
            break;
        case ConnectionStatus_TOKEN_INCORRECT:
            [dict setObject:@(4) forKey:@"code"];
            [dict setObject:@"Token incorrect." forKey:@"message"];
            break;
        case ConnectionStatus_SERVER_INVALID:
            [dict setObject:@(5) forKey:@"code"];
            [dict setObject:@"Server invalid." forKey:@"message"];
            break;
        case ConnectionStatus_Cellular_2G:
        case ConnectionStatus_Cellular_3G_4G:
        case ConnectionStatus_WIFI:
        case ConnectionStatus_LOGIN_ON_WEB:
        case ConnectionStatus_VALIDATE_INVALID:
        case ConnectionStatus_DISCONN_EXCEPTION:
        default:
            //ignore
            return;
    }
    [self sendEventWithName:@"rongIMConnectionStatus" body:[dict copy]];
}

#pragma mark - private

+ (NSDictionary *)_convertConversation:(RCConversation *)conversation
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    dic[@"title"] = conversation.conversationTitle;
    dic[@"type"] = [self _convertConversationType: conversation.conversationType];
    dic[@"targetId"] = conversation.targetId;
    dic[@"unreadCount"] = @(conversation.unreadMessageCount);
    dic[@"lastMessage"] = [self _converMessageContent:conversation.lastestMessage];
    
    dic[@"isTop"] = @(conversation.isTop);
    dic[@"receivedStatus"] = @(conversation.receivedStatus);
    dic[@"sentStatus"] = @(conversation.sentStatus);
    dic[@"receivedTime"] = @(conversation.receivedTime);
    dic[@"sentTime"] = @(conversation.sentTime);
    dic[@"draft"] = conversation.draft;
    dic[@"objectName"] = conversation.objectName;
    dic[@"senderUserId"] = conversation.senderUserId;
    
    dic[@"conversationTitle"] = conversation.conversationTitle;
    
    dic[@"jsonDict"] = conversation.jsonDict;
    dic[@"lastestMessageId"] = @(conversation.lastestMessageId);
    return dic;
}

+ (NSString *) _convertConversationType: (RCConversationType) type
{
    switch(type) {
        case ConversationType_PRIVATE: return @"private";
        case ConversationType_DISCUSSION: return @"discussion";
        case ConversationType_GROUP: return @"group";
        case ConversationType_CHATROOM: return @"chatroom";
        case ConversationType_CUSTOMERSERVICE: return @"customer_service";
        case ConversationType_SYSTEM: return @"system";
        case ConversationType_APPSERVICE: return @"app_service";
        case ConversationType_PUBLICSERVICE: return @"public_service";
        case ConversationType_PUSHSERVICE: return @"push_service";
        default: return @"unknown";
    }
}

+ (NSDictionary *)_convertMessage:(RCMessage *)message
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    dic[@"senderId"] = message.senderUserId;
    dic[@"targetId"] = message.targetId;
    dic[@"conversationType"] = [self _convertConversationType: message.conversationType];;
    dic[@"extra"] = message.extra;
    dic[@"messageId"] = @(message.messageId);
    dic[@"receivedTime"] = @(message.receivedTime);
    dic[@"sentTime"] = @(message.sentTime);
    dic[@"content"] = [self _converMessageContent:message.content];
    
    dic[@"messageDirection"] = @(message.messageDirection);
    dic[@"receivedStatus"] = @(message.receivedStatus);
    dic[@"sentStatus"] = @(message.sentStatus);
    dic[@"objectName"] = message.objectName;
    dic[@"messageUId"] = message.messageUId;
    return dic;
}

+ (NSDictionary *)_converMessageContent:(RCMessageContent *)messageContent
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    if ([messageContent isKindOfClass:[RCTextMessage class]]) {
        RCTextMessage *message = (RCTextMessage *)messageContent;
        dic[@"type"] = @"text";
        dic[@"content"] = message.content;
        dic[@"extra"] = message.extra;
    }
    else if ([messageContent isKindOfClass:[RCVoiceMessage class]]) {
        RCVoiceMessage *message = (RCVoiceMessage *)messageContent;
        dic[@"type"] = @"voice";
        dic[@"duration"] = @(message.duration);
        dic[@"extra"] = message.extra;
        if (message.wavAudioData) {
            dic[@"base64"] = [message.wavAudioData base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
        }
    }
    else if ([messageContent isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *message = (RCImageMessage*)messageContent;
        dic[@"type"] = @"image";
        if ([[message.imageUrl substringToIndex:1] isEqualToString:@"/"]) {
            dic[@"imageUrl"] = [NSString stringWithFormat: @"file://%@", message.imageUrl];
        } else {
            dic[@"imageUrl"] = message.imageUrl;
        }
        // dic[@"thumb"] = [NSString stringWithFormat:@"data:image/png;base64,%@", [UIImagePNGRepresentation(message.thumbnailImage) base64EncodedStringWithOptions:0]];
        dic[@"extra"] = message.extra;
    }
    else if ([messageContent isKindOfClass:[RCCommandNotificationMessage class]]){
        RCCommandNotificationMessage * message = (RCCommandNotificationMessage*)messageContent;
        dic[@"type"] = @"notify";
        dic[@"name"] = message.name;
        dic[@"data"] = message.data;
    }else if([messageContent isKindOfClass:[RCRichContentMessage class]]){
        RCRichContentMessage *message=(RCRichContentMessage*)messageContent;
        dic[@"type"]=@"rich";
        dic[@"imageUrl"]=message.imageURL;
        dic[@"title"]=message.title;
        dic[@"content"]=message.digest;
        dic[@"url"]=message.url;
        dic[@"extra"]=message.extra;
        
    }else if([messageContent isKindOfClass:[RCLocationMessage class]]){
        RCLocationMessage *message=(RCLocationMessage*)messageContent;
        dic[@"type"]=@"location";
        //dic[@"content"]= [NSString stringWithFormat:@"data:image/png;base64,%@", [UIImagePNGRepresentation(message.thumbnailImage) base64EncodedStringWithOptions:0]];;
        dic[@"poi"]=message.locationName;
        dic[@"lat"]=@(message.location.latitude);
        dic[@"lng"]=@(message.location.longitude);
        dic[@"extra"]=message.extra;
        
    }else if([messageContent isKindOfClass:[RCFileMessage class]]){
        RCFileMessage *message=(RCFileMessage*)messageContent;
        dic[@"type"]=@"media";
        //dic[@"content"]= [NSString stringWithFormat:@"data:image/png;base64,%@", [UIImagePNGRepresentation(message.thumbnailImage) base64EncodedStringWithOptions:0]];;
        dic[@"contentType"]=message.type;
        if(message.fileUrl)
            dic[@"mediaUrl"]=message.fileUrl;
        if(message.localPath)
              dic[@"mediaUrl"]=message.localPath;
        NSData *extraData=[[message extra] dataUsingEncoding:NSUTF8StringEncoding];
        id allkeys=[NSJSONSerialization JSONObjectWithData:extraData options:NSJSONWritingPrettyPrinted error:nil];
       
        dic[@"thumb"]=allkeys[@"thumb"];
        
        dic[@"extra"]=allkeys[@"extra"];
        
    } else {
        dic[@"type"] = @"unknown";
    }
    if(messageContent.senderUserInfo!=NULL){
        NSMutableDictionary *user = [NSMutableDictionary new];
        [user setValue:messageContent.senderUserInfo.userId forKey:@"userId"];
        [user setValue:messageContent.senderUserInfo.name forKey:@"name"];
        [user setValue:messageContent.senderUserInfo.portraitUri forKey:@"portraitUri"];
        [dic  setValue:user forKey:@"userInfo"];
        //dic[@"userInfo"]=user;
    }
    return dic;
}


@end
