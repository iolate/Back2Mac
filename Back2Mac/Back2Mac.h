//
//  Back2Mac.h
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const API_HOST;

extern NSString* const DEFAULT_RECEIVE_NOTI;
extern NSString* const DEFAULT_DEFAULT_VIEWER;
extern NSString* const DEFAULT_ASK_BEFORE_SAFARI;

@interface Back2Mac : NSObject

+(id)getUserDefaults:(NSString *)key;
+(id)getUserDefaults:(NSString *)key withDefault:(id)def;
+(void)setUserDefaults:(id)obj forKey:(NSString *)key;
+(NSURL *)getURL:(NSString *)articleId;
+(NSString *)uuid;
+(void)updateDeviceToServerWithCompletionHandler:(void (^)(BOOL isSuccess))completionBlock;

+(void)articleId:(NSString *)articleId toRead:(BOOL)opt;
+(NSArray *)readArticlesList;

+(void)articleId:(NSString *)articleId toBookmark:(BOOL)opt userInfo:(NSDictionary *)userInfo;
+(NSDictionary *)bookmarksList;
@end