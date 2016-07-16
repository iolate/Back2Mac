//
//  DetailOptionTableViewController.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "DetailOptionTableViewController.h"

@interface DetailOptionTableViewController ()
@property (nonatomic, strong) NSMutableSet* mutableSelected;
@end

@implementation DetailOptionTableViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    _canMultipleSelection = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.canMultipleSelection) {
        _mutableSelected = (self.selectedIndexes != nil) ? [NSMutableSet setWithArray:self.selectedIndexes] : [NSMutableSet set];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    if (self.delegate != nil) {
        if (self.canMultipleSelection && [self.delegate respondsToSelector:@selector(detailOption:selectedIndexes:)]) {
            [self.delegate detailOption:self selectedIndexes:[self.mutableSelected allObjects]];
        }else if ([self.delegate respondsToSelector:@selector(detailOption:selectedIndex:)]) {
            [self.delegate detailOption:self selectedIndex:self.selectedIndex];
        }
    }
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.options[indexPath.row];
    if (self.canMultipleSelection) {
        cell.accessoryType = [self.mutableSelected containsObject:[NSNumber numberWithInteger:indexPath.row]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }else{
        cell.accessoryType = (indexPath.row == self.selectedIndex) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.canMultipleSelection) {
        NSNumber* nbIndex = [NSNumber numberWithInteger:indexPath.row];
        if ([self.mutableSelected containsObject:nbIndex]) {
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
            [self.mutableSelected removeObject:nbIndex];
        }else{
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
            [self.mutableSelected addObject:nbIndex];
        }
    }else{
        [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]].accessoryType = UITableViewCellAccessoryNone;
        
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedIndex = indexPath.row;
    }
}

@end
