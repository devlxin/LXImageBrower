//
//  LXImageBrowerPhotoView.h
//  ImagePicker
//
//  Created by 鑫 李 on 2017/1/16.
//  Copyright © 2017年 lxin. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const CGFloat kLXImageBrowerPhotoViewPadding;

@class LXImageBrowerPhotoItem, LXImageView;

@interface LXImageBrowerPhotoView : UIScrollView

@property (nonatomic, strong, readonly) LXImageView *imageView;
@property (nonatomic, strong) LXImageBrowerPhotoItem *item;

- (void)resizeImageView;
- (void)cancelCurrentImageLoading;

@end
