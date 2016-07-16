//
//  AppDelegate.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "AppDelegate.h"
#import "Back2Mac.h"
#import "NotificationController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    
    if (([[[UIApplication sharedApplication] currentUserNotificationSettings] types] & UIUserNotificationTypeBadge) != 0) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
    
    NSDictionary* remoteUserInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteUserInfo) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [NotificationController processRemoteNotification:remoteUserInfo needToConfirm:NO];
        });
    }
    
    return YES;
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if(application.applicationState == UIApplicationStateActive){
        [NotificationController processRemoteNotification:userInfo needToConfirm:YES];
    }else if(application.applicationState == UIApplicationStateInactive){
        [NotificationController processRemoteNotification:userInfo needToConfirm:NO];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)tokenData {
#if !TARGET_IPHONE_SIMULATOR
    NSMutableString *deviceToken = [NSMutableString string];
    const unsigned char* ptr = (const unsigned char*)[tokenData bytes];
    for(int i = 0 ; i < 32 ; i++)
        [deviceToken appendFormat:@"%02x", ptr[i]];
    
    //[DC saveAPNSToken:deviceToken];
    [Back2Mac setUserDefaults:deviceToken forKey:@"token"];
    [Back2Mac updateDeviceToServerWithCompletionHandler:nil];
#endif
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    //handle the actions
    NSLog(@"%@ %@ %@", NSStringFromSelector(_cmd), identifier, userInfo);
    
    if ([identifier isEqualToString:@"declineAction"]) {
        
    } else if ([identifier isEqualToString:@"answerAction"]) {
        
    }
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), error);
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
