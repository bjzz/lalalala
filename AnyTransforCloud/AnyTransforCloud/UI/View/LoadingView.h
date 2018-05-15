//
//  LoadingView.h
//  AnyTrans
//
//  Created by iMobie_Market on 16/8/1.
//  Copyright (c) 2016年 imobie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CircleView;
@interface LoadingView : NSView
{
    CALayer *drawingLayer;
    CALayer *drawingLayer2;
    NSColor *_bgColor;
}
-(void)startAnimation;
-(void)endAnimation;
- (void)setbackColor:(NSColor *)backgroundColor ;
@end
