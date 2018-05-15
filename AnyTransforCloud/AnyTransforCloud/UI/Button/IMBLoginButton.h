//
//  IMBGridientButton.h
//  FontTest
//
//  Created by m on 17/3/7.
//  Copyright (c) 2017年 iMobie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMBCommonEnum.h"
@protocol MouseEnumDelegate <NSObject>
- (void)mouseDownTag:(int)tag;
- (void)mouseEnterTag:(int)tag;
- (void)mouseUpTag:(int)tag;
- (void)mouseExitedTag:(int)tag;
@end
@interface IMBLoginButton : NSButton
{
    NSTrackingArea *_trackingArea;
    BOOL _isleftRightGridient;
    float _cornerRadius;
    float _borderLineWidth; //边框线宽
    
    NSColor *_leftNormalBgColor;
    NSColor *_rightNormalBgColor;
    NSColor *_leftEnterBgColor;
    NSColor *_rightEnterBgColor;
    NSColor *_leftDownBgColor;
    NSColor *_rightDownBgColor;
    NSColor *_leftForbiddenBgColor;
    NSColor *_rightForbiddenBgColor;
    
    BOOL _hasBorder;//是否有边框
    NSColor *_normalBorderColor;//默认边框颜色
    NSColor *_enterBorderColor;//经过边框颜色
    NSColor *_downBorderColor;//点击边框颜色
    NSColor *_forbiddenBorderColor;//禁用边框颜色
    
    NSString *_buttonTitle;
    NSColor *_normalTitleColor;
    NSColor *_enterTitleColor;
    NSColor *_downTitleColor;
    NSColor *_forbiddenTitleColor;
    float _titleSize;
    
    //没有渐变色的时候
    NSColor *_normalFillColor;
    NSColor *_enterFillColor;
    NSColor *_downFillColor;
    //背景填充色
    NSColor *_bgNormalFillColor;
    NSColor *_bgEnterFillColor;
    NSColor *_bgDownFillColor;
    
    MouseStatusEnum _buttonType;
    
    NSImageView *_lightImageView;
    
    BOOL _hasLeftImage;
    NSImage *_leftImage;
    BOOL _hasRightImage;
    NSImage *_rightImage;
    float _spaceWithText;
    BOOL _isAnimation;
    NSMutableDictionary *_dic;
    id <MouseEnumDelegate> _delegate;
    BOOL _isNoGridient;//是否是渐变的
    
    CALayer *_oneCircleLayer;
    CALayer *_twoCircleLayer;
    CALayer *_threeCircleLayer;
    BOOL _isLogining;//正在登陆中
    
}
@property (nonatomic, assign) BOOL isNoGridient;
@property (nonatomic, assign) BOOL isAnimation;//是否有光效
@property (nonatomic, assign) BOOL isLeftRightGridient;//设置为左右渐变,否则是上下渐变
@property (nonatomic, assign) BOOL hasBorder;//是否有边框
@property (nonatomic, assign) float cornerRadius;//圆角半径
@property (nonatomic, assign) float borderLineWidth;//边框宽度
@property (nonatomic, assign) BOOL hasLeftImage;
@property (nonatomic, retain) NSImage *leftImage;
@property (nonatomic, assign) BOOL hasRightImage;
@property (nonatomic, retain) NSImage *rightImage;
@property (nonatomic, assign) float spaceWithText;
@property (nonatomic, retain) NSMutableDictionary *dic;
@property (nonatomic, assign) id <MouseEnumDelegate> delegate;
@property (nonatomic, retain) NSString *buttonTitle;
@property (nonatomic, assign) BOOL isLogining;
/**
 *  设置按钮渐变属性
 *
 *  @param isLeftRightGridient   是否左右渐变，否则为上下渐变
 *  @param leftNormalBgColor     左边一般背景颜色
 *  @param rightNormalBgColor    右边一般背景颜色
 *  @param leftEnterBgColor      左边进入背景颜色
 *  @param rightEnterBgColor     右边进入背景颜色
 *  @param leftDownBgColor       左边点击背景颜色
 *  @param rightDownBgColor      右边点击背景颜色
 *  @param leftForbiddenBgColor  左边禁用背景颜色
 *  @param rightForbiddenBgColor 右边边禁用背景颜色
 */
- (void)setIsLeftRightGridient:(BOOL)isLeftRightGridient withLeftNormalBgColor:(NSColor *)leftNormalBgColor withRightNormalBgColor:(NSColor *)rightNormalBgColor  withLeftEnterBgColor:(NSColor *)leftEnterBgColor withRightEnterBgColor:(NSColor *)rightEnterBgColor withLeftDownBgColor:(NSColor *)leftDownBgColor withRightDownBgColor:(NSColor *)rightDownBgColor withLeftForbiddenBgColor:(NSColor *)leftForbiddenBgColor withRightForbiddenBgColor:(NSColor *)rightForbiddenBgColor;

/**
 *  设置按钮边框属性
 *
 *  @param hasBorder            是否有边框颜色
 *  @param normalBorderColor    一般边框颜色
 *  @param enterBorderColor     进入边框颜色
 *  @param downBorderColor      点击边框颜色
 *  @param forbiddenBorderColor 禁用边框颜色
 *  @param borderLineWidth      边框线宽
 */
- (void)setButtonBorder:(BOOL)hasBorder withNormalBorderColor:(NSColor *)normalBorderColor withEnterBorderColor:(NSColor *)enterBorderColor withDownBorderColor:(NSColor *)downBorderColor withForbiddenBorderColor:(NSColor *)forbiddenBorderColor withBorderLineWidth:(float)borderLineWidth;

/**
 *  设置按钮文字属性
 *
 *  @param buttonTitle         按钮名字
 *  @param normalTitleColor    一般文字颜色
 *  @param enterTitleColor     进入文字颜色
 *  @param downTitleColor      点击文字颜色
 *  @param forbiddenTitleColor 禁用文字颜色
 *  @param titleSize           文字大小
 *  @param isAnimation         是否给按钮加移动光标
 */
- (void)setButtonTitle:(NSString *)buttonTitle withNormalTitleColor:(NSColor *)normalTitleColor withEnterTitleColor:(NSColor *)enterTitleColor withDownTitleColor:(NSColor *)downTitleColor withForbiddenTitleColor:(NSColor *)forbiddenTitleColor withTitleSize:(float)titleSize WithLightAnimation:(BOOL)isAnimation;

/**
 *  没有渐变色的时候
 *
 *  @param normalFillColor 一般背景颜色
 *  @param enterFillColor  进入背景颜色
 *  @param downFillColor   点击背景颜色
 */
- (void)setNormalFillColor:(NSColor *)normalFillColor WithEnterFillColor:(NSColor *)enterFillColor WithDownFillColor:(NSColor *)downFillColor;

- (void)loadAnimation;
- (void)endAnimation;
@end











