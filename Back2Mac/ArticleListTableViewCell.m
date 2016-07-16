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

-(void)isRead:(BOOL)read {
    self.readMark.hidden = read;
}
@end
