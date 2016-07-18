//
//  ArticleListTableViewCell.h
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"

typedef NS_ENUM(NSInteger, ArticleCellMarkType) {
    ArticleCellMarkNone,
    ArticleCellMarkRead,
    ArticleCellMarkBookmark
};

@interface ArticleListTableViewCell : MGSwipeTableCell

@property (nonatomic) IBOutlet UIImageView* aImageView;
@property (nonatomic) IBOutlet UILabel* aTitle;
@property (nonatomic) IBOutlet UILabel* aCategory;
@property (nonatomic) IBOutlet UILabel* aTime;

-(void)setMark:(ArticleCellMarkType)markType;
@end
