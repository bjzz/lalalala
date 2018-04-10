//
//  IMBMainBigIcloudView.m
//  iOSFiles
//
//  Created by iMobie on 2018/3/20.
//  Copyright © 2018年 iMobie. All rights reserved.
//

#import "IMBMainBigIcloudView.h"
#import "IMBCommonDefine.h"
#import "IMBMyDrawCommonly.h"
#import "customTextFiled.h"


@implementation IMBMainBigIcloudView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)awakeFromNib {
    _titleLabel.stringValue = CustomLocalizedString(@"MenuItem_id_18", nil);
    [_titleLabel setFont:[NSFont fontWithName:IMBCommonFont size:18.0]];
    [_titleLabel setTextColor:COLOR_TEXT_ORDINARY];
    
    [_messageLabel setStringValue:CustomLocalizedString(@"iCloud_id_2", nil)];
    [_messageLabel setFont:[NSFont fontWithName:IMBCommonFont size:12.0]];
    [_messageLabel setTextColor:COLOR_TEXT_EXPLAIN];
    
    [_rememberMeLabel setStringValue:CustomLocalizedString(@"iCloudLogin_View_Remeberme", nil)];
    [_rememberMeLabel setFont:[NSFont fontWithName:IMBCommonFont size:12.0]];
    [_rememberMeLabel setTextColor:COLOR_MAINWINDOW_REMEMBENME_TEXT];
    
    [_loginBtn setButtonTitle:CustomLocalizedString(@"Cloud_Login", nil)];
    
    [_icloudLoginPwdTF setPlaceholderString:CustomLocalizedString(@"CloudLogin_Password_Txt", nil)];
    [_icloudLoginPwdTF setFont:[NSFont fontWithName:IMBCommonFont size:14.0]];
    
    [_icloudSecireTF setPlaceholderString:CustomLocalizedString(@"CloudLogin_Password_Txt", nil)];
    [_icloudSecireTF setFont:[NSFont fontWithName:IMBCommonFont size:14.0]];
    
    [_icloudUserTF setPlaceholderString:CustomLocalizedString(@"CloudLogin_AppleID_Txt", nil)];
    [_icloudUserTF setFont:[NSFont fontWithName:IMBCommonFont size:14.0]];
    
    
}

@end
