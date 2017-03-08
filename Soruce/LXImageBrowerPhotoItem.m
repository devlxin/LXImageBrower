//
//  LXImageBrowerItem.m
//  ImagePicker
//
//  Created by 鑫 李 on 2017/1/16.
//  Copyright © 2017年 lxin. All rights reserved.
//

#import "LXImageBrowerPhotoItem.h"

@interface LXImageBrowerPhotoItem()

@property (nonatomic, weak, readwrite) UIView *sourceView;
@property (nonatomic, strong, readwrite) UIImage *thumbImage;
@property (nonatomic, strong, readwrite) UIImage *originalImage;
@property (nonatomic, strong, readwrite) NSURL *originalImageURL;

@end

@implementation LXImageBrowerPhotoItem

- (void)updateItemWithSourceView:(UIView *)sourceView
                      thumbImage:(UIImage *)thumbImage
                   originalImage:(UIImage *)originalImage
                originalImageURL:(NSURL *)originalImageURL {
    _sourceView = sourceView;
    _thumbImage = thumbImage;
    _originalImage = originalImage;
    _originalImageURL = originalImageURL;
}

//- (instancetype)initWithSourceView:(UIView *)sourceView
//                        thumbImage:(UIImage *)thumbImage
//                  originalImageURL:(NSURL *)originalImageURL {
//    if (self = [super init]) {
//        _sourceView = sourceView;
//        _thumbImage = thumbImage;
//        _originalImageURL = originalImageURL;
//    }
//    return self;
//}
//
//- (instancetype)initWithSourceView:(UIView *)sourceView
//                        thumbImage:(UIImage *)thumbImage
//                     originalImage:(UIImage *)originalImage {
//    if (self = [super init]) {
//        _sourceView = sourceView;
//        _thumbImage = thumbImage;
//        _originalImage = originalImage;
//    }
//    return self;
//}
//
//- (instancetype)initWithSourceView:(UIImageView *)sourceView
//                  originalImageURL:(NSURL *)originalImageURL {
//    if (self = [super init]) {
//        _sourceView = sourceView;
//        _originalImageURL = originalImageURL;
//    }
//    return self;
//}
//
//- (instancetype)initWithSourceView:(UIImageView *)sourceView
//                     originalImage:(UIImage *)originalImage {
//    if (self = [super init]) {
//        _sourceView = sourceView;
//        _originalImage = originalImage;
//    }
//    return self;
//}
//
//+ (instancetype)itemWithSourceView:(UIView *)sourceView
//                        thumbImage:(UIImage *)thumbImage
//                  originalImageURL:(NSURL *)originalImageURL {
//    return [[LXImageBrowerPhotoItem alloc] initWithSourceView:sourceView
//                                              thumbImage:thumbImage
//                                        originalImageURL:originalImageURL];
//}
//
//+ (instancetype)itemWithSourceView:(UIView *)sourceView
//                        thumbImage:(UIImage *)thumbImage
//                     originalImage:(UIImage *)originalImage {
//    return [[LXImageBrowerPhotoItem alloc] initWithSourceView:sourceView
//                                                   thumbImage:thumbImage
//                                                originalImage:originalImage];
//}
//
//+ (instancetype)itemWithSourceView:(UIImageView *)sourceView
//                  originalImageURL:(NSURL *)originalImageURL {
//    return [[LXImageBrowerPhotoItem alloc] initWithSourceView:sourceView
//                                        originalImageURL:originalImageURL];
//}
//
//+ (instancetype)itemWithSourceView:(UIImageView *)sourceView
//                     originalImage:(UIImage *)originalImage {
//    return [[LXImageBrowerPhotoItem alloc] initWithSourceView:sourceView
//                                           originalImage:originalImage];
//}

@end
