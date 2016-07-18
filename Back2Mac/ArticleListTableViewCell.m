//
//  ArticleListTableViewCell.m
//  Back2Mac
//
//  Copyright © 2016 iolate. All rights reserved.
//

#import "ArticleListTableViewCell.h"

@interface ArticleListTableViewCell ()
    @property (nonatomic, strong) IBOutlet UIView* readMark;
@end

@implementation ArticleListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.readMark.layer.cornerRadius = 6.0f;
    self.readMark.layer.masksToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setMark:(ArticleCellMarkType)markType {
    if (markType == ArticleCellMarkRead) {
        self.readMark.backgroundColor = [UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1];
    }else if (markType == ArticleCellMarkBookmark) {
        self.readMark.backgroundColor = [UIColor colorWithRed:0.9 green:0.525882 blue:0 alpha:1];
    }else {
        self.readMark.backgroundColor = [UIColor clearColor];
    }
}

@end
