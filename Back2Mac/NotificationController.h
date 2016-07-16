//
//  NotificationController.h
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationController : NSObject

+(void)processRemoteNotification:(NSDictionary *)userInfo needToConfirm:(BOOL)needConfirm;

@end
