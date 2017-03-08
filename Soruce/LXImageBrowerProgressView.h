//
//  LXImageBrowerProgressView.h
//  ImagePicker
//
//  Created by 鑫 李 on 2017/1/18.
//  Copyright © 2017年 lxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXImageBrowerProgressView : UIView

- (void)startAnimation;
- (void)stopAnimation;

/// max progress : 1, min progress: 0
- (void)updateProgress:(CGFloat)progress;

@end
