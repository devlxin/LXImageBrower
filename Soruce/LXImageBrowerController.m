//
//  LXImageBrowerController.m
//  ImagePicker
//
//  Created by 鑫 李 on 2017/1/16.
//  Copyright © 2017年 lxin. All rights reserved.
//

#import "LXImageBrowerController.h"
#import "LXImageBrowerPhotoView.h"
#import <Image/LXWebImageManager.h>
#import <Image/LXImageView.h>
#import <Cache/Cache.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef struct {
    unsigned int isExistsNumberOfSourceItems : 1;
    unsigned int isExistsSourceItemAtIndex : 1;
} LXImageBrowerDataSourceFlags;

static const NSTimeInterval kLXImageBrowerAnimationDuration = 0.2;
static const NSTimeInterval kLXImageBrowerSpringAnimationDuration = 0.2;

@interface LXImageBrowerController () <UIScrollViewDelegate, UIActionSheetDelegate> {
    NSUInteger _sourceItemsCount;
    
    LXImageBrowerDataSourceFlags _dataSourceFlags;
    
    CGPoint _startLocation;
    
    LXImageBrowerPhotoItem *_item;
    
    UIImage *_savedImage;
}

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *backgroundView;

/// reusable
@property (nonatomic, strong) NSMutableSet *reusableItemViews;
@property (nonatomic, strong) NSMutableArray *visibleItemViews;

@property (nonatomic, strong) NSMutableSet *reusableItems;
@property (nonatomic, strong) NSMutableArray *visibleItems;

/// pageLabel
@property (nonatomic, strong) UIView *pageBgView;
@property (nonatomic, strong) UILabel *selectedPageLabel;
@property (nonatomic, strong) UILabel *totalPageLabel;

@property (nonatomic, assign) BOOL presented;

@end

@implementation LXImageBrowerController

- (instancetype)init {
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        _reusableItemViews = [NSMutableSet new];
        _visibleItemViews = [NSMutableArray new];
        
        _reusableItems = [NSMutableSet new];
        _visibleItems = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfSourceItemsInLXImageBrower:)])
        _dataSourceFlags.isExistsNumberOfSourceItems = 1;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(LXImageBrower:sourceItemAtIndex:)])
        _dataSourceFlags.isExistsSourceItemAtIndex = 1;
    
    [self setup];
}

- (void)setup {
    self.view.backgroundColor = [UIColor clearColor];
    
    if (_dataSourceFlags.isExistsNumberOfSourceItems)
        _sourceItemsCount = [self.dataSource numberOfSourceItemsInLXImageBrower:self];
    
    _backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    _backgroundView.alpha = 0;
    [self.view addSubview:_backgroundView];
    
    CGRect rect = self.view.bounds;
    rect.origin.x -= kLXImageBrowerPhotoViewPadding;
    rect.size.width += 2 * kLXImageBrowerPhotoViewPadding;
    _scrollView = [[UIScrollView alloc] initWithFrame:rect];
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    [self.view addSubview:_scrollView];
    
    _pageBgView = [[UIView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - 200) / 2., 20, 200, 30)];
    _pageBgView.backgroundColor = [UIColor clearColor];
    
    _selectedPageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 95, 28)];
    _selectedPageLabel.textColor = [UIColor whiteColor];
    _selectedPageLabel.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightLight];
    _selectedPageLabel.textAlignment = NSTextAlignmentRight;
    [_pageBgView addSubview:_selectedPageLabel];
    
     UILabel *slashLabel = [[UILabel alloc] initWithFrame:CGRectMake(97, 9, 6, 16)];
    slashLabel.textColor = [UIColor whiteColor];
    slashLabel.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightLight];
    slashLabel.textAlignment = NSTextAlignmentCenter;
    slashLabel.text = @"/";
    [_pageBgView addSubview:slashLabel];
    
    _totalPageLabel = [[UILabel alloc] initWithFrame:CGRectMake(105, 11, 95, 14)];
    _totalPageLabel.textColor = [UIColor whiteColor];
    _totalPageLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightLight];
    _totalPageLabel.textAlignment = NSTextAlignmentLeft;
    _totalPageLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)_sourceItemsCount];
    [_pageBgView addSubview:_totalPageLabel];

    [self _configPageLabelWithPage:_selectedIndex];
    
    _pageBgView.hidden = YES;
    [self.view addSubview:_pageBgView];
    
    CGSize contentSize = CGSizeMake(rect.size.width * _sourceItemsCount, rect.size.height);
    _scrollView.contentSize = contentSize;
    
    [self _addGestureRecognizer];
    
    CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width * _selectedIndex, 0);
    [_scrollView setContentOffset:contentOffset animated:NO];
    if (contentOffset.x == 0) [self scrollViewDidScroll:_scrollView];
}

#pragma mark - Public Method
- (void)showFromViewController:(UIViewController *)viewController {
    [viewController presentViewController:self animated:NO completion:nil];
}

- (LXImageBrowerPhotoItem *)dequeueReusablePhotoItem {
    LXImageBrowerPhotoItem *item = [_reusableItems anyObject];
    if (item) [_reusableItems removeObject:item];
    else item = [[LXImageBrowerPhotoItem alloc] init];
    
    return item;
}

#pragma mark - Private Method
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (LXImageBrowerPhotoView *)_photoViewForPage:(NSUInteger)page {
    for (LXImageBrowerPhotoView *photoView in _visibleItemViews) {
        if (photoView.tag == page) return photoView;
    }
    return nil;
}

- (LXImageBrowerPhotoView *)_dequeueReusableItemView {
    LXImageBrowerPhotoView *photoView = [_reusableItemViews anyObject];
    if (photoView == nil) photoView = [[LXImageBrowerPhotoView alloc] initWithFrame:_scrollView.bounds];
    else [_reusableItemViews removeObject:photoView];
    photoView.tag = -1;
    return photoView;
}

- (void)_updateReusableItemViews {
    NSMutableArray *itemsViewForRemove = @[].mutableCopy;
    NSMutableArray *itemsForRemove = @[].mutableCopy;
    for (LXImageBrowerPhotoView *photoView in _visibleItemViews) {
        if (photoView.frame.origin.x + photoView.frame.size.width < _scrollView.contentOffset.x - _scrollView.frame.size.width || photoView.frame.origin.x > _scrollView.contentOffset.x + 2 * _scrollView.frame.size.width) {
            [photoView removeFromSuperview];
            [itemsForRemove addObject:photoView.item];
            [_reusableItems addObject:photoView.item];
            [self _configPhotoView:photoView withItem:nil];
            [itemsViewForRemove addObject:photoView];
            [_reusableItemViews addObject:photoView];
        }
    }
    [_visibleItemViews removeObjectsInArray:itemsViewForRemove];
    [_visibleItems removeObjectsInArray:itemsForRemove];
}

- (void)_configItemViews {
    NSInteger page = _scrollView.contentOffset.x / _scrollView.frame.size.width + 0.5;
    for (NSInteger i = page - 1; i <= page + 1; i++) {
        if (i < 0 || i >= _sourceItemsCount) continue;
        LXImageBrowerPhotoView *photoView = [self _photoViewForPage:i];
        if (photoView == nil) {
            photoView = [self _dequeueReusableItemView];
            CGRect rect = _scrollView.bounds;
            rect.origin.x = i * _scrollView.bounds.size.width;
            photoView.frame = rect;
            photoView.tag = i;
            [_scrollView addSubview:photoView];
            [_visibleItemViews addObject:photoView];
        }
        if (photoView.item == nil && _presented) {
            if (_dataSourceFlags.isExistsSourceItemAtIndex)
                _item = [self.dataSource LXImageBrower:self sourceItemAtIndex:i];
            [self _configPhotoView:photoView withItem:_item];
        }
    }
    
    if (page != _selectedIndex && _presented) {
        _selectedIndex = page;
        [self _configPageLabelWithPage:_selectedIndex];
    }
}

- (void)_addGestureRecognizer {
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_onDidDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_onDidSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:singleTap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_onDidLongPress:)];
    [self.view addGestureRecognizer:longPress];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_onDidPan:)];
    [self.view addGestureRecognizer:pan];
}

- (void)_configPageLabelWithPage:(NSUInteger)page {
    _selectedPageLabel.text = [NSString stringWithFormat:@"%ld", page + 1];
}

- (void)_configPhotoView:(LXImageBrowerPhotoView *)photoView withItem:(LXImageBrowerPhotoItem *)item {
    [photoView setItem:item];
}

#pragma mark - Animation
- (void)_showDismissalAnimation {

    LXImageBrowerPhotoView *photoView = [self _photoViewForPage:_selectedIndex];
    [photoView cancelCurrentImageLoading];
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    if (_dataSourceFlags.isExistsSourceItemAtIndex)
        _item = [self.dataSource LXImageBrower:self sourceItemAtIndex:_selectedIndex];
    
    _item.sourceView.alpha = 0;
    
    _pageBgView.hidden = YES;
    
    CGFloat sourceYAtScreen;
    CGFloat sourceXAtScreen;
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 8.0 && systemVersion < 9.0) {
        sourceYAtScreen = [_item.sourceView.superview convertRect:_item.sourceView.frame toCoordinateSpace:[UIApplication sharedApplication].keyWindow].origin.y;
        sourceXAtScreen = [_item.sourceView.superview convertRect:_item.sourceView.frame toCoordinateSpace:[UIApplication sharedApplication].keyWindow].origin.x;
    } else {
        sourceYAtScreen = [_item.sourceView.superview convertRect:_item.sourceView.frame toView:[UIApplication sharedApplication].keyWindow].origin.y;
        sourceXAtScreen = [_item.sourceView.superview convertRect:_item.sourceView.frame toCoordinateSpace:[UIApplication sharedApplication].keyWindow].origin.x;
    }
    
    if (_item.sourceView && sourceYAtScreen + _item.sourceView.frame.size.height / 2. < [UIScreen mainScreen].bounds.size.height && sourceXAtScreen + _item.sourceView.frame.size.width / 2. < [UIScreen mainScreen].bounds.size.width) {
        CGRect sourceRect;
        float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (systemVersion >= 8.0 && systemVersion < 9.0)
            sourceRect = [_item.sourceView.superview convertRect:_item.sourceView.frame toCoordinateSpace:photoView];
        else
            sourceRect = [_item.sourceView.superview convertRect:_item.sourceView.frame toView:photoView];
        
        [UIView animateWithDuration:kLXImageBrowerSpringAnimationDuration animations:^{
            photoView.imageView.frame = sourceRect;
            self.view.backgroundColor = [UIColor clearColor];
            _backgroundView.alpha = 0;
        } completion:^(BOOL finished) {
            [self _dismissAnimated:NO];
        }];
    } else {
        [UIView animateWithDuration:kLXImageBrowerSpringAnimationDuration animations:^{
            self.view.backgroundColor = [UIColor clearColor];
            _backgroundView.alpha = 0;
            photoView.alpha = 0;
        } completion:^(BOOL finished) {
            [self _dismissAnimated:NO];
        }];
    }
}

- (void)_dismissAnimated:(BOOL)animated {
    for (LXImageBrowerPhotoView *photoView in _visibleItemViews) {
        [photoView cancelCurrentImageLoading];
    }

    if (animated) {
        [UIView animateWithDuration:kLXImageBrowerSpringAnimationDuration animations:^{
            _item.sourceView.alpha = 1;
        }];
    } else {
        _item.sourceView.alpha = 1;
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Gesture Actions
- (void)_onDidDoubleTap:(UITapGestureRecognizer *)sender {
    LXImageBrowerPhotoView *photoView = [self _photoViewForPage:_selectedIndex];

    if (!_item.finished) return;
    if (photoView.zoomScale > 1) [photoView setZoomScale:1 animated:YES];
    else {
        CGPoint location = [sender locationInView:sender.view];
        CGFloat maxZoomScale = photoView.maximumZoomScale;
        CGFloat width = self.view.bounds.size.width / maxZoomScale;
        CGFloat height = self.view.bounds.size.height / maxZoomScale;
        [photoView zoomToRect:CGRectMake(location.x - width / 2., location.y - height / 2., width, height) animated:YES];
    }
}

- (void)_onDidSingleTap:(UITapGestureRecognizer *)sender {
    [self _showDismissalAnimation];
}

- (void)_onDidLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    
    LXImageBrowerPhotoView *photoView = [self _photoViewForPage:_selectedIndex];
    _savedImage = photoView.imageView.image;
    if (!_savedImage) return;
    
    [self _saveImage];
}

- (void)_onDidPan:(UIPanGestureRecognizer *)sender {
    LXImageBrowerPhotoView *photoView = [self _photoViewForPage:_selectedIndex];
    if (photoView.zoomScale > 1.1) return;
    
    [self _performSlideWithPan:sender];
}

- (void)_performSlideWithPan:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender translationInView:self.view];
    CGPoint location = [sender locationInView:self.view];
    CGPoint velocity = [sender velocityInView:self.view];
    LXImageBrowerPhotoView *photoView = [self _photoViewForPage:_selectedIndex];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            _startLocation = location;
            [self _handlePanBegin];
        } break;
        case UIGestureRecognizerStateChanged: {
            photoView.imageView.transform = CGAffineTransformMakeTranslation(0, point.y);
            double percent = 1 - fabs(point.y) / (self.view.frame.size.height / 2.);
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:percent];
            _backgroundView.alpha = percent;
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (fabs(point.y) > 200 || fabs(velocity.y) > 500)
                [self _showSlideCompletionAnimationFromPoint:point];
            else
                [self _showCancellationAnimation];
        } break;
        default:
            break;
    }
}

- (void)_showCancellationAnimation {
    LXImageBrowerPhotoView *photoView = [self _photoViewForPage:_selectedIndex];

    _item.sourceView.alpha = 1;

    [UIView animateWithDuration:kLXImageBrowerAnimationDuration animations:^{
        photoView.imageView.transform = CGAffineTransformIdentity;
        self.view.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = 1;
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self _configPhotoView:photoView withItem:_item];
        _pageBgView.hidden = NO;
    }];
}

- (void)_showSlideCompletionAnimationFromPoint:(CGPoint)point {
    LXImageBrowerPhotoView *photoView = [self _photoViewForPage:_selectedIndex];
    BOOL throwToTop = point.y < 0;
    CGFloat toTranslationY = 0;
    if (throwToTop)
        toTranslationY = -self.view.frame.size.height;
    else
        toTranslationY = self.view.frame.size.height;
    [UIView animateWithDuration:kLXImageBrowerAnimationDuration animations:^{
        photoView.imageView.transform = CGAffineTransformMakeTranslation(0, toTranslationY);
        self.view.backgroundColor = [UIColor clearColor];
        _backgroundView.alpha = 0;
    } completion:^(BOOL finished) {
        [self _dismissAnimated:YES];
    }];
}

- (void)_handlePanBegin {
    LXImageBrowerPhotoView *photoView = [self _photoViewForPage:_selectedIndex];
    [photoView cancelCurrentImageLoading];
    
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    if (_dataSourceFlags.isExistsSourceItemAtIndex)
        _item = [self.dataSource LXImageBrower:self sourceItemAtIndex:_selectedIndex];
    
    _item.sourceView.alpha = 0;
    _pageBgView.hidden = YES;
}

#pragma mark - UIAlertController
- (void)_saveImage {
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        NSArray *titles = @[@"保存图片"];
        [self addActionTarget:alert titles:titles];
        [self addCancelActionTarget:alert title:@"取消"];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"取消"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"保存图片", nil];
        actionSheet.tag = 10000;
        [actionSheet showInView:self.view];
    }
}

// 添加其他按钮
- (void)addActionTarget:(UIAlertController *)alertController titles:(NSArray *)titles {
    for (NSString *title in titles) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            // 保存到相册
            ALAssetsLibrary *assetsLibrary=[[ALAssetsLibrary alloc] init];
            
            [assetsLibrary writeImageToSavedPhotosAlbum:[_savedImage CGImage] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error) {
                    NSLog(@"ERROR: the image failed to be written");
                } else {
                    NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
                    [AlertTool showSuccessHUD:@"已保存到相册"];
                }
            }];
        }];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_2) {
            [action setValue:COLOR_WITH_RGB(251, 126, 126, 1) forKey:@"_titleTextColor"];
        }
        [alertController addAction:action];
    }
}

// 取消按钮
- (void)addCancelActionTarget:(UIAlertController *)alertController title:(NSString *)title {
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleCancel handler:nil];
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_2) {
        [action setValue:COLOR_WITH_RGB(183, 183, 183, 1) forKey:@"_titleTextColor"];
    }
    [alertController addAction:action];
}

#pragma mark actionSheet
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    if (actionSheet.tag == 10000) {
        for (UIView *subViwe in actionSheet.subviews) {
            if ([subViwe isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)subViwe;
                label.font = [UIFont systemFontOfSize:15];
                label.frame = CGRectMake(CGRectGetMinX(label.frame), CGRectGetMinY(label.frame), CGRectGetWidth(label.frame), CGRectGetHeight(label.frame)+20);
            }
            if ([subViwe isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton*)subViwe;
                if ([button.titleLabel.text isEqualToString:@"取消"]) {
                    [button setTitleColor:COLOR_WITH_RGB(149, 149, 149, 1) forState:UIControlStateNormal];
                } else {
                    [button setTitleColor:COLOR_WITH_RGB(31, 178, 233, 1) forState:UIControlStateNormal];
                }
                button.titleLabel.font = [UIFont systemFontOfSize:18];
            }
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 10000) {
        if (buttonIndex == 0) {
            // 保存到相册
            ALAssetsLibrary *assetsLibrary=[[ALAssetsLibrary alloc] init];
            
            [assetsLibrary writeImageToSavedPhotosAlbum:[_savedImage CGImage] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error) {
                    NSLog(@"ERROR: the image failed to be written");
                } else {
                    NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
                    [AlertTool showSuccessHUD:@"已保存到相册"];
                }
            }];
        }
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self _updateReusableItemViews];
    [self _configItemViews];
}

#pragma mark - life cycle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_dataSourceFlags.isExistsSourceItemAtIndex)
        _item = [self.dataSource LXImageBrower:self sourceItemAtIndex:_selectedIndex];
    
    LXImageBrowerPhotoView *photoView = [self _photoViewForPage:_selectedIndex];
    LXWebImageManager *manager = [LXWebImageManager sharedManager];
    NSString *key = [manager cacheKeyForURL:_item.originalImageURL];
    if ([manager.cache cacheForKey:key]) [self _configPhotoView:photoView withItem:_item];
    else {
        photoView.imageView.image = _item.thumbImage;
        [photoView resizeImageView];
    }
    
    if (_item.sourceView) {
        CGRect endRect = photoView.imageView.frame;
        CGRect sourceRect;
        float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (systemVersion >= 8.0 && systemVersion < 9.0)
            sourceRect = [_item.sourceView.superview convertRect:_item.sourceView.frame toCoordinateSpace:photoView];
        else
            sourceRect = [_item.sourceView.superview convertRect:_item.sourceView.frame toView:photoView];
        photoView.imageView.frame = sourceRect;
        
        [UIView animateWithDuration:kLXImageBrowerAnimationDuration animations:^{
            photoView.imageView.frame = endRect;
            self.view.backgroundColor = [UIColor blackColor];
            _backgroundView.alpha = 1;
        } completion:^(BOOL finished) {
            [self _configPhotoView:photoView withItem:_item];
            _presented = YES;
            _pageBgView.hidden = NO;
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }];
    } else {
        photoView.alpha = 0;
        [UIView animateWithDuration:kLXImageBrowerAnimationDuration animations:^{
            self.view.backgroundColor = [UIColor blackColor];
            _backgroundView.alpha = 1;
            photoView.alpha = 1;
        } completion:^(BOOL finished) {
            [self _configPhotoView:photoView withItem:_item];
            _presented = YES;
            _pageBgView.hidden = NO;
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
