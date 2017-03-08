//
//  LXImageBrowerController.h
//  ImagePicker
//
//  Created by 鑫 李 on 2017/1/16.
//  Copyright © 2017年 lxin. All rights reserved.
//

/**
 *  思路：通过`坐标转换`将要展示的图片从所在内容视图的坐标转换到图片浏览器视图的坐标，并辅以动画。
 *  核心：`坐标转换`
 *  注意：1.需要配合<Image>、<Cache>框架使用
 *           2.使用`showFromViewController`弹出
 *           3.与具体业务逻辑是脱离的，不要与具体业务逻辑产生耦合
 */

#import <UIKit/UIKit.h>
#import "LXImageBrowerPhotoItem.h"

@class LXImageBrowerController;

@protocol LXImageBrowerDataSource <NSObject>

@required
/// number of source items
- (NSUInteger)numberOfSourceItemsInLXImageBrower:(LXImageBrowerController *)imageBrower;
/// source item at index
- (LXImageBrowerPhotoItem *)LXImageBrower:(LXImageBrowerController *)imageBrower sourceItemAtIndex:(NSUInteger)index;

@end

@interface LXImageBrowerController : UIViewController

@property (nonatomic, weak) id<LXImageBrowerDataSource> dataSource;

@property (nonatomic, assign) NSUInteger selectedIndex;

- (LXImageBrowerPhotoItem *)dequeueReusablePhotoItem;

/**
 务必调用此方法来弹出图片浏览器，否则会显示不正确。

 @param viewController  从该viewController弹出图片浏览器
 */
- (void)showFromViewController:(UIViewController *)viewController;

@end
