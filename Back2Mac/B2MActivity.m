//
//  B2MActivity.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "B2MActivity.h"
#import "Back2Mac.h"

@interface B2MActivity ()
@property (nonatomic, strong) NSString* type;
@property (nonatomic, strong) NSURL* activityURL;
@end

@implementation B2MActivity

-(id)initWithType:(NSString *)type {
    if ((self = [super init])) {
        _type = type;
    }
    return self;
}

- (NSString *)activityType {
    return self.type;
}

- (NSString *)activityTitle {
    if ([self.type isEqualToString:@"addToBookmark"]) {
        return @"책갈피 추가";
    }else if ([self.type isEqualToString:@"openInSafari"]) {
        return @"Safari에서 열기";
    }else{
        return nil;
    }
}

- (UIImage *)activityImage {
    if ([self.type isEqualToString:@"addToBookmark"]) {
        return [UIImage imageNamed:@"bookmark"];
    }else if ([self.type isEqualToString:@"openInSafari"]) {
        return [UIImage imageNamed:@"safari"];
    }else{
        return nil;
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    if ([self.type isEqualToString:@"addToBookmark"]) {
        return (activityItems.count > 0 && [self extractArticleId:activityItems[0]] != nil);
    }else if ([self.type isEqualToString:@"openInSafari"]) {
        return (activityItems.count > 0 && [activityItems[0] isKindOfClass:[NSURL class]]);
    }else{
        return FALSE;
    }
}

+(UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    if (activityItems.count > 0) {
        self.activityURL = activityItems[0];
    }
}

- (nullable UIViewController *)activityViewController {
    if ([self.type isEqualToString:@"addToBookmark"]) {
        NSString* articleId = [self extractArticleId:self.activityURL];
        if (articleId != nil) {
            [Back2Mac articleId:articleId toBookmark:YES userInfo:nil];
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Back2Mac"
                                                                                     message:@"책갈피 표시 완료"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self activityDidFinish:YES];
            }];
            [alertController addAction:cancelAction];
            
            return alertController;
        }else return nil;
    }else return nil;
}

- (void)performActivity {
    if ([self.type isEqualToString:@"addToBookmark"]) {
        NSLog(@"perform bookmark");
        
    }else if ([self.type isEqualToString:@"openInSafari"]) {
        [[UIApplication sharedApplication] openURL:self.activityURL];
    }
    
    [self activityDidFinish:YES];
}

#pragma mark -

-(NSString *)extractArticleId:(NSURL *)url {
    NSString* urlString = url.absoluteString;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"(?:macnews.tistory.com\\/m\\/post\\/|macnews.tistory.com\\/)(\\d*)"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:nil];
    NSTextCheckingResult* match = [regex firstMatchInString:urlString options:0 range:NSMakeRange(0, [urlString length])];
    if (match != nil) {
        NSString* articleId = [urlString substringWithRange:[match rangeAtIndex:1]];
        if (articleId.length == 0) return nil;
        else return articleId;
    }else return nil;
}

@end
