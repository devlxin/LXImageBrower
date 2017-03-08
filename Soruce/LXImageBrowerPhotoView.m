//
//  LXImageBrowerPhotoView.m
//  ImagePicker
//
//  Created by 鑫 李 on 2017/1/16.
//  Copyright © 2017年 lxin. All rights reserved.
//

#import "LXImageBrowerPhotoView.h"
#import "LXImageBrowerPhotoItem.h"
#import <Image/UIImageView+WebImage.h>
#import <Image/LXImageView.h>

const CGFloat kLXImageBrowerPhotoViewPadding = 10;
const CGFloat kLXImageBrowerPhotoViewMaxScale = 3;

@interface LXImageBrowerPhotoView() <UIScrollViewDelegate>

@property (nonatomic, strong, readwrite) LXImageView *imageView;

@end

@implementation LXImageBrowerPhotoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.bouncesZoom = YES;
        self.maximumZoomScale = kLXImageBrowerPhotoViewMaxScale;
        self.multipleTouchEnabled = YES;
        self.showsHorizontalScrollIndicator = YES;
        self.showsVerticalScrollIndicator = YES;
        self.delegate = self;
        
        _imageView = [[LXImageView alloc] init];
        _imageView.backgroundColor = [UIColor darkGrayColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self addSubview:_imageView];
        [self resizeImageView];
    }
    return self;
}

- (void)setItem:(LXImageBrowerPhotoItem *)item {
    _item = item;
    [_imageView cancelCurrentImageRequest];
    if (item) {
        if (item.originalImage) {
            _imageView.image = item.originalImage;
            _item.finished = YES;
            [self resizeImageView];
            return;
        }
        __weak typeof(self) weakSelf = self;
        LXWebImageProgressBlock progress = ^(NSInteger receivedSize, NSInteger expectedSize) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
#warning 在此书写图片加载进度的代码
            
        };
        _imageView.image = item.thumbImage;
        
        [_imageView setImageWithURL:item.originalImageURL placeHolder:item.thumbImage options:kNilOptions progress:progress transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, LXWebImageFromType from, LXWebImageStage stage, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.item.finished = YES;
            if (stage == LXWebImageStageFinished) {
                [strongSelf resizeImageView];
                return;
            }
        }];
    } else {
        _imageView.image = nil;
    }
    [self resizeImageView];
}

- (void)resizeImageView {
    if (_imageView.image) {
        CGSize imageSize = _imageView.image.size;
        CGFloat width = _imageView.frame.size.width;
        CGFloat height = width * (imageSize.height / imageSize.width);
        CGRect rect = CGRectMake(0, 0, width, height);
        _imageView.frame = rect;
        
        if (height <= self.bounds.size.height)
            _imageView.center = CGPointMake(self.bounds.size.width / 2., self.bounds.size.height / 2.);
        else
            _imageView.center = CGPointMake(self.bounds.size.width / 2., height / 2.);
        
        if (width / height > 2) self.maximumZoomScale = self.bounds.size.height / height;
    } else {
        CGFloat width = self.frame.size.width - 2 * kLXImageBrowerPhotoViewPadding;
        _imageView.frame = CGRectMake(0, 0, width, width * 2 / 3.);
        _imageView.center = CGPointMake(self.bounds.size.width / 2., self.bounds.size.height / 2.);
    }
    self.contentSize = _imageView.frame.size;
}

- (void)cancelCurrentImageLoading {
    [_imageView cancelCurrentImageRequest];
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.;
    
    _imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}

@end
