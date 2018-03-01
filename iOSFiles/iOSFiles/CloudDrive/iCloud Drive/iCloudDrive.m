


//
//  iCloudDrive.m
//  DriveSync
//
//  Created by 罗磊 on 2018/1/17.
//  Copyright © 2018年 imobie. All rights reserved.
//

#import "iCloudDrive.h"
#import "iCloudDriveAuthSigninAPI.h"
#import "iCloudDriveAccountLoginAPI.h"
#import "iCloudDriveVerifySecurityCodeAPI.h"
#import "iCloudDriveGetSecuritycodeAPI.h"
#import "iCloudDriveGetListAPI.h"
#import "iCloudDriveCreateFolderAPI.h"
#import "iCloudDriveDeleteItemsAPI.h"
#import "iCloudDriveRenameAPI.h"
#import "iCloudDriveMoveToNewParentAPI.h"
#import "iCloudDriveDownloadOneAPI.h"
#import "iCloudDriveUploadOneAPI.h"
#import "iCloudDriveUploadTwoAPI.h"
#import "iCloudDriveUploadThreeAPI.h"
#import "iCloudDriveHeartbeatAPI.h"
#import "iCloudDriveLogoutAPI.h"
#import "iCloudDriveValidateAPI.h"

@implementation iCloudDrive
@synthesize userName = _userName;
@synthesize cookie = _cookie;

- (instancetype)init
{
    if (self == [super init]) {
        _cookie = [[NSMutableDictionary alloc] init];
        _downLoader = [[DownLoader alloc] initWithAccessToken:nil];
        _upLoader = [[UpLoader alloc] initWithAccessToken:nil];
    }
    return self;
}

#pragma mark - Login
- (void)logOut
{
    //停止心跳包
    _stopHearBeat = YES;
    //发送一个注销请求 不管注销请求是否成功 我们都清除掉本地cookie
    iCloudDriveLogoutAPI *logoutAPI = [[iCloudDriveLogoutAPI alloc] initWithClientID:_clientID proxyDest:_proxyDest dsid:_dsid cookie:_cookie];
    __block iCloudDriveLogoutAPI *weaklogoutAPI = logoutAPI;
    [logoutAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        [weaklogoutAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        [weaklogoutAPI release];
    }];
    if (_delegate && [_delegate respondsToSelector:@selector(driveDidLogOut:)]) {
        [_delegate driveDidLogOut:self];
    }
}

- (void)loginAppleID:(NSString *)appleID password:(NSString *)password rememberMe:(BOOL)rememberMe;
{
    //将用户名和密码保存在内存中，登录超时可以自动进行第二次登录
    if (_appleID != nil) {
        [_appleID release],_appleID = nil;
    }
    if (_password != nil) {
        [_password release],_password = nil;
    }
    _appleID = [appleID retain];
    _password = [password retain];
    iCloudDriveAuthSigninAPI *icloudsin = [[iCloudDriveAuthSigninAPI alloc] initWithEmail:_appleID withPassword:_password rememberMe:rememberMe];
    __block iCloudDriveAuthSigninAPI *weakiCloudsin = icloudsin;
    __block iCloudDrive *weakself = self;
    [icloudsin startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        id resulst = [NSJSONSerialization JSONObjectWithData:request.responseData options:
                      NSJSONReadingMutableContainers error:NULL];
        NSInteger responscode = request.responseStatusCode;
        if (responscode == 200) {
            //登录第一步认证成功，接下来进行第二部认证
            NSDictionary *responseHeader = request.responseHeaders;
            NSString *sessionToken = [responseHeader objectForKey:@"X-Apple-Session-Token"];
            [weakself accountLogin:sessionToken rememberMe:rememberMe];
        }else if (responscode == 401){
            if ([resulst isKindOfClass:[NSDictionary class]]) {
                NSDictionary *resultContent = (NSDictionary *)resulst;
                if ([resultContent.allKeys containsObject:@"serviceErrors"]) {
                    NSDictionary *errorDic = [resultContent objectForKey:@"serviceErrors"];
                    if ([[errorDic objectForKey:@"code"] isEqualToString:@"-20101"]) {
                        if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
                            [_delegate drive:self logInFailWithResponseCode:ResponseUserNameOrPasswordError];
                        }
                    }
                }
            }
        }else if (responscode == 400){
            //bad request
            if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
                [_delegate drive:self logInFailWithResponseCode:ResponseInvalid];
            }
        }else if (responscode == 409){
            NSDictionary *responseHeader = request.responseHeaders;
            BOOL twoTrust = [[responseHeader objectForKey:@"X-Apple-TwoSV-Trust-Eligible"] boolValue];
            if (twoTrust) {
                NSString *sessionID = [responseHeader objectForKey:@"X-Apple-ID-Session-Id"];
                NSString *scnt = [responseHeader objectForKey:@"scnt"];
                if (_xappleSessionID != nil) {
                    [_xappleSessionID release];
                }
                _xappleSessionID = [sessionID retain];
                if (_scnt != nil) {
                    [_scnt release];
                }
                _scnt = [scnt retain];
                if ([_delegate respondsToSelector:@selector(driveNeedSecurityCode:)]) {
                    [_delegate driveNeedSecurityCode:self];
                }
            }
        }else {
            if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
                [_delegate drive:self logInFailWithResponseCode:ResponseUnknown];
            }
        }
        [weakiCloudsin release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        [weakself faiureError:request.error];
        [weakiCloudsin release];
    }];
}

- (void)accountLogin:(NSString *)sessionToken rememberMe:(BOOL)rememberMe
{
    if (_clientID != nil) {
        [_clientID release];
    }
    _clientID = [[BaseDriveAPI createGUID] retain];
    iCloudDriveAccountLoginAPI *accountLoginAPI = [[iCloudDriveAccountLoginAPI alloc] initWithXappleSessionToken:sessionToken clientID:_clientID rememberMe:rememberMe];
    __block iCloudDriveAccountLoginAPI *weakaccountLoginAPI = accountLoginAPI;
    __block iCloudDrive *weakself = self;
    [accountLoginAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        [weakself paseAccountLogin:request cookie:nil];
        [weakaccountLoginAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        [weakself faiureError:request.error];
        [weakaccountLoginAPI release];
    }];
}

- (void)loginWithCookie:(NSMutableDictionary *)cookie
{
    iCloudDriveValidateAPI *validateAPI = [[iCloudDriveValidateAPI alloc] initWithCookie:cookie];
    __block iCloudDrive *weakself = self;
    __block iCloudDriveValidateAPI *weakvalidateAPI = validateAPI;
    [validateAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        [weakself paseAccountLogin:request cookie:cookie];
        [weakvalidateAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        [weakself faiureError:request.error];
        [weakvalidateAPI release];
    }];
}

- (void)paseAccountLogin:(YTKBaseRequest *)request cookie:(NSMutableDictionary *)cookie
{
    __block iCloudDrive *weakself = self;
    NSInteger responscode = request.responseStatusCode;
    if (responscode == 200) {
        //登录成功保存相关的信息
        [_cookie removeAllObjects];
        if (cookie == nil) {
            NSString *setCookie = [request.responseHeaders objectForKey:@"Set-Cookie"];
            NSArray *setCookieArray = [setCookie componentsSeparatedByString:@";"];
            NSString *totalCookie = @"";
            for (NSString *cookieStr in setCookieArray) {
                if ([[cookieStr uppercaseString] containsString:@"X-APPLE-"]) {
                    NSRange range = [[cookieStr uppercaseString] rangeOfString:@"X-APPLE-"];
                    NSString *subCookieStr = [cookieStr substringFromIndex:range.location];
                    totalCookie = [[totalCookie stringByAppendingString:subCookieStr] stringByAppendingString:@";"];
                }
            }
            //保存cookie
            if (setCookie) {
                [_cookie setObject:totalCookie forKey:@"Cookie"];
            }

        }else{
            [_cookie addEntriesFromDictionary:cookie];
        }
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingMutableContainers error:NULL];
        if ([result objectForKey:@"dsInfo"]) {
            NSString *fullName = [[result objectForKey:@"dsInfo"] objectForKey:@"fullName"];
            if (_userName != nil) {
                [_userName release];
            }
            _userName = [fullName retain];
            NSString *dsid = [[result objectForKey:@"dsInfo"] objectForKey:@"dsid"];
            if (_dsid != nil) {
                [_dsid release];
            }
            _dsid = [dsid retain];
        }
        if ([result objectForKey:@"webservices"]) {
            NSDictionary *drivewsDic = [[result objectForKey:@"webservices"] objectForKey:@"drivews"];
            NSString *iCloudDriveUrl = [drivewsDic objectForKey:@"url"];
            if (_iCloudDriveUrl != nil) {
                [_iCloudDriveUrl release];
            }
            _iCloudDriveUrl = [iCloudDriveUrl retain];
            NSDictionary *pushDic = [[result objectForKey:@"webservices"] objectForKey:@"push"];
            NSString *pushUrl = [pushDic objectForKey:@"url"];
            if (_pushUrl != nil) {
                [_pushUrl release];
            }
            _pushUrl = [pushUrl retain];
            
            NSDictionary *docwsDic = [[result objectForKey:@"webservices"] objectForKey:@"docws"];
            NSString *docwsUrl = [docwsDic objectForKey:@"url"];
            if (_iCloudDriveDocwsUrl != nil) {
                [_iCloudDriveDocwsUrl release];
            }
            _iCloudDriveDocwsUrl = [docwsUrl retain];
            
            NSDictionary *accountDic = [[result objectForKey:@"webservices"] objectForKey:@"account"];
            NSString *accountUrl = [accountDic objectForKey:@"url"];
            if (_accountUrl != nil) {
                [_accountUrl release];
            }
            _accountUrl = [accountUrl retain];
            if (_proxyDest != nil) {
                [_proxyDest release];
            }
            _proxyDest = [[[_accountUrl stringByReplacingOccurrencesOfString:@"https://" withString:@""] stringByReplacingOccurrencesOfString:@".icloud.com:443" withString:@""] retain];
            //成功登录回调
            if ([_delegate respondsToSelector:@selector(driveDidLogIn:)]) {
                [_delegate driveDidLogIn:weakself];
                //后台开启心跳包，一直保持会话处于激活有效状态
                if (cookie == nil) {
                    [self startHeartbeatPacket];
                }
            }
        }
    }else{
        if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
            [_delegate drive:self logInFailWithResponseCode:ResponseUnknown];
        }
    }
}


- (void)startHeartbeatPacket
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            while (1) {
                iCloudDriveHeartbeatAPI *hearBeatAPI = [[iCloudDriveHeartbeatAPI alloc] initWithPushUrl:_pushUrl dsid:_dsid cookie:_cookie];
                __block iCloudDriveHeartbeatAPI *weakhearBeatAPI = hearBeatAPI;
                [hearBeatAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                    [weakhearBeatAPI release];
                } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
                    [weakhearBeatAPI release];
                }];
                [NSThread sleepForTimeInterval:100];
                if (_stopHearBeat) {
                    break;
                }
            }
        }
    });
}

- (void)verifySecurityCode:(NSString *)securityCode rememberMe:(BOOL)rememberMe
{
    iCloudDriveVerifySecurityCodeAPI *verifycodeAPI = [[iCloudDriveVerifySecurityCodeAPI alloc] initWithSecurityCode:securityCode sessionID:_xappleSessionID scnt:_scnt];
    __block  iCloudDriveVerifySecurityCodeAPI *weakverifycodeAPI = verifycodeAPI;
    __block iCloudDrive *weakself = self;
    [weakverifycodeAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        id resulst = [NSJSONSerialization JSONObjectWithData:request.responseData options:
                      NSJSONReadingMutableContainers error:NULL];
        if (request.responseStatusCode == 204) {
            //验证安全码成功，开始最后一步登录请求
            NSDictionary *responseHeader = request.responseHeaders;
            NSString *sessionToken = [responseHeader objectForKey:@"X-Apple-Session-Token"];
            [weakself accountLogin:sessionToken rememberMe:rememberMe];
        }else if (request.responseStatusCode == 401){
            //长时间不输入验证码 导致会话失效 需要重新走登录流程
            if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
                [_delegate drive:self logInFailWithResponseCode:ResponseSessionExpired];
            }
        }else if (request.responseStatusCode == 400){
            //安全码验证失败
            if ([resulst isKindOfClass:[NSDictionary class]]) {
                NSDictionary *resultContent = (NSDictionary *)resulst;
                if ([resultContent.allKeys containsObject:@"service_errors"]) {
                    NSArray *errorArray = [resultContent objectForKey:@"service_errors"];
                    if ([errorArray count]>0) {
                        NSDictionary *errorDic = [errorArray objectAtIndex:0];
                        NSString *code = [errorDic objectForKey:@"code"];
                        if ([code isEqualToString:@"-21669"]) {
                            //验证码错误
                            if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
                                [_delegate drive:self logInFailWithResponseCode:ResonseSecurityCodeError];
                            }
                        }else{
                            if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
                                [_delegate drive:self logInFailWithResponseCode:ResponseUnknown];
                            }
                        }
                    }
                }
            }else{
                if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
                    [_delegate drive:self logInFailWithResponseCode:ResponseUnknown];
                }
            }
        }else {
            if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
                [_delegate drive:self logInFailWithResponseCode:ResponseUnknown];
            }
        }
        [weakverifycodeAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        [weakself faiureError:request.error];
        [weakverifycodeAPI release];
    }];
}

- (void)faiureError:(NSError *)error
{
    if (error.code == -1009) {
        if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
            [_delegate drive:self logInFailWithResponseCode:ResponseNoNetwork];
        }
    }else{
        if ([_delegate respondsToSelector:@selector(drive:logInFailWithResponseCode:)]) {
            [_delegate drive:self logInFailWithResponseCode:ResponseUnknown];
        }
    }
}

- (void)resendGetSecurity
{
    iCloudDriveGetSecuritycodeAPI *getSecurityCode = [[iCloudDriveGetSecuritycodeAPI alloc] initWithAppleSessionID:_xappleSessionID scnt:_scnt];
    __block iCloudDriveGetSecuritycodeAPI *weakgetSecurityCode = getSecurityCode;
    [getSecurityCode startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request)
    {
        [weakgetSecurityCode release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        [weakgetSecurityCode release];
    }];
}

#pragma mark - business Actions

- (void)createFolder:(NSString *)folderName parent:(NSString *)parentID success:(Callback)success fail:(Callback)fail
{
    YTKRequest *requestAPI = [[iCloudDriveCreateFolderAPI alloc] initWithFolderName:folderName Parent:parentID dsid:_dsid cookie:_cookie iCloudDriveURL:_iCloudDriveUrl];
    __block YTKRequest *weakRequestAPI = requestAPI;
    [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithSuccess:request];
        if (code == ResponseSuccess) {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
            success?success(response):nil;
            [response release];
        }else {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData: nil status:code];
            fail?fail(response):nil;
            [response release];
        }
        [weakRequestAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        //to do需要更具返回值判断错误
        ResponseCode code = [self checkResponseTypeWithFailed:request];
        NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
        NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
        DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
        fail?fail(response):nil;
        [response release];
        [weakRequestAPI release];
    }];
}


- (void)getList:(NSString *)folerID success:(Callback)success fail:(Callback)fail
{
    YTKRequest *requestAPI = [[iCloudDriveGetListAPI alloc] initWithItemID:folerID cookie:_cookie iCloudDriveURL:_iCloudDriveUrl];
    __block YTKRequest *weakRequestAPI = requestAPI;
    [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithSuccess:request];
        if (code == ResponseSuccess) {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
            success?success(response):nil;
            [response release];
        }else {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData: nil status:code];
            fail?fail(response):nil;
            [response release];
        }
        [weakRequestAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithFailed:request];
        NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
        NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
        DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
        fail?fail(response):nil;
        [response release];
        [weakRequestAPI release];
    }];
}

- (void)deleteFilesOrFolders:(NSArray *)fileOrFolderIDs success:(Callback)success fail:(Callback)fail
{
    YTKRequest *requestAPI = [[iCloudDriveDeleteItemsAPI alloc] initWithDeleteItems:fileOrFolderIDs dsid:_dsid cookie:_cookie iCloudDriveURL:_iCloudDriveUrl];
    __block YTKRequest *weakRequestAPI = requestAPI;
    [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithSuccess:request];
        if (code == ResponseSuccess) {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
            success?success(response):nil;
            [response release];
        }else {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData: nil status:code];
            fail?fail(response):nil;
            [response release];
        }
        [weakRequestAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        //to do需要更具返回值判断错误
        ResponseCode code = [self checkResponseTypeWithFailed:request];
        NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
        NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
        DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
        fail?fail(response):nil;
        [response release];
        [weakRequestAPI release];
    }];
}

- (void)reName:(NSDictionary *)item  success:(Callback)success fail:(Callback)fail
{
    YTKRequest *requestAPI = [[iCloudDriveRenameAPI alloc] initWithRenameItems:item dsid:_dsid cookie:_cookie iCloudDriveURL:_iCloudDriveUrl];
    __block YTKRequest *weakRequestAPI = requestAPI;
    [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithSuccess:request];
        if (code == ResponseSuccess) {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
            success?success(response):nil;
            [response release];
        }else {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData: nil status:code];
            fail?fail(response):nil;
            [response release];
        }
        [weakRequestAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        //to do需要更具返回值判断错误
        ResponseCode code = [self checkResponseTypeWithFailed:request];
        NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
        NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
        DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
        fail?fail(response):nil;
        [response release];
        [weakRequestAPI release];
    }];
}

- (void)moveToNewParent:(NSString *)newParent itemDic:(NSDictionary *)item   success:(Callback)success fail:(Callback)fail
{
    YTKRequest *requestAPI = [[iCloudDriveMoveToNewParentAPI alloc] initWithMoveItemDic:item newParentIDOrPathdsid:newParent dsid:_dsid cookie:_cookie iCloudDriveURL:_iCloudDriveUrl];
    __block YTKRequest *weakRequestAPI = requestAPI;
    [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithSuccess:request];
        if (code == ResponseSuccess) {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
            success?success(response):nil;
            [response release];
        }else {
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData: nil status:code];
            fail?fail(response):nil;
            [response release];
        }
        [weakRequestAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        //to do需要更具返回值判断错误
        ResponseCode code = [self checkResponseTypeWithFailed:request];
        NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
        NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
        DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
        fail?fail(response):nil;
        [response release];
        [weakRequestAPI release];
    }];
}

#pragma mark - downloadActions
- (void)downloadItem:(_Nonnull id<DownloadAndUploadDelegate>)item
{
    if (item.isFolder) {
        [self downloadFolder:item];
    }else{
        //第一步先获取下载链接
        iCloudDriveDownloadOneAPI *downloadAPI = [[iCloudDriveDownloadOneAPI alloc] initWithDocumentID:[item  docwsID] zone:[item zone] iCloudDriveDocwsURL:_iCloudDriveDocwsUrl];
        __block YTKRequest *weakdownloadAPI = downloadAPI;
        [downloadAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
            if (request.responseStatusCode == 200) {
                //解析返回结果
                NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingMutableContainers error:NULL];
                NSDictionary *data_tokenDic = [resultDic objectForKey:@"data_token"];
                NSString *url = [data_tokenDic objectForKey:@"url"];
                item.urlString = url;
                item.httpMethod = @"GET";
                [_downLoader downloadItem:item];
            }else{
                item.state = DownloadStateError;
            }
            [weakdownloadAPI release];
        } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
            item.state = DownloadStateError;
            [weakdownloadAPI release];
        }];
    }
}

- (void)downloadFolder:(_Nonnull id<DownloadAndUploadDelegate>)item
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            NSMutableArray *allfileArray = [NSMutableArray array];
            [self getAllFile:item.itemIDOrPath AllChildArray:allfileArray parentPath:[NSString stringWithFormat:@"/%@",item.fileName]];
            [item setChildArray:allfileArray];
            long long  totalSize = [[item.childArray valueForKeyPath:@"@sum.fileSize"] longLongValue];
            [item setFileSize:totalSize];
            NSMutableArray *reverseArray = [NSMutableArray array];
            [allfileArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                id <DownloadAndUploadDelegate> childItem = obj;
                childItem.parent = item;
                [reverseArray addObject:childItem];
            }];
            //设置为等待状态
            item.state = DownloadStateWait;
            [self downloadItems:reverseArray];
        }
    });
}

- (NSDictionary *)getList:(NSString *)folerID
{
    __block NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    __block BaseDrive *weakSelf = self;
    __block BOOL iswait = YES;
    __block NSThread *currentthread = [NSThread currentThread];
    [self getList:folerID  success:^(DriveAPIResponse *response) {
        NSArray *contentArray = response.content;
        if ([contentArray count]>0) {
            NSDictionary *conDic = [contentArray objectAtIndex:0];
            [dic setDictionary:conDic];
            iswait = NO;
            [weakSelf performSelector:@selector(createFolderWait) onThread:currentthread withObject:nil waitUntilDone:NO];
        }
    } fail:^(DriveAPIResponse *response) {
        NSDictionary *edic = [NSDictionary dictionaryWithObject:response.content forKey:@"error"];
        [dic setDictionary:edic];
        iswait = NO;
        [weakSelf performSelector:@selector(createFolderWait) onThread:currentthread withObject:nil waitUntilDone:NO];
        NSLog(@"获取list失败");
    }];
    while (iswait) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    return dic;
}

- (void)getAllFile:(NSString *)folderID  AllChildArray:(NSMutableArray *)allChildArray  parentPath:(NSString *)parentPath
{
    NSDictionary *dic = [self getList:folderID];
    //解析列表
    NSMutableArray *childArray = [dic objectForKey:@"items"];
    for (NSDictionary *childDic in childArray) {
        if ([[childDic objectForKey:@"type"] isEqualToString:@"FOLDER"]) {
            //是文件夹
            NSString *folderID = [childDic objectForKey:@"drivewsid"];
            NSString *foderName = [childDic objectForKey:@"name"];
            NSString *path = [parentPath stringByAppendingPathComponent:foderName];
            [self getAllFile:folderID AllChildArray:allChildArray parentPath:path];
            
        }else{
            //构建downloaditem
            DownLoadAndUploadItem *item = [[DownLoadAndUploadItem alloc] init];
            item.docwsID = [childDic objectForKey:@"docwsid"];
            item.itemIDOrPath = [childDic objectForKey:@"drivewsid"];
            item.parentPath = parentPath;

            item.fileName =  [NSString stringWithFormat:@"%@.%@",[childDic objectForKey:@"name"],[childDic objectForKey:@"extension"]]   ;
            item.fileSize = [[childDic objectForKey:@"size"] longLongValue];
            item.doZone = [childDic objectForKey:@"zone"];
            [allChildArray addObject:item];
            [item release];
        }
    }
}

- (void)uploadItem:(_Nonnull id<DownloadAndUploadDelegate>)item {
    if (item.isFolder) {
        [self uploadFolder:item];
    }else{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[item localPath] error:nil];
            long long fileSize = [[attr objectForKey:NSFileSize] longLongValue];
            YTKRequest *requestAPI = [[iCloudDriveUploadOneAPI alloc] initWithiCloudDriveDocwsUrl:_iCloudDriveDocwsUrl fileName:[item fileName] mimeType:[BaseDrive getMIMETypeWithCAPIAtFilePath:[item localPath]] fileSize:fileSize cookie:_cookie];
            __block YTKRequest *weakRequestAPI = requestAPI;
            [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                if (request.responseStatusCode == 200) {
                    //解析返回结果
                     NSArray *resultArray = [NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingMutableContainers error:NULL];
                    if ([resultArray count]>0) {
                        NSDictionary *resultsDic = [resultArray objectAtIndex:0];
                        NSString *documentID = [resultsDic objectForKey:@"document_id"];
                        NSString *url = [resultsDic objectForKey:@"url"];
                        YTKRequest *requesttwoAPI = [[iCloudDriveUploadTwoAPI alloc] initWithUploadURL:url];
                        item.requestAPI = requesttwoAPI;
                        item.isConstructingData = YES;
                        [_upLoader uploadmutilPartItem:item success:^(__kindof YTKBaseRequest * _Nonnull request) {
                            //进行最后一步更新操作
                            if (request.responseStatusCode == 200) {
                                NSDictionary *singleFileDic = [[NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingMutableContainers error:NULL] objectForKey:@"singleFile"];
                                NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
                                [singleFileDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                                    if ([key isEqualToString:@"fileChecksum"]) {
                                        [dataDic setObject:obj forKey:@"signature"];
                                    }else if([key isEqualToString:@"wrappingKey"]){
                                        [dataDic setObject:obj forKey:@"wrapping_key"];
                                    }else if([key isEqualToString:@"referenceChecksum"]){
                                        [dataDic setObject:obj forKey:@"reference_signature"];
                                    }else{
                                        [dataDic setObject:obj forKey:key];
                                    }
                                }];
                                YTKRequest *requestThreeAPI = [[iCloudDriveUploadThreeAPI alloc] initWithiCloudDriveDocwsUrl:_iCloudDriveDocwsUrl dataDic:(NSMutableDictionary *)dataDic fileName:[item fileName] parent:[item uploadParent] documentID:documentID cookie:_cookie];
                                __block YTKRequest *weakrequestThreeAPI = requestThreeAPI;
                                [requestThreeAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                                    item.state = UploadStateComplete;
                                    //如果是文件夹
                                    if (item.parent != nil) {
                                        id <DownloadAndUploadDelegate> parentItem = item.parent;
                                        NSPredicate *cate1 =[NSPredicate predicateWithFormat:@"self.state=%d",UploadStateComplete];
                                        NSArray *completeArray = [parentItem.childArray filteredArrayUsingPredicate:cate1];
                                        NSPredicate *cate2 =[NSPredicate predicateWithFormat:@"self.state=%d",UploadStateError];
                                        NSArray *errorArray = [parentItem.childArray filteredArrayUsingPredicate:cate2];
                                        if ([completeArray count] + [errorArray count] == [parentItem.childArray count]) {
                                            parentItem.state = UploadStateComplete;
                                        }
                                    }
                                    [weakrequestThreeAPI release];
                                } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
                                    item.state = UploadStateError;
                                    [weakrequestThreeAPI release];
                                }];
                            }else{
                                item.state = UploadStateError;
                            }
                        }];
                        [requesttwoAPI release];
                    }else{
                        item.state = UploadStateError;
                    }
                }else{
                    item.state = UploadStateError;
                }
                [weakRequestAPI release];
            } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
                [weakRequestAPI release];
                item.state = UploadStateError;
            }];
        });
    }
}

- (void)uploadFolder:(_Nonnull id<DownloadAndUploadDelegate>)item
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            NSMutableArray *allfileArray = [NSMutableArray array];
            [self createFolder:[item localPath] parent:[item uploadParent] AllChildArray:allfileArray];
            [item setChildArray:allfileArray];
            long long  totalSize = [[item.childArray valueForKeyPath:@"@sum.fileSize"] longLongValue];
            [item setFileSize:totalSize];
            [allfileArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                id <DownloadAndUploadDelegate> childItem = obj;
                childItem.parent = item;
            }];
            [self uploadItems:allfileArray];
        }
    });
}

- (void)createFolder:(NSString *)localPath parent:(NSString *)parent AllChildArray:(NSMutableArray *)allfileArray
{
    NSString *folderName = [localPath lastPathComponent];
    NSDictionary *dic = [self createFolder:folderName parent:parent];
    NSString *subparent = nil;
    NSString *subdocParent = nil;
    if ([dic objectForKey:@"folders"]) {
        NSArray *folderArray = [dic objectForKey:@"folders"];
        if ([folderArray count]>0) {
            NSDictionary *folderDic = [folderArray objectAtIndex:0];
            subparent = [folderDic objectForKey:@"drivewsid"];
            subdocParent = [folderDic objectForKey:@"docwsid"];
        }
    }
    //创建文件夹成功之后 开始遍历本地的这个文件目录
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:localPath error:nil];
    NSString *sublocalPath = nil;
    for (NSString *fileName in content) {
        if ([fileName rangeOfString:@".DS_Store"].location != NSNotFound) {
            continue;
        }
        sublocalPath = [localPath stringByAppendingPathComponent:fileName];
        if ([[[NSFileManager defaultManager] attributesOfItemAtPath:sublocalPath error:nil] fileType] == NSFileTypeDirectory) {
            //如果是文件夹
            [self createFolder:sublocalPath parent:subparent AllChildArray:allfileArray];
        } else if ([[[NSFileManager defaultManager] attributesOfItemAtPath:sublocalPath error:nil] fileType] == NSFileTypeRegular) {
            //如果是文件
            DownLoadAndUploadItem *upLoadItme = [[DownLoadAndUploadItem alloc] init];
            upLoadItme.fileName = fileName;
            upLoadItme.localPath = sublocalPath;
            upLoadItme.uploadParent = subdocParent;
            upLoadItme.fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:sublocalPath error:nil] fileSize];
            [allfileArray addObject:upLoadItme];
            [upLoadItme release];
        }
    }
}

- (ResponseCode)checkResponseTypeWithSuccess:(YTKBaseRequest *)request
{
    if (request.responseStatusCode == 200) {
        return ResponseSuccess;
    }else if (request.responseStatusCode == 400){
        return ResponseInvalid;
    }else{
        return ResponseUnknown;
    }
}

- (ResponseCode)checkResponseTypeWithFailed:(YTKBaseRequest *)request
{
    NSError *error = request.error;
    if (error.code == -1009) {
        return ResponseNoNetwork;
    }else if (error.code == -1001){
        return ResponseTimeOut;
    }else{
        return ResponseUnknown;
    }
}

- (void)dealloc
{
    [_dsid release],_dsid = nil;
    [_appleID release],_appleID = nil;
    [_password release],_password = nil;
    [_userName release],_userName = nil;
    [_iCloudDriveDocwsUrl release],_iCloudDriveDocwsUrl = nil;
    [_accountUrl release],_accountUrl = nil;
    [_clientID release],_clientID = nil;
    [super dealloc];
}
@end
