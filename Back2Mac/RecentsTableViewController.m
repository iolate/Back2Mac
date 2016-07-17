//
//  RecentsTableViewController.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "Back2Mac.h"
#import "RecentsTableViewController.h"
#import "ArticleListTableViewCell.h"
#import "ArticleViewController.h"
#import "MBProgressHUD.h"
#import "JSONProxy.h"
#import "UIImageView+WebCache.h"

@interface RecentsTableViewController () {
    NSInteger defaultViewer;
    BOOL pullToRefreshEnabled;
}
@property (nonatomic) NSInteger lastFetchedPage;
@property (nonatomic, strong) NSArray* articleList;
@property (nonatomic, strong) NSArray* readList;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation RecentsTableViewController

-(void)errorAlertWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Back2Mac"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(BOOL)addArticleWithDupCheckAndOrder:(NSArray *)newList {
    if (self.articleList == nil || self.articleList.count == 0) {
        _articleList = newList;
        return TRUE;
    }else{
        NSMutableArray* orgIds = [NSMutableArray array];
        for (NSDictionary* article in self.articleList) {
            [orgIds addObject:article[@"id"]];
        }
        
        NSMutableArray* newArticleList = [NSMutableArray array];
        for (NSDictionary* article in newList) {
            if ([orgIds containsObject:article[@"id"]]) {
                continue;
            }else{
                [newArticleList addObject:article];
            }
        }
        
        if (newArticleList.count > 0) {
            [newArticleList addObjectsFromArray:self.articleList];
            
            [newArticleList sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                NSInteger obj1Id = [obj1[@"id"] integerValue];
                NSInteger obj2Id = [obj2[@"id"] integerValue];
                
                if (obj1Id < obj2Id) return NSOrderedDescending;
                else return NSOrderedAscending;
            }];
            
            self.articleList = [NSArray arrayWithArray:newArticleList];
            
            return TRUE;
        }else{
            return FALSE;
        }
    }
}

-(void)_fetchArticleListWithPage:(NSInteger)page completion:(void (^)(NSError* error))completionBlock {
    NSString* url = [NSString stringWithFormat:@"http://%@/list?page=%ld", API_HOST, page];
    NSDictionary* api_data = [NSDictionary dictionaryWithContentsOfJSONURLString:url];
    
    if (api_data != nil) {
        if ([api_data[@"result"] isEqual:@0]) {
            if (self.articleList == nil) {
                _articleList = [NSMutableArray array];
            }
            BOOL articleWasAdded = [self addArticleWithDupCheckAndOrder:api_data[@"posts"]];
            if (page > self.lastFetchedPage) self.lastFetchedPage = page;
            
            if (articleWasAdded) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [self.tableView reloadData];
                });
            }
            
            if (completionBlock != nil) completionBlock(nil);
            return;
        }else if (completionBlock != nil) {
            NSString* errorMsg = nil;
            if ([api_data.allKeys containsObject:@"error"]) {
                errorMsg = api_data[@"error"];
            }else {
                errorMsg = [NSString stringWithFormat:@"Error %@", api_data[@"result"]];
            }
            
            NSError* error = [NSError errorWithDomain:@"fetch" code:[api_data[@"result"] integerValue] userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
            completionBlock(error);
        }
    }else if (completionBlock != nil) {
        NSError* error = [NSError errorWithDomain:@"fetch" code:-99 userInfo:@{NSLocalizedDescriptionKey: @"데이터 불러오기 실패"}];
        completionBlock(error);
    }
}

-(void)fetchArticleListWithPage:(NSInteger)page {
    if (self.hud == nil) {
        _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:self.hud];
    }
    [self.hud showAnimated:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _fetchArticleListWithPage:page completion:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                if (self.hud != nil) [self.hud hideAnimated:YES];
                if (error != nil) [self errorAlertWithMessage:[error localizedDescription]];
            });
        }];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lastFetchedPage = 0;
    [self fetchArticleListWithPage:1];
}

-(void)viewWillAppear:(BOOL)animated {
    defaultViewer = [[Back2Mac getUserDefaults:DEFAULT_DEFAULT_VIEWER withDefault:@0] unsignedIntegerValue];
    self.readList = [Back2Mac readArticlesList];
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tabBarController.tabBar setHidden:NO];
}

- (void)didReceiveMemoryWarning {
    if (self.hud != nil) {
        [self.hud removeFromSuperview];
        _hud = nil;
    }
    
    [super didReceiveMemoryWarning];
}

#pragma mark -

-(IBAction)refreshTable:(id)sender {
    [self _fetchArticleListWithPage:1 completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self.refreshControl endRefreshing];
            if (error != nil) [self errorAlertWithMessage:[error localizedDescription]];
        });
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.articleList count] > 0 ? [self.articleList count]+1 : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.row == [self.articleList count]) ? 44.0f : 77.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.articleList.count) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CellLoadMore" forIndexPath:indexPath];
        
        return cell;
    }else{
        NSDictionary* post = self.articleList[indexPath.row];
        ArticleListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[post.allKeys containsObject:@"thumbnail"] ? @"Cell" : @"CellNoImage" forIndexPath:indexPath];
        if ([post.allKeys containsObject:@"thumbnail"]) {
            [cell.aImageView sd_setImageWithURL:[NSURL URLWithString:post[@"thumbnail"]] placeholderImage:nil];
        }
        
        cell.aTitle.text = post[@"title"];
        cell.aCategory.text = post[@"category"];
        cell.aTime.text = post[@"date"];
        
        [cell isRead:[self.readList containsObject:post[@"id"]]];
        
        return cell;
    }
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.articleList.count) {
        [self fetchArticleListWithPage:self.lastFetchedPage+1];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }else{
        if (defaultViewer == 2) {
            NSString* articleId = self.articleList[indexPath.row][@"id"];
            [Back2Mac articleId:articleId toRead:YES];
            [[UIApplication sharedApplication] openURL:[Back2Mac getURL:articleId]];
        }else{
            [self performSegueWithIdentifier:@"webViewSegue" sender:self];
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


#pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     ArticleViewController* vc = [segue destinationViewController];
     NSInteger row = [self.tableView indexPathForSelectedRow].row;
     [vc setArticleId:self.articleList[row][@"id"]];
 }


@end
