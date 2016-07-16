//
//  B2MActivity.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "B2MActivity.h"

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
    for (id obj in activityItems) {
        if ([obj isKindOfClass:[NSURL class]] == FALSE) return FALSE;
    }
    
    return TRUE;
}

+(UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    if (activityItems.count > 0) {
        self.activityURL = activityItems[0];
    }
}

- (void)performActivity {
    if ([self.type isEqualToString:@"addToBookmark"]) {
        
    }else if ([self.type isEqualToString:@"openInSafari"]) {
        [[UIApplication sharedApplication] openURL:self.activityURL];
    }
    
    [self activityDidFinish:YES];
}

@end
