//
//  LXImageBrowerItem.h
//  ImagePicker
//
//  Created by 鑫 李 on 2017/1/16.
//  Copyright © 2017年 lxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXImageBrowerPhotoItem : NSObject

/// 源视图
@property (nonatomic, weak, readonly) UIView *sourceView;
/// 小图
@property (nonatomic, strong, readonly) UIImage *thumbImage;
/// 大图（大图或大图URL两者选一）
@property (nonatomic, strong, readonly) UIImage *originalImage;
/// 大图URL（大图或大图URL两者选一）
@property (nonatomic, strong, readonly) NSURL *originalImageURL;
/// 图片是否加载完成的标识符
@property (nonatomic, assign, getter=isFinished) BOOL finished;

///// 适用于：源视图不是UIImageView，网络请求大图
//- (instancetype)initWithSourceView:(UIView *)sourceView
//                        thumbImage:(UIImage *)thumbImage
//                  originalImageURL:(NSURL *)originalImageURL;
//
//+ (instancetype)itemWithSourceView:(UIView *)sourceView
//                        thumbImage:(UIImage *)thumbImage
//                  originalImageURL:(NSURL *)originalImageURL;
//
///// 适用于：源视图不是UIImageView，本地请求大图
//- (instancetype)initWithSourceView:(UIView *)sourceView
//                        thumbImage:(UIImage *)thumbImage
//                     originalImage:(UIImage *)originalImage;
//
//+ (instancetype)itemWithSourceView:(UIView *)sourceView
//                        thumbImage:(UIImage *)thumbImage
//                     originalImage:(UIImage *)originalImage;
//
///// 适用于：源视图是UIImageView，网络请求大图
//- (instancetype)initWithSourceView:(UIImageView *)sourceView
//                  originalImageURL:(NSURL *)originalImageURL;
//
//+ (instancetype)itemWithSourceView:(UIImageView *)sourceView
//                  originalImageURL:(NSURL *)originalImageURL;
//
///// 适用于：源视图是UIImageView，本地请求大图
//- (instancetype)initWithSourceView:(UIImageView *)sourceView
//                     originalImage:(UIImage *)originalImage;
//
//+ (instancetype)itemWithSourceView:(UIImageView *)sourceView
//                     originalImage:(UIImage *)originalImage;


/**
 更新Item赋值

 @param sourceView  源视图
 @param thumbImage   源图片
 @param originalImage  大图
 @param originalImageURL  大图URL
 */
- (void)updateItemWithSourceView:(UIView *)sourceView
                      thumbImage:(UIImage *)thumbImage
                   originalImage:(UIImage *)originalImage
                originalImageURL:(NSURL *)originalImageURL;

@end
