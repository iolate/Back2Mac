//
//  ArticleViewController.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "Back2Mac.h"
#import "ArticleViewController.h"
#import "MBProgressHUD.h"
#import "JSONProxy.h"
#import "B2MActivity.h"

#define UIButtonBarArrowLeft        105
#define UIButtonBarArrowRight       106

@interface ArticleViewController () <UIGestureRecognizerDelegate, UIScrollViewDelegate, UIWebViewDelegate> {
    CGFloat webViewOriginHeight;
    CGFloat bottomBarOriginY;
    BOOL bottomBarLock;
    
    BOOL useMobileWeb;
    BOOL askToSafari;
}
@property (nonatomic, strong) IBOutlet UIWebView* webView;
@property (nonatomic, strong) IBOutlet UIToolbar* bottomBar;

@property (nonnull, strong) NSURL* lastLoadingURL;
@property (nonatomic) NSInteger webHistoryIndex;
@property (nonatomic, strong) NSMutableArray* webHistory;
@property (nonatomic, strong) UIBarButtonItem* btnPrev;
@property (nonatomic, strong) UIBarButtonItem* btnNext;

@property (nonatomic, strong) MBProgressHUD *hud;
@end

@implementation ArticleViewController

#pragma mark - fetch
-(void)errorAlertWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self.hud hideAnimated:YES];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Back2Mac"
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

-(void)_fetchArticle:(NSString *)articleId completion:(void (^)(NSString* articleId, NSDictionary* item))completionBlock {
    if (articleId == nil) {
        [self errorAlertWithMessage:@"글이 선택되지 않았습니다."];
        return;
    }
    
    NSString* url = [NSString stringWithFormat:@"http://%@/view/%@", API_HOST, articleId];
    NSDictionary* api_data = [NSDictionary dictionaryWithContentsOfJSONURLString:url];
    
    if (api_data != nil) {
        if ([api_data[@"result"] isEqual:@0]) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                [self.hud hideAnimated:YES];
                if (completionBlock != nil) {
                    completionBlock(articleId, api_data[@"item"]);
                }
            });
            return;
        }else{
            NSString* error = nil;
            if ([api_data.allKeys containsObject:@"error"]) {
                error = api_data[@"error"];
            }else {
                error = [NSString stringWithFormat:@"Error %@", api_data[@"result"]];
            }
            [self errorAlertWithMessage:error];
        }
    }else{
        [self errorAlertWithMessage:@"데이터 불러오기 실패"];
    }
}

-(void)fetchArticle:(NSString *)articleId completion:(void (^)(NSString* articleId, NSDictionary* item))completionBlock {
    if (self.hud == nil) {
        _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:self.hud];
    }
    [self.hud showAnimated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _fetchArticle:articleId completion:completionBlock];
    });
}

#pragma mark - view cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize BarButton items
    _btnPrev = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIButtonBarArrowLeft target:self action:@selector(handleBarButton:)];
    self.btnPrev.tag = 1;
    _btnNext = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIButtonBarArrowRight target:self action:@selector(handleBarButton:)];
    self.btnNext.tag = 2;
    UIBarButtonItem* btnRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(handleBarButton:)];
    btnRefresh.tag = 3;
    UIBarButtonItem* btnAction = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(handleBarButton:)];
    btnAction.tag = 4;
    
    #define BarButtonFlexible [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]
    self.bottomBar.items = @[self.btnPrev, BarButtonFlexible,
                             self.btnNext, BarButtonFlexible,
                             btnRefresh, BarButtonFlexible,
                             btnAction];
    
    // WebView
    self.webView.scrollView.delegate = self;
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    tapGesture.delegate = self;
    [self.webView addGestureRecognizer:tapGesture];
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.delegate = self;
    [self.webView addGestureRecognizer:panGesture];
    
    // UserDefaults
    askToSafari = [[Back2Mac getUserDefaults:DEFAULT_ASK_BEFORE_SAFARI withDefault:[NSNumber numberWithBool:TRUE]] boolValue];
    useMobileWeb = ([[Back2Mac getUserDefaults:DEFAULT_DEFAULT_VIEWER withDefault:@0] integerValue] == 1);
    
    if (useMobileWeb) {
        [Back2Mac articleId:self.articleId toRead:YES];
        [self addHistoryAndLoad:[Back2Mac getURL:self.articleId]];
    } else {
        _webHistory = [NSMutableArray array];
        _webHistoryIndex = -1;
        [Back2Mac articleId:self.articleId toRead:YES];
        
        // Fetch article
        [self fetchArticle:self.articleId completion:^(NSString *articleId, NSDictionary *item) {
            [self addHistoryAndLoad:articleId withItem:item];
        }];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    bottomBarOriginY = self.bottomBar.frame.origin.y;
    webViewOriginHeight = self.webView.frame.size.height;
    
    //Fix for UIMenu
    if ([self.navigationController.navigationBar isHidden]) {
        CGRect frame = self.bottomBar.frame;
        CGRect webViewFrame = self.webView.frame;
        self.webView.frame = CGRectMake(webViewFrame.origin.x, webViewFrame.origin.y, webViewFrame.size.width, webViewFrame.size.height+frame.size.height);
        self.bottomBar.frame = CGRectMake(frame.origin.x, bottomBarOriginY+frame.size.height, frame.size.width, frame.size.height);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Web view history

-(void)addHistoryAndLoad:(NSURL *)url {
    if (self.webHistoryIndex != self.webHistory.count - 1) {
        [self.webHistory removeObjectsInRange:NSMakeRange(self.webHistoryIndex+1, self.webHistory.count-self.webHistoryIndex-1)];
    }
    [self.webHistory addObject:url];
    self.webHistoryIndex = self.webHistory.count - 1;
    [self updateBarButtonState];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void)addHistoryAndLoad:(NSString *)articleId withItem:(NSDictionary *)item {
    if (self.webHistoryIndex != self.webHistory.count - 1) {
        [self.webHistory removeObjectsInRange:NSMakeRange(self.webHistoryIndex+1, self.webHistory.count-self.webHistoryIndex-1)];
    }
    [self.webHistory addObject:articleId];
    self.webHistoryIndex = self.webHistory.count - 1;
    [self updateBarButtonState];
    
    [self updateWebViewWithItem:item];
}

-(void)updateBarButtonState {
    if (useMobileWeb) {
        self.btnPrev.enabled = self.webView.canGoBack;
        self.btnNext.enabled = self.webView.canGoForward;
    }else{
        self.btnPrev.enabled = (self.webHistoryIndex > 0);
        self.btnNext.enabled = (self.webHistoryIndex < self.webHistory.count-1);
    }
}

-(void)loadFromHistory:(NSInteger)historyIndex {
    if (self.webHistoryIndex == historyIndex || historyIndex >= self.webHistory.count) return;
    
    id obj = self.webHistory[historyIndex];
    if ([obj isKindOfClass:[NSURL class]]) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:obj]];
        self.webHistoryIndex = historyIndex;
        
        [self updateBarButtonState];
    }else if ([obj isKindOfClass:[NSString class]]) {
        [self fetchArticle:obj completion:^(NSString *articleId, NSDictionary *item) {
            [self updateWebViewWithItem:item];
            self.webHistoryIndex = historyIndex;
            
            [self updateBarButtonState];
        }];
    }
}

-(void)webViewGoBack {
    if (useMobileWeb) {
        if (self.webView.canGoBack) [self.webView goBack];
    }else{
        if (self.webHistoryIndex > 0) [self loadFromHistory:self.webHistoryIndex-1];
    }
}

-(void)webViewGoForward {
    if (useMobileWeb) {
        if (self.webView.canGoForward) [self.webView goForward];
    }else{
        if (self.webHistoryIndex < self.webHistory.count-1) [self loadFromHistory:self.webHistoryIndex+1];
    }
}


#pragma mark - Web view

-(void)updateWebViewWithItem:(NSDictionary *)item {
    self.title = item[@"title"];
    
    NSString* html = [NSString stringWithFormat:@"<!DOCTYPE html><html lang=\"ko\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, width=device-width\"><link rel=\"stylesheet\" href=\"tistory/T.m.blog.css\"><link rel=\"stylesheet\" href=\"tistory/style_h.css\"></head><body><div class=\"viewer\"> \
                      \
                      <div class=\"area_tit\"><h2>%@</h2>\
                      \
                      <span class=\"owner_info\">%@<span class=\"txt_bar\">|</span><span class=\"datetime\">%@</span><span class=\"txt_bar\">|</span><span class=\"category_info\">%@</span></span>\
                      \
                      </div><div class=\"post_header\"><div class=\"post_relative_action\"></div></div> \
                      \
                      %@</div></body></html>",
                      item[@"title"],
                      item[@"author"], item[@"datetime"], item[@"category"],
                      item[@"content"]];
    
    [[self webView] loadHTMLString:html baseURL:[[NSBundle mainBundle] resourceURL]];
}

-(void)handleBarButton:(UIBarButtonItem *)sender {
    if (sender.tag == 1) {
        [self webViewGoBack];
    }else if (sender.tag == 2) {
        [self webViewGoForward];
    }else if (sender.tag == 3) {
        // Refresh
        if (useMobileWeb) {
            [self.webView reload];
        }else{
            id obj = self.webHistory[self.webHistoryIndex];
            if ([obj isKindOfClass:[NSURL class]]) {
                [self.webView reload];
            }else{
                [self fetchArticle:obj completion:^(NSString *articleId, NSDictionary *item) {
                    [self updateWebViewWithItem:item];
                }];
            }
        }
    }else if (sender.tag == 4) {
        NSURL* url = nil;
        if (useMobileWeb) {
            url = self.lastLoadingURL;
        }else{
            id obj = self.webHistory[self.webHistoryIndex];
            if ([obj isKindOfClass:[NSURL class]]) {
                url = self.lastLoadingURL;
            }else{
                url = [Back2Mac getURL:self.articleId];
            }
        }
        if (url == nil) url = [Back2Mac getURL:self.articleId];
        
        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                                 applicationActivities:@[
                                                                                                         [[B2MActivity alloc] initWithType:@"addToBookmark"],
                                                                                                         [[B2MActivity alloc] initWithType:@"openInSafari"]]];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

-(BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if (!useMobileWeb && inType == UIWebViewNavigationTypeLinkClicked) {
        if ([inRequest.URL.host isEqualToString:@"macnews.tistory.com"]) {
            NSString* urlString = inRequest.URL.absoluteString;
            NSRegularExpression *regex = [NSRegularExpression
                                          regularExpressionWithPattern:@"(?:macnews.tistory.com\\/m\\/post\\/|macnews.tistory.com\\/)(\\d*)"
                                          options:NSRegularExpressionCaseInsensitive
                                          error:nil];
            NSTextCheckingResult* match = [regex firstMatchInString:urlString options:0 range:NSMakeRange(0, [urlString length])];
            if (match != nil) {
                
                NSString* articleId = [urlString substringWithRange:[match rangeAtIndex:1]];
                [Back2Mac articleId:articleId toRead:YES];
                [self fetchArticle:articleId completion:^(NSString *articleId, NSDictionary *item) {
                    [self addHistoryAndLoad:articleId withItem:item];
                }];
                
                return NO;
            }
        }
        
        if (askToSafari) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Back2Mac"
                                                                                     message:[NSString stringWithFormat:@"%@", inRequest.URL]
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:nil];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Safari로 이동"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [[UIApplication sharedApplication] openURL:[inRequest URL]];
                                                             }];
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }else{
            return YES;
        }
    }
    
    self.lastLoadingURL = inRequest.URL;
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    if (useMobileWeb) {
        [self updateBarButtonState];
    }
}

#pragma mark - full screen

-(void)handlePanGesture:(UIPanGestureRecognizer *) sender {
    CGPoint panned = [sender translationInView:self.view];
    
    if (panned.y < -80) {
        [self setFullscreen:YES];
    }else if (panned.y > 100) {
        [self setFullscreen:NO];
    }
}
-(void)handleGesture:(UITapGestureRecognizer *)sender {
    [self setFullscreen:!self.navigationController.navigationBar.isHidden];
}

-(void)setFullscreen:(BOOL)full {
    if (bottomBarLock) return;
    
    CGRect frame = self.bottomBar.frame;
    BOOL isFull = self.navigationController.navigationBar.isHidden;
    
    if (isFull == full) return;
    
    CGRect webViewFrame = self.webView.frame;
    bottomBarLock = TRUE;
    [UIView animateWithDuration:0.3f animations:^{
        CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
        [self.navigationController setNavigationBarHidden:full animated:NO];
        
        if (full) {
            self.webView.frame = CGRectMake(webViewFrame.origin.x, webViewFrame.origin.y-navBarHeight, webViewFrame.size.width, webViewFrame.size.height+navBarHeight+frame.size.height);
            self.bottomBar.frame = CGRectMake(frame.origin.x, bottomBarOriginY+frame.size.height, frame.size.width, frame.size.height);
        }else{
            self.webView.frame = CGRectMake(webViewFrame.origin.x, webViewFrame.origin.y+navBarHeight, webViewFrame.size.width, webViewOriginHeight);
            self.bottomBar.frame = CGRectMake(frame.origin.x, bottomBarOriginY, frame.size.width, frame.size.height);
        }
    } completion:^(BOOL finished) {
        bottomBarLock = FALSE;
    }];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y < 0) {
        CGRect frame = self.bottomBar.frame;
        if (frame.origin.y == bottomBarOriginY + frame.size.height) {
            [self setFullscreen:NO];
        }
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


@end
