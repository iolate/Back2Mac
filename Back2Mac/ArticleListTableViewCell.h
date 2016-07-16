//
//  ArticleListTableViewCell.h
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArticleListTableViewCell : UITableViewCell

@property (nonatomic) IBOutlet UIImageView* aImageView;
@property (nonatomic) IBOutlet UILabel* aTitle;
@property (nonatomic) IBOutlet UILabel* aCategory;
@property (nonatomic) IBOutlet UILabel* aTime;

-(void)isRead:(BOOL)read;
@end
