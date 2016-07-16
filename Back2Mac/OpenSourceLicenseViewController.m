//
//  OpenSourceLicenseViewController.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "OpenSourceLicenseViewController.h"

@interface OpenSourceLicenseViewController ()
@property (nonatomic, strong) IBOutlet UITextView* textView;
@end

@implementation OpenSourceLicenseViewController

- (void)viewDidLoad {
    NSString* text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"opensources" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    [self.textView setText:text];
    
    [super viewDidLoad];
}
- (void)viewDidLayoutSubviews {
    self.textView.contentOffset = CGPointZero;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
