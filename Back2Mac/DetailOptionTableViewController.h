//
//  DetailOptionTableViewController.h
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailOptionTableViewController;

@protocol DetailOptionDelegate <NSObject>
@optional
-(void)detailOption:(DetailOptionTableViewController *)vc selectedIndex:(NSInteger)selectedIndex;
-(void)detailOption:(DetailOptionTableViewController *)vc selectedIndexes:(NSArray *)selectedIndexes;
@end

@interface DetailOptionTableViewController : UITableViewController
@property (nonatomic, weak) id <DetailOptionDelegate> delegate;
@property (nonatomic) BOOL canMultipleSelection;
@property (nonatomic, strong) NSArray* options;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic, strong) NSArray* selectedIndexes;
@end
