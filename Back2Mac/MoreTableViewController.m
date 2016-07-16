//
//  MoreTableViewController.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "Back2Mac.h"
#import "MoreTableViewController.h"
#import "DetailOptionTableViewController.h"
#import "NotificationController.h"

@interface MoreTableViewController () <DetailOptionDelegate> {
    NSInteger defaultViewer;
}
@property (nonatomic, strong) IBOutlet UISwitch* switchNoti;
@property (nonatomic, strong) IBOutlet UISwitch* switchAskSafari;
@end

@implementation MoreTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}
- (void)viewWillAppear:(BOOL)animated {
    self.switchNoti.on = [[Back2Mac getUserDefaults:DEFAULT_RECEIVE_NOTI
                                             withDefault:[NSNumber numberWithBool:TRUE]] boolValue];
    self.switchAskSafari.on = [[Back2Mac getUserDefaults:DEFAULT_ASK_BEFORE_SAFARI
                                             withDefault:[NSNumber numberWithBool:TRUE]] boolValue];
    defaultViewer = [[Back2Mac getUserDefaults:DEFAULT_DEFAULT_VIEWER withDefault:@0] unsignedIntegerValue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 1 && indexPath.row == 0) {
        cell.detailTextLabel.text = @[@"기본 뷰어", @"모바일 웹뷰", @"Safari에서 열기"][defaultViewer];
    }
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2 && indexPath.row == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Back2Mac"
                                                                                 message:@"Safari로 이동합니다."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"이동"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [[UIApplication sharedApplication] openURL:
                                                              [NSURL URLWithString:@"http://macnews.tistory.com"]];
                                                         }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark -
-(IBAction)switchChanged:(UISwitch *)sender {
    if (sender.tag == 1) { // 알림 받기
        [Back2Mac updateDeviceToServerWithCompletionHandler:^(BOOL isSuccess) {
            if (isSuccess == FALSE) {
                sender.on = !sender.isOn;
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Back2Mac"
                                                                                         message:@"서버에 반영하지 못했습니다 ;("
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"확인"
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:nil];
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }else{
                [Back2Mac setUserDefaults:[NSNumber numberWithBool:sender.isOn] forKey:DEFAULT_RECEIVE_NOTI];
            }
        }];
    }else if (sender.tag == 2) { // Safari를 열기 전 묻기
        [Back2Mac setUserDefaults:[NSNumber numberWithBool:sender.isOn] forKey:DEFAULT_ASK_BEFORE_SAFARI];
    }
}


-(void)detailOption:(DetailOptionTableViewController *)vc selectedIndex:(NSInteger)selectedIndex {
    [Back2Mac setUserDefaults:[NSNumber numberWithInteger:selectedIndex] forKey:DEFAULT_DEFAULT_VIEWER];
    defaultViewer = selectedIndex;
    
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    cell.detailTextLabel.text = @[@"기본 뷰어", @"모바일 웹뷰", @"Safari에서 열기"][defaultViewer];
}

-(void)detailOption:(DetailOptionTableViewController *)vc selectedIndexes:(NSArray *)selectedIndexes {
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ViewerSegue"]) {
        DetailOptionTableViewController* vc = [segue destinationViewController];
        vc.delegate = self;
        vc.title = @"기본 뷰어";
        [vc setOptions:@[@"기본 뷰어", @"모바일 웹뷰", @"Safari에서 열기"]];
        [vc setSelectedIndex:defaultViewer];
    }else if ([[segue identifier] isEqualToString:@"categorySegue"]) {
        DetailOptionTableViewController* vc = [segue destinationViewController];
        vc.delegate = self;
        vc.title = @"카테고리 설정";
        vc.canMultipleSelection = TRUE;
    }
}

@end
