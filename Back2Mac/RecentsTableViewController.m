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
}
@property (nonatomic, strong) NSMutableArray* articleList;
@property (nonatomic, strong) NSArray* readList;
@property (nonatomic, strong) MBProgressHUD *hud;
@end

@implementation RecentsTableViewController

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

-(void)_fetchArticleListWithPage:(NSInteger)page {
    NSString* url = [NSString stringWithFormat:@"http://%@/list", API_HOST];
    NSDictionary* api_data = [NSDictionary dictionaryWithContentsOfJSONURLString:url];
    
    if (api_data != nil) {
        if ([api_data[@"result"] isEqual:@0]) {
            if (self.articleList == nil) {
                _articleList = [NSMutableArray array];
            }
            
            [self.articleList addObjectsFromArray:api_data[@"posts"]];
            
            dispatch_async(dispatch_get_main_queue(), ^() {
                [self.tableView reloadData];
                [self.hud hideAnimated:YES];
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

-(void)fetchArticleListWithPage:(NSInteger)page {
    if (self.hud == nil) {
        _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:self.hud];
    }
    [self.hud showAnimated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _fetchArticleListWithPage:1];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.articleList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (defaultViewer == 2) {
        NSString* articleId = self.articleList[indexPath.row][@"id"];
        [Back2Mac articleId:articleId toRead:YES];
        [[UIApplication sharedApplication] openURL:[Back2Mac getURL:articleId]];
    }else{
        [self performSegueWithIdentifier:@"webViewSegue" sender:self];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     ArticleViewController* vc = [segue destinationViewController];
     NSInteger row = [self.tableView indexPathForSelectedRow].row;
     [vc setArticleId:self.articleList[row][@"id"]];
 }


@end
