//
//  IMBToolBarView.m
//  iOSFiles
//
//  Created by iMobie on 18/2/10.
//  Copyright © 2018年 iMobie. All rights reserved.
//

#import "IMBToolBarView.h"
#import "IMBInformation.h"
#import "IMBiPod.h"
#import "IMBBaseViewController.h"
static const NSString *IMBToolBarViewIdxName = @"idx";
static const NSString *IMBToolBarViewImgNameName = @"imgName";
static const NSString *IMBToolBarViewTipName = @"tipName";

@interface IMBToolBarView()
{
    NSMutableArray<NSDictionary *> *_imgArray;
    NSMutableArray<NSDictionary *> *_tipArray;
    
    NSArray *_hiddenIndexes;
}

@end

@implementation IMBToolBarView

@synthesize information = _information;
@synthesize delegate = _delegate;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setupArray];
    }
    return self;
}
- (void)awakeFromNib {
    [self setupArray];
}

- (void)setupArray {
    if (_imgArray) {
        [_imgArray removeAllObjects];
        [_imgArray release];
        _imgArray = nil;
    }
    if (_tipArray) {
        [_tipArray removeAllObjects];
        [_tipArray release];
        _tipArray = nil;
    }
    _imgArray = [[NSMutableArray alloc]  init];
    _tipArray = [[NSMutableArray alloc]  init];
    
    [_imgArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumRefresh),IMBToolBarViewImgNameName : @"tool_refresh_normal"}];
    [_imgArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumToMac),IMBToolBarViewImgNameName : @"tool_tomac_normal"}];
    [_imgArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumAddToDevice),IMBToolBarViewImgNameName : @"tool_add_normal"}];
    [_imgArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumDelete),IMBToolBarViewImgNameName : @"tool_delete_normal"}];
    [_imgArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumToDevice),IMBToolBarViewImgNameName : @"tool_todevice_normal"}];
    
    [_tipArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumRefresh),IMBToolBarViewTipName : @"Refresh"}];
    [_tipArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumToMac),IMBToolBarViewTipName : @"Send To Mac"}];
    [_tipArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumAddToDevice),IMBToolBarViewTipName : @"Add To Device"}];
    [_tipArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumDelete),IMBToolBarViewTipName : @"Delete Items"}];
    [_tipArray addObject:@{IMBToolBarViewIdxName : @(IMBToolBarViewEnumToDevice),IMBToolBarViewTipName : @"Send To Device"}];
    
    
    NSInteger subCount = self.subviews.count;
    for (NSInteger i = 0; i < subCount; i++) {
        NSView *view = [self.subviews objectAtIndex:0];
        [view removeFromSuperview];
    }
    for (id idx in _hiddenIndexes) {
        for (NSDictionary *dic in _imgArray) {
            if ([[dic objectForKey:IMBToolBarViewIdxName] isEqual:idx]) {
                [_imgArray removeObject:dic];
                break;
            }
        }
        for (NSDictionary *dic in _tipArray) {
            if ([[dic objectForKey:IMBToolBarViewIdxName] isEqual:idx]) {
                [_tipArray removeObject:dic];
                break;
            }
        }
    }
    
    NSInteger count = _imgArray.count;
    CGFloat btnX = 0;
    CGFloat btnY = 0;
    CGFloat btnW = 36.0f;
    CGFloat btnH = self.frame.size.height;
    
    for (NSInteger i = 0; i < count; i++) {
        btnX = i*btnW;
        NSButton *btn = [[NSButton alloc] init];
        [btn setButtonType:NSMomentaryPushInButton];
        [btn setBordered:NO];
        btn.frame = NSMakeRect(btnX, btnY, btnW, btnH);
        
        NSDictionary *imgDic = [_imgArray objectAtIndex:i];
        NSDictionary *tipDic = [_tipArray objectAtIndex:i];
        
        [btn setTag:[imgDic[IMBToolBarViewIdxName] integerValue]];
        [btn setImage:[NSImage imageNamed:[imgDic objectForKey:IMBToolBarViewImgNameName]]];
        [btn setToolTip:[tipDic objectForKey:IMBToolBarViewTipName]];
        [btn setTarget:self];
        [btn setAction:@selector(btnClicked:)];
        [self addSubview:btn];
    }
    
}

- (void)setHiddenIndexes:(NSArray *)indexes {
    _hiddenIndexes = indexes;
    if (!_hiddenIndexes) return;
    
    [self setupArray];
    
    
}

- (void)btnClicked:(NSButton *)sender {
    IMBInformation *information = [_information retain];
    switch (sender.tag) {
        case IMBToolBarViewEnumRefresh:
        {
            [_delegate refresh];
            [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageRefreshClickedNoti object:information];
        }
            break;
        case IMBToolBarViewEnumToMac:
        {
            [_delegate toMac];
            [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageToMacClickedNoti object:information];
        }
            break;
        case IMBToolBarViewEnumAddToDevice:
        {
            [_delegate addItems];
            [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageAddToDeviceClickedNoti object:information];
        }
            break;
        case IMBToolBarViewEnumDelete:
        {
            [_delegate deleteItem];
            [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageDeleteClickedNoti object:information];
        }
            break;
        case IMBToolBarViewEnumToDevice:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageToDeviceClickedNoti object:information];
        }
            break;
            
        default:
            break;
    }
    
    [information release];
    information = nil;
}



- (void)dealloc {
    
    if (_imgArray) {
        [_imgArray removeAllObjects];
        [_imgArray release];
        _imgArray = nil;
    }
    if (_tipArray) {
        [_tipArray removeAllObjects];
        [_tipArray release];
        _tipArray = nil;
    }
//    if (_hiddenIndexes) {
//        [_hiddenIndexes release];
//        _hiddenIndexes = nil;
//    }
    if (_information) {
        [_information release];
        _information = nil;
    }
    [super dealloc];
}

- (void)enableBtns:(BOOL)isEnable {
    if (self.subviews.count) {
        for (id btn in self.subviews) {
            if ([btn isKindOfClass:[NSButton class]]) {
                [(NSButton *)btn setEnabled:isEnable];
            }
        }
    }
}
@end
