//
//  Back2Mac.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "Back2Mac.h"
#import <UIKit/UIKit.h>
#import "JSONProxy.h"

NSString* const API_HOST = @"b2m.iolate.kr";

NSString* const DEFAULT_RECEIVE_NOTI = @"receive_noti";
NSString* const DEFAULT_DEFAULT_VIEWER = @"default_viewer";
NSString* const DEFAULT_ASK_BEFORE_SAFARI = @"ask_safari";


@implementation Back2Mac

+(id)getUserDefaults:(NSString *)key {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:key];
}

+(id)getUserDefaults:(NSString *)key withDefault:(id)def {
    return [Back2Mac getUserDefaults:key] ?: def;
}

+(void)setUserDefaults:(id)obj forKey:(NSString *)key {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:obj forKey:key];
    [userDefaults synchronize];
}

+(NSURL *)getURL:(NSString *)articleId {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://macnews.tistory.com/%@", articleId]];
}

+(NSString *)uuid {
    NSString* uuid = [Back2Mac getUserDefaults:@"uuid"];
    
    if(uuid == nil || uuid.length == 0){
        uuid = [[NSUUID UUID] UUIDString];
        [Back2Mac setUserDefaults:uuid forKey:@"uuid"];
    }
    
    return uuid;
}

+(void)updateDeviceToServerWithCompletionHandler:(void (^)(BOOL isSuccess))completionBlock {
    NSString* token = [Back2Mac getUserDefaults:@"token"];
    if (token == nil) {
        NSLog(@"[ERROR] Cannot update device. token is nil.");
        if (completionBlock != nil) {
            completionBlock(FALSE);
        }
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"/app/push"];
    NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:API_HOST path:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSString* uuid = [Back2Mac uuid];
    NSNumber* enabled = [Back2Mac getUserDefaults:DEFAULT_RECEIVE_NOTI] ?: @1;
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    UIDevice *dev = [UIDevice currentDevice];
    NSString *deviceName = dev.name;
    NSString *deviceModel = dev.model;
    NSString *deviceVersion = dev.systemVersion;
    
    NSMutableDictionary* postData = [NSMutableDictionary dictionaryWithDictionary:
                                     @{@"uuid": uuid, @"enabled": enabled, @"token": token, @"app_version": appVersion,
                                       @"device_name": deviceName, @"device_model": deviceModel, @"device_version": deviceVersion}];
#ifdef DEBUG
    [postData setObject:@"sandbox" forKey:@"development"];
#endif
    
    NSData* post = [postData toJSON];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[post length]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:[NSString stringWithFormat:@"Back2Mac/%@; iOS/%@", appVersion, deviceVersion] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:post];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *urlR, NSData *returnData, NSError *e) {
                               NSLog(@"Response: %@", [returnData parseJSON]);
                               NSDictionary* result = [returnData parseJSON];
                               if (completionBlock != nil) {
                                   if (result != nil && [[result objectForKey:@"result"] isEqual:@0]) {
                                       completionBlock(TRUE);
                                   }else{
                                       completionBlock(FALSE);
                                   }
                               }
                           }];
    
}

typedef NS_ENUM(NSInteger, ArticleStoreType) {
    ArticleStoreTypeRead,
    ArticleStoreTypeBookmark
};

+(void)_articleId:(NSString *)articleId toStore:(BOOL)store withUserInfo:(NSDictionary *)userInfo for:(ArticleStoreType)type {
    NSString* path = nil;
    if (type == ArticleStoreTypeRead) path = @"read.plist";
    else if (type == ArticleStoreTypeBookmark) path = @"bookmark.plist";
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    path = [documentsDirectory stringByAppendingPathComponent:path];
    
    if (type == ArticleStoreTypeRead) {
        NSMutableArray* data = [NSMutableArray arrayWithContentsOfFile:path] ?: [NSMutableArray array];
        
        if (store && [data containsObject:articleId] == FALSE) {
            [data addObject:articleId];
        }else if (store == FALSE && [data containsObject:articleId]) {
            [data removeObject:articleId];
        }else { return; }
        
        [data writeToFile:path atomically:NO];
    }else if (type == ArticleStoreTypeBookmark) {
        NSMutableDictionary* data = [NSMutableDictionary dictionaryWithContentsOfFile:path] ?: [NSMutableDictionary dictionary];
        
        if (store && [data.allKeys containsObject:articleId] == FALSE) {
            [data setObject:userInfo forKey:articleId];
        }else if (store == FALSE && [data.allKeys containsObject:articleId]) {
            [data removeObjectForKey:articleId];
        }else { return; }
        
        [data writeToFile:path atomically:NO];
    }
}

+(void)articleId:(NSString *)articleId toRead:(BOOL)opt {
    [self _articleId:articleId toStore:opt withUserInfo:nil for:ArticleStoreTypeRead];
}

+(void)articleId:(NSString *)articleId toBookmark:(BOOL)opt userInfo:(NSDictionary *)userInfo {
    [self _articleId:articleId toStore:opt withUserInfo:userInfo for:ArticleStoreTypeBookmark];
}

+(NSArray *)readArticlesList {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:@"read.plist"];
    
    return [NSArray arrayWithContentsOfFile:path] ?: [NSArray array];
}

+(NSDictionary *)bookmarksList {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:@"bookmark.plist"];
    
    return [NSDictionary dictionaryWithContentsOfFile:path] ?: [NSDictionary dictionary];
}

@end