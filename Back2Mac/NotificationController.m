//
//  NotificationController.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "NotificationController.h"
#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>
#import "Back2Mac.h"
#include "ArticleViewController.h"

@implementation NotificationController

+(void)processRemoteNotification:(NSDictionary *)userInfo needToConfirm:(BOOL)needConfirm {
    if (needConfirm) {
        NSString* sound = [userInfo[@"aps"] objectForKey:@"sound"];
        if (sound != nil) {
            SystemSoundID soundID;
            CFBundleRef mainBundle = CFBundleGetMainBundle();
            CFURLRef ref = CFBundleCopyResourceURL(mainBundle, (CFStringRef)@"Tri-tone.caf", NULL, NULL);
            AudioServicesCreateSystemSoundID(ref, &soundID);
            AudioServicesPlaySystemSound(soundID);
            
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Back2Mac"
                                                                                 message:[userInfo[@"aps"] objectForKey:@"alert"]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleCancel
                                                             handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"보기" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self _remoteNotification:userInfo];
                                                         }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alertController animated:YES completion:nil];
    }else{
        [self _remoteNotification:userInfo];
    }
}

+(void)_remoteNotification:(NSDictionary *)userInfo {
    NSString* type = [userInfo objectForKey:@"type"];
    
    if ([type isEqualToString:@"article"]) {
        NSString* articleId = [userInfo objectForKey:@"articleId"];
        
        UITabBarController* mainTab = (UITabBarController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        UINavigationController* nav = (UINavigationController *)[[mainTab viewControllers] objectAtIndex:0];
        [nav popToRootViewControllerAnimated:NO];
        
        ArticleViewController* vc = [[UIStoryboard storyboardWithName:@"Main" bundle:NULL] instantiateViewControllerWithIdentifier:@"ARTICLE_VIEW"];
        [vc setArticleId:articleId];
        [nav pushViewController:vc animated:NO];
        
        [mainTab setSelectedIndex:0];
    }
}

@end
