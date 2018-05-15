//
//  Dropbox.m
//  DriveSync
//
//  Created by JGehry on 12/4/17.
//  Copyright © 2017 imobie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Dropbox.h"
#import "DropboxUserAccountAPI.h"
#import "DropboxUserSpaceUsageAPI.h"
#import "DropboxCreateFolderAPI.h"
#import "DropboxDeleteItemAPI.h"
#import "DropboxDeleteMultipleItemAPI.h"
#import "DropboxDeleteMultipleItemCheckAPI.h"
#import "DropboxGetListAPI.h"
#import "DropboxSearchAPI.h"
#import "DropboxUploadAPI.h"
#import "DropboxUploadSessionStartAPI.h"
#import "DropboxUploadSessionAppendAPI.h"
#import "DropboxUploadSessionFinishAPI.h"
#import "DropboxCopyItemAPI.h"
#import "DropboxCopyMultipleItemAPI.h"
#import "DropboxCopyMultipleItemCheckAPI.h"
#import "DropboxMoveToNewParentAPI.h"
#import "DropboxMoveMultipleToNewParentAPI.h"
#import "DropboxMoveMultipleToNewParentCheckAPI.h"

NSString *const kClientIDWithDropbox = @"9vgchj5wjyl6cc1";
NSString *const kClientSecretWithDropbox = @"5nrjn0hfmtmopn8";
NSString *const kRedirectURIWithDropbox = @"http://127.0.0.1:58240/";
NSString *const kSuccessURLStringWithDropbox = @"https://www.imobie.com";
NSString *const OAuthorizationEndpointWithDropbox = @"https://www.dropbox.com/oauth2/authorize";
NSString *const TokenEndpointWithDropbox = @"https://api.dropboxapi.com/oauth2/token";

@implementation Dropbox

- (void)logIn
{
    if ([self isAuthValid]) {
        if ([_delegate respondsToSelector:@selector(driveDidLogIn:)]) {
            [_delegate driveDidLogIn:self];
        }
    }else{
        if (_redirectHTTPHandler != nil) {
            [_redirectHTTPHandler release],
            _redirectHTTPHandler = nil;
        }
        NSArray *scope = 0;
        NSURL *authorizationEndpoint =
        [NSURL URLWithString:OAuthorizationEndpointWithDropbox];
        NSURL *tokenEndpoint =
        [NSURL URLWithString:TokenEndpointWithDropbox];
        NSURL *successURL = [NSURL URLWithString:kSuccessURLStringWithDropbox];
        _redirectHTTPHandler = [[OIDRedirectHTTPHandler alloc] initWithSuccessURL:successURL];
        NSURL *redirectURI = [_redirectHTTPHandler startHTTPListener:nil];
        OIDServiceConfiguration *configuration =
        [[OIDServiceConfiguration alloc] initWithAuthorizationEndpoint:authorizationEndpoint
                                                         tokenEndpoint:tokenEndpoint];
        OIDAuthorizationRequest *request =
        [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:kClientIDWithDropbox
                                                  clientSecret:kClientSecretWithDropbox
                                                        scopes:scope
                                                   redirectURL:redirectURI
                                                  responseType:OIDResponseTypeCode
                                          additionalParameters:nil];
        [request setCodeVerifier:nil];
        [request setCodeChallenge:nil];
        [request setCodeChallengeMethod:nil];
        _redirectHTTPHandler.currentAuthorizationFlow =
        [[OIDAuthState authStateByPresentingAuthorizationRequest:request
                                                        callback:^(OIDAuthState *_Nullable authState,
                                                                   NSError *_Nullable error) {
                                                            if (authState) {
                                                                //此处需要给自己的token赋值
                                                                self.accessToken = authState.lastTokenResponse.accessToken;
                                                                self.expirationDate = authState.lastTokenResponse.accessTokenExpirationDate;
                                                                
                                                                if ([_delegate respondsToSelector:@selector(driveDidLogIn:)]) {
                                                                    [_delegate driveDidLogIn:self];
                                                                }
                                                            } else {
                                                                if ([_delegate respondsToSelector:@selector(drive:logInFailWithError:)]) {
                                                                    [_delegate drive:self logInFailWithError:error];
                                                                }
                                                            }
                                                        }] retain];
    }
}

#pragma mark -- 获取云盘用户信息
- (void)getAccount:(NSString *)accountID success:(Callback)success fail:(Callback)fail {
    if ([self isExecute]) {
        YTKRequest *requestAPI = [[DropboxUserAccountAPI alloc] initWithUserAccountID:accountID accessToken:_accessToken];
        __block YTKRequest *weakRequestAPI = requestAPI;
        [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
            ResponseCode code = [self checkResponseTypeWithSuccess:request];
            if (code == ResponseSuccess) {
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                success?success(response):nil;
                [response release];
            }else {
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
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
}

#pragma mark -- 获取云盘使用空间
- (void)getSpaceUsage:(NSString *)spaceUsage success:(Callback)success fail:(Callback)fail {
    if ([self isExecute]) {
        YTKRequest *requestAPI = [[DropboxUserSpaceUsageAPI alloc] initWithUserAccountID:spaceUsage accessToken:_accessToken];
        __block YTKRequest *weakRequestAPI = requestAPI;
        [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
            ResponseCode code = [self checkResponseTypeWithSuccess:request];
            if (code == ResponseSuccess) {
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                success?success(response):nil;
                [response release];
            }else {
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
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
}

- (void)createFolder:(NSString *)folderName parent:(NSString *)parentFilePath success:(Callback)success fail:(Callback)fail {
    if ([self isExecute]) {
        YTKRequest *requestAPI = [[DropboxCreateFolderAPI alloc] initWithFolderName:folderName Parent:parentFilePath accessToken:_accessToken];
        __block YTKRequest *weakRequestAPI = requestAPI;
        [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
            ResponseCode code = [self checkResponseTypeWithSuccess:request];
            if (code == ResponseSuccess) {
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                success?success(response):nil;
                [response release];
            }else {
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
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
}

- (void)getList:(NSString *)folerID success:(Callback)success fail:(Callback)fail {
    if ([self isExecute]) {
        YTKRequest *requestAPI = [[DropboxGetListAPI alloc] initWithItemID:folerID accessToken:_accessToken];
        __block YTKRequest *weakRequestAPI = requestAPI;
        [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
            ResponseCode code = [self checkResponseTypeWithSuccess:request];
            if (code == ResponseSuccess) {
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                success?success(response):nil;
                [response release];
            }else {
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
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
}

- (void)searchContent:(NSString *)query withLimit:(NSString *)limit withPageIndex:(NSString *)pageIndex success:(Callback)success fail:(Callback)fail {
    if ([self isExecute]) {
        if ([limit isEqualToString:@""] || [limit isEqualToString:@"0"] || !limit) {
            limit = @"20";
        }
        if ([pageIndex isEqualToString:@""] || [pageIndex isEqualToString:@"0"]) {
            pageIndex = nil;
        }
        YTKRequest *requestAPI = [[DropboxSearchAPI alloc] initWithUserLoginToken:self.userLoginToken withDriveID:self.driveID withSearchName:query withSearchLimit:limit withSearchPageIndex:pageIndex];
        __block YTKRequest *weakRequestAPI = requestAPI;
        [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
            ResponseCode code = [self checkResponseTypeWithSuccess:request];
            if (code == ResponseSuccess) {
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                success?success(response):nil;
                [response release];
            }else {
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
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
}

- (void)deleteFilesOrFolders:(NSArray *)idOrPathArray success:(Callback)success fail:(Callback)fail {
    if ([self isExecute]) {
        if ([idOrPathArray count] > 0 && [idOrPathArray count] == 1) {
            YTKRequest *requestAPI = nil;
            for (NSDictionary *itemDict in idOrPathArray) {
                NSString *itemID = [itemDict objectForKey:@"itemIDOrPath"];
                requestAPI = [[DropboxDeleteItemAPI alloc] initWithItemID:itemID accessToken:_accessToken];
            }
            __block YTKRequest *weakRequestAPI = requestAPI;
            [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithSuccess:request];
                if (code == ResponseSuccess) {
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                    success?success(response):nil;
                    [response release];
                }else {
                    NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                    NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
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
        }else if ([idOrPathArray count] > 0) {
            YTKRequest *requestAPI = [[DropboxDeleteMultipleItemAPI alloc] initWithItemsID:idOrPathArray accessToken:_accessToken];
            __block YTKRequest *weakResquestAPI = requestAPI;
            [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithSuccess:request];
                if (code == ResponseSuccess) {
                    if ([request responseData]) {
                        if ([request responseJSONObject] && [[request responseJSONObject] isKindOfClass:[NSDictionary class]]) {
                            NSString *asyncJobID = [[request responseJSONObject] objectForKey:@"async_job_id"];
                            [self deleteMultipleItemCheck:asyncJobID success:success fail:fail];
                        }
                    }
                }else {
                    NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                    NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                    fail?fail(response):nil;
                    [response release];
                }
                [weakResquestAPI release];
            } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithFailed:request];
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                fail?fail(response):nil;
                [response release];
                [weakResquestAPI release];
            }];
        }
    }
}

- (void)deleteMultipleItemCheck:(NSString *)asyncJobID success:(Callback)success fail:(Callback)fail {
    YTKRequest *asyncJobRequestAPI = [[DropboxDeleteMultipleItemCheckAPI alloc] initWithItemsAsyncJobID:asyncJobID accessToken:_accessToken];
    __block YTKRequest *weakAsyncJobResquestAPI = asyncJobRequestAPI;
    [asyncJobRequestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithSuccess:request];
        if (code == ResponseSuccess) {
            if ([request responseData]) {
                if ([request responseJSONObject] && [[request responseJSONObject] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = [request responseJSONObject];
                    if ([[dict allKeys] containsObject:@".tag"]) {
                        if ([[dict objectForKey:@".tag"] isEqualToString:@"in_progress"]) {
                            sleep(1);
                            [self deleteMultipleItemCheck:asyncJobID success:success fail:fail];
                        }else if ([[dict objectForKey:@".tag"] isEqualToString:@"failed"]) {
                            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                            fail?fail(response):nil;
                            [response release];
                        }else {
                            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                            success?success(response):nil;
                            [response release];
                        }
                    }
                }
            }
        }
        [weakAsyncJobResquestAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithFailed:request];
        NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
        NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
        DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
        fail?fail(response):nil;
        [response release];
        [weakAsyncJobResquestAPI release];
    }];
}

- (void)copyToNewParentIDOrPath:(NSString *)newParentIdOrPath idOrPathArray:(NSArray *)idOrPathArray success:(Callback)success fail:(Callback)fail {
    if ([self isExecute]) {
        if ([idOrPathArray count] > 0 && [idOrPathArray count] == 1) {
            YTKRequest *requestAPI = nil;
            for (NSDictionary *itemDict in idOrPathArray) {
                NSString *itemID = [itemDict objectForKey:@"fromItemIDOrPath"];
                NSString *newName = [[itemID componentsSeparatedByString:@"/"] lastObject];
                if ([newParentIdOrPath isEqualToString:@"0"]) {
                    requestAPI = [[DropboxCopyItemAPI alloc] initWithItemID:itemID newParentIDOrPath:newName parent:newParentIdOrPath accessToken:_accessToken];
                }else {
                    requestAPI = [[DropboxCopyItemAPI alloc] initWithItemID:itemID newParentIDOrPath:[newParentIdOrPath stringByAppendingPathComponent:newName] parent:@"" accessToken:_accessToken];
                }
            }
            __block YTKRequest *weakRequest = requestAPI;
            [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithSuccess:request];
                if (code == ResponseSuccess) {
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                    success?success(response):nil;
                    [response release];
                }else {
                    NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                    NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                    fail?fail(response):nil;
                    [response release];
                }
                [weakRequest release];
            } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
                //to do需要更具返回值判断错误
                ResponseCode code = [self checkResponseTypeWithFailed:request];
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                fail?fail(response):nil;
                [response release];
                [weakRequest release];
            }];
        }else if ([idOrPathArray count] > 0) {
            NSMutableArray *oldIdOrPathsArray = [[NSMutableArray alloc] init];
            NSMutableArray *newIdOrPathsArray = [[NSMutableArray alloc] init];
            for (NSDictionary *itemDict in idOrPathArray ) {
                NSString *itemID = [itemDict objectForKey:@"fromItemIDOrPath"];
                NSString *newName = [[itemID componentsSeparatedByString:@"/"] lastObject];
                [oldIdOrPathsArray addObject:itemID];
                if ([newParentIdOrPath isEqualToString:@"0"]) {
                    [newIdOrPathsArray addObject:newName];
                }else {
                    [newIdOrPathsArray addObject:[newParentIdOrPath stringByAppendingPathComponent:newName]];
                }
            }
            YTKRequest *requestAPI = nil;
            if ([newParentIdOrPath isEqualToString:@"0"]) {
                requestAPI = [[DropboxCopyMultipleItemAPI alloc] initWithItemsID:oldIdOrPathsArray newParentIDOrPath:newIdOrPathsArray parent:newParentIdOrPath accessToken:_accessToken];
            }else {
                requestAPI = [[DropboxCopyMultipleItemAPI alloc] initWithItemsID:oldIdOrPathsArray newParentIDOrPath:newIdOrPathsArray parent:@"" accessToken:_accessToken];
            }
            [oldIdOrPathsArray release];
            oldIdOrPathsArray = nil;
            [newIdOrPathsArray release];
            newIdOrPathsArray = nil;
            __block YTKRequest *weakRequest = requestAPI;
            [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithSuccess:request];
                if (code == ResponseSuccess) {
                    if ([request responseData]) {
                        if ([request responseJSONObject] && [[request responseJSONObject] isKindOfClass:[NSDictionary class]]) {
                            NSString *asyncJobID = [[request responseJSONObject] objectForKey:@"async_job_id"];
                            [self copyMultipleToNewParentCheck:asyncJobID success:success fail:fail];
                        }
                    }
                }else {
                    NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                    NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                    fail?fail(response):nil;
                    [response release];
                }
                [weakRequest release];
            } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithFailed:request];
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                fail?fail(response):nil;
                [response release];
                [weakRequest release];
            }];
        }
    }
}

- (void)copyMultipleToNewParentCheck:(NSString *)asyncJobID success:(Callback)success fail:(Callback)fail {
    YTKRequest *asyncJobRequestAPI = [[DropboxCopyMultipleItemCheckAPI alloc] initWithItemsAsyncJobID:asyncJobID accessToken:_accessToken];
    __block YTKRequest *weakAsyncJobResquestAPI = asyncJobRequestAPI;
    [asyncJobRequestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithSuccess:request];
        if (code == ResponseSuccess) {
            if ([request responseData]) {
                if ([request responseJSONObject] && [[request responseJSONObject] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = [request responseJSONObject];
                    if ([[dict allKeys] containsObject:@".tag"]) {
                        if ([[dict objectForKey:@".tag"] isEqualToString:@"in_progress"]) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [self copyMultipleToNewParentCheck:asyncJobID success:success fail:fail];
                            });
                        }else if ([[dict objectForKey:@".tag"] isEqualToString:@"failed"]) {
                            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                            fail?fail(response):nil;
                            [response release];
                        }else {
                            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                            success?success(response):nil;
                            [response release];
                        }
                    }
                }
            }
        }
        [weakAsyncJobResquestAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithFailed:request];
        NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
        NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
        DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
        fail?fail(response):nil;
        [response release];
        [weakAsyncJobResquestAPI release];
    }];
}

- (void)reName:(NSString *)newName idOrPathArray:(NSArray *)idOrPathArray success:(Callback)success fail:(Callback)fail {
    if ([self isExecute]) {
        if ([idOrPathArray count] > 0) {
            NSDictionary *dict = [idOrPathArray objectAtIndex:0];
            NSString *absolutePath = [dict objectForKey:@"itemIDOrPath"];
            if ([absolutePath rangeOfString:@"/"].location != NSNotFound) {
                newName = [[absolutePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newName];
            }
            BaseDriveAPI *requestAPI = [[DropboxMoveToNewParentAPI alloc] initWithItemID:absolutePath newParentIDOrPath:newName parent:@"" accessToken:_accessToken];
            __block YTKRequest *weakRequestAPI = requestAPI;
            [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithSuccess:request];
                if (code == ResponseSuccess) {
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                    success?success(response):nil;
                    [response release];
                }else {
                    NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                    NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
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
    }
}

- (void)moveToNewParentIDOrPath:(NSString *)newParentIdOrPath idOrPathArray:(NSArray *)idOrPathArray success:(Callback)success fail:(Callback)fail {
    if ([self isExecute]) {
        if ([idOrPathArray count] > 0 && [idOrPathArray count] == 1) {
            YTKRequest *requestAPI = nil;
            for (NSDictionary *itemDict in idOrPathArray) {
                NSString *itemID = [itemDict objectForKey:@"fromItemIDOrPath"];
                NSString *newName = [[itemID componentsSeparatedByString:@"/"] lastObject];
                if ([newParentIdOrPath isEqualToString:@"0"]) {
                    requestAPI = [[DropboxMoveToNewParentAPI alloc] initWithItemID:itemID newParentIDOrPath:newName parent:newParentIdOrPath accessToken:_accessToken];
                }else {
                    requestAPI = [[DropboxMoveToNewParentAPI alloc] initWithItemID:itemID newParentIDOrPath:[newParentIdOrPath stringByAppendingPathComponent:newName] parent:@"" accessToken:_accessToken];
                }
            }
            __block YTKRequest *weakRequest = requestAPI;
            [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithSuccess:request];
                if (code == ResponseSuccess) {
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                    success?success(response):nil;
                    [response release];
                }else {
                    NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                    NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                    fail?fail(response):nil;
                    [response release];
                }
                [weakRequest release];
            } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
                //to do需要更具返回值判断错误
                ResponseCode code = [self checkResponseTypeWithFailed:request];
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                fail?fail(response):nil;
                [response release];
                [weakRequest release];
            }];
        }else if ([idOrPathArray count] > 0) {
            NSMutableArray *oldIdOrPathsArray = [[NSMutableArray alloc] init];
            NSMutableArray *newIdOrPathsArray = [[NSMutableArray alloc] init];
            for (NSDictionary *itemDict in idOrPathArray ) {
                NSString *itemID = [itemDict objectForKey:@"fromItemIDOrPath"];
                NSString *newName = [[itemID componentsSeparatedByString:@"/"] lastObject];
                [oldIdOrPathsArray addObject:itemID];
                if ([newParentIdOrPath isEqualToString:@"0"]) {
                    [newIdOrPathsArray addObject:newName];
                }else {
                    [newIdOrPathsArray addObject:[newParentIdOrPath stringByAppendingPathComponent:newName]];
                }
            }
            YTKRequest *requestAPI= nil;
            if ([newParentIdOrPath isEqualToString:@"0"]) {
                requestAPI = [[DropboxMoveMultipleToNewParentAPI alloc] initWithItemsID:oldIdOrPathsArray newParentIDOrPath:newIdOrPathsArray parent:newParentIdOrPath accessToken:_accessToken];
            }else {
                requestAPI = [[DropboxMoveMultipleToNewParentAPI alloc] initWithItemsID:oldIdOrPathsArray newParentIDOrPath:newIdOrPathsArray parent:@"" accessToken:_accessToken];
            }
            [oldIdOrPathsArray release];
            oldIdOrPathsArray = nil;
            [newIdOrPathsArray release];
            newIdOrPathsArray = nil;
            __block YTKRequest *weakRequest = requestAPI;
            [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithSuccess:request];
                if (code == ResponseSuccess) {
                    if ([request responseData]) {
                        if ([request responseJSONObject] && [[request responseJSONObject] isKindOfClass:[NSDictionary class]]) {
                            NSString *asyncJobID = [[request responseJSONObject] objectForKey:@"async_job_id"];
                            [self moveMultipleToNewParentCheck:asyncJobID success:success fail:fail];
                        }
                    }
                }else {
                    NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                    NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                    DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                    fail?fail(response):nil;
                    [response release];
                }
                [weakRequest release];
            } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
                ResponseCode code = [self checkResponseTypeWithFailed:request];
                NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
                NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
                DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
                fail?fail(response):nil;
                [response release];
                [weakRequest release];
            }];
        }
    }
}

- (void)moveMultipleToNewParentCheck:(NSString *)asyncJobID success:(Callback)success fail:(Callback)fail {
    YTKRequest *asyncJobRequestAPI = [[DropboxMoveMultipleToNewParentCheckAPI alloc] initWithItemsAsyncJobID:asyncJobID accessToken:_accessToken];
    __block YTKRequest *weakAsyncJobResquestAPI = asyncJobRequestAPI;
    [asyncJobRequestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithSuccess:request];
        if (code == ResponseSuccess) {
            if ([request responseData]) {
                if ([request responseJSONObject] && [[request responseJSONObject] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = [request responseJSONObject];
                    if ([[dict allKeys] containsObject:@".tag"]) {
                        if ([[dict objectForKey:@".tag"] isEqualToString:@"in_progress"]) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [self moveMultipleToNewParentCheck:asyncJobID success:success fail:fail];
                            });
                        }else if ([[dict objectForKey:@".tag"] isEqualToString:@"failed"]) {
                            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                            fail?fail(response):nil;
                            [response release];
                        }else {
                            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:[request responseData] status:code];
                            success?success(response):nil;
                            [response release];
                        }
                    }
                }
            }
        }
        [weakAsyncJobResquestAPI release];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithFailed:request];
        NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
        NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
        DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
        fail?fail(response):nil;
        [response release];
        [weakAsyncJobResquestAPI release];
    }];
}

#pragma mark - downloadActions

- (void)downloadItem:(_Nonnull id<DownloadAndUploadDelegate>)item
{
    if (item.isFolder) {
        [_folderItemArray addObject:item];
        [(NSObject *)item addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
        [self downloadFolder:item];
    }else {
        if ([self isExecute]) {
            NSString *urlString = [DropboxContentBaseURL stringByAppendingPathComponent:DropboxDownloadFilePath];
            item.urlString = urlString;
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"{\"path\":\"%@\"}",item.itemIDOrPath] ,@"Dropbox-API-Arg",@"application/octet-stream",@"Content-Type", nil];
            [item setHeaderParam:dic];
            item.httpMethod = @"POST";
            [_downLoader downloadItem:item completionHandler:^(NSURL * _Nullable filePath, NSError * _Nullable error) {
                //todo 完成回调
            }];
        }
    }
}

- (void)startDownload:(_Nonnull id <DownloadAndUploadDelegate>)item completionHandler:(nullable void (^)(NSURL * _Nullable filePath, NSError * _Nullable error))completionHandler
{
    NSString *urlString = [DropboxContentBaseURL stringByAppendingPathComponent:DropboxDownloadFilePath];
    item.urlString = urlString;
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"{\"path\":\"%@\"}",item.itemIDOrPath] ,@"Dropbox-API-Arg",@"application/octet-stream",@"Content-Type", nil];
    [item setHeaderParam:dic];
    item.httpMethod = @"POST";
    [_downLoader downloadItem:item completionHandler:completionHandler];
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
            NSArray *sortArray = [item.childArray sortedArrayUsingSelector:@selector(compare:)];
            [sortArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                id <DownloadAndUploadDelegate> childItem = obj;
                childItem.parent = item;
            }];
            dispatch_async(dispatch_get_main_queue(), ^{            
                //设置为等待状态
                item.state = DownloadStateWait;
                if ([sortArray count] > 0) {
                    [self downloadItems:sortArray];
                }else{
                    item.progress = 100;
                    item.state = DownloadStateComplete;
                }
            });
        }
    });
}

- (void)getAllFile:(NSString *)folderID  AllChildArray:(NSMutableArray *)allChildArray parentPath:(NSString *)parentPath
{
    NSDictionary *dic = [self getList:folderID];
    NSString *folderPath = [_downLoader.downloadPath stringByAppendingString:parentPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    //解析列表
    NSMutableArray *childArray = [self parseListDic:dic];
    for (NSDictionary *childDic in childArray) {
        if ([[childDic objectForKey:@"folder"] isEqualToString:@"folder"]) {
            //是文件夹
            NSString *folderID = [childDic objectForKey:@"id"];
            NSString *foderName = [childDic objectForKey:@"name"];
            NSString *path = [parentPath stringByAppendingPathComponent:foderName];
            [self getAllFile:folderID AllChildArray:allChildArray parentPath:path];
        }else{
            //构建downloaditem
            DownLoadAndUploadItem *item = [[DownLoadAndUploadItem alloc] init];
            item.itemIDOrPath = [childDic objectForKey:@"id"];
            item.fileName = [childDic objectForKey:@"name"];
            item.parentPath = parentPath;
            item.fileSize = [[childDic objectForKey:@"size"] longLongValue];
            [allChildArray addObject:item];
            [item release];
        }
    }
}

- (NSMutableArray <NSDictionary *> *)parseListDic:(NSDictionary *)content
{
    NSMutableArray *childArray = [NSMutableArray array];
    NSArray *valueArray = [content objectForKey:@"entries"];
    for (NSDictionary *dic in valueArray) {
        NSMutableDictionary *childDic = [NSMutableDictionary dictionary];
        for (NSString *key in dic.allKeys) {
            if ([key isEqualToString:@"id"]) {
                [childDic setObject:[dic objectForKey:@"id"] forKey:@"id"];
            }else if ([key isEqualToString:@"name"]){
                [childDic setObject:[dic objectForKey:@"name"] forKey:@"name"];
            }else if ([key isEqualToString:@".tag"]){
                [childDic setObject:[dic objectForKey:@".tag"] forKey:@"folder"];
            }else if ([key isEqualToString:@"path_display"]){
                NSString *path = [dic objectForKey:@"path_display"];
                [childDic setObject:path forKey:@"parent"];
            }else if ([key isEqualToString:@"size"]){
                [childDic setObject:[dic objectForKey:@"size"] forKey:@"size"];
            }
        }
        [childArray addObject:childDic];
    }
    return childArray;
}

- (void)uploadItem:(id<DownloadAndUploadDelegate>)item {
    if (item.isFolder) {
        [_folderItemArray addObject:item];
        [(NSObject *)item addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
        [self uploadFolder:item];
    }else {
        [_uploadArray addObject:item];
        item.state = UploadStateWait;
        dispatch_sync(_synchronQueue, ^{
            if ([self isUploadActivityLessMax]) {
                [self startUploadItem:item];
            }
        });
    }
}

- (void)startUploadItem:(_Nonnull id<DownloadAndUploadDelegate>)item
{
    if ([self isExecute]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            @autoreleasepool {
                _activeUploadCount++;
                item.state = UploadStateLoading;
                if (item.parent != nil) {
                    id <DownloadAndUploadDelegate> parentItem = item.parent;
                    parentItem.state = UploadStateLoading;
                }
                __block Dropbox *weakSelf = self;
                __block uint64_t fileSize = 0;
                NSFileManager *fm = [NSFileManager defaultManager];
                if ([fm fileExistsAtPath:[item localPath] isDirectory:NO]) {
                    NSDictionary *attributes = [fm attributesOfItemAtPath:[item localPath] error:nil];
                    if ([[attributes allKeys] containsObject:NSFileSize]) {
                        if ([[attributes objectForKey:NSFileSize] isKindOfClass:[NSNumber class]]) {
                            fileSize = [[attributes objectForKey:NSFileSize] longValue];
                            [item setFileSize:fileSize];
                        }
                    }
                    if (fileSize > 157286400) {
                        YTKRequest *requestAPI = [[DropboxUploadSessionStartAPI alloc] initWithFileName:[item localPath] Parent:@"" accessToken:_accessToken];
                        __block YTKRequest *weakRequestAPI = requestAPI;
                        [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
                            if ([request responseJSONObject] && [[request responseJSONObject] isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *jsonObjectDict = (NSDictionary *)[request responseJSONObject];
                                if ([[jsonObjectDict allKeys] containsObject:@"session_id"]) {
                                    __block NSString *sessionID = [jsonObjectDict objectForKey:@"session_id"];
                                    
                                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                                        @try {
                                            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[item localPath]];
                                            [fileHandle seekToFileOffset:0];
                                            /**
                                             *  fileBlock: 文件块上传的预设值，约定的上传块数必须是10M的倍数
                                             */
                                            long long fileBlock = 10485760;//8388608;
                                            int totalCount = (int)(fileSize / fileBlock);
                                            uint64_t start = 0;
                                            uint64_t end = 0;
                                            [item setCurrentTotalSize:0];
                                            if (fileSize % fileBlock != 0) {
                                                for (int i = 0; i < totalCount; i++) {
                                                    if ([self isExecute]) {
                                                        [item setIsBigFile:YES];
                                                        if (item.state == UploadStateError) {
                                                            break;
                                                        }
                                                        start = i * fileBlock;
                                                        end = fileBlock * i + fileBlock;
                                                        YTKRequest *uploadRequestAPI = [[DropboxUploadSessionAppendAPI alloc] initWithFileName:[item fileName] Parent:[item uploadParent] uploadFile:[item localPath] offset:start sessionID:sessionID accessToken:_accessToken];
                                                        NSData *data = [fileHandle readDataOfLength:fileBlock];
                                                        [uploadRequestAPI setResumableUploadBodyData:data];
                                                        [item setRequestAPI:uploadRequestAPI];
                                                        [fileHandle seekToFileOffset:end];
                                                        [uploadRequestAPI release];
                                                        [_upLoader uploadItem:item success:^(__kindof YTKBaseRequest * _Nonnull request) {
                                                            
                                                        } fail:^(__kindof YTKBaseRequest * _Nonnull request) {
                                                            
                                                        }];
                                                        while ([item isBigFile]) {
                                                            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                                                        }
                                                        
                                                        //请求完成后，检查当前任务状态
                                                        //                                                        [self checkUploadStatus:item];
                                                        if (i == totalCount - 1) {
                                                            break;
                                                        }
                                                    }
                                                }
                                                if ([self isExecute]) {
                                                    if (item.state == UploadStateLoading) {
                                                        [item setIsBigFile:YES];
                                                        long long residualBlock = (fileSize % fileBlock);
                                                        YTKRequest *uploadRequestAPI = [[DropboxUploadSessionFinishAPI alloc] initWithFileName:[item fileName] Parent:[item uploadParent] uploadFile:[item localPath] offset:(fileSize - residualBlock) sessionID:sessionID accessToken:_accessToken];
                                                        [fileHandle seekToEndOfFile];
                                                        [fileHandle seekToFileOffset:([fileHandle offsetInFile] - residualBlock * sizeof(char))];
                                                        NSData *data = [fileHandle readDataToEndOfFile];
                                                        [uploadRequestAPI setResumableUploadBodyData:data];
                                                        [item setRequestAPI:uploadRequestAPI];
                                                        [fileHandle seekToEndOfFile];
                                                        [uploadRequestAPI release];
                                                        [_upLoader uploadItem:item success:^(__kindof YTKBaseRequest * _Nonnull request) {
                                                            
                                                        } fail:^(__kindof YTKBaseRequest * _Nonnull request) {
                                                            
                                                        }];
                                                        while ([item isBigFile]) {
                                                            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                                                        }
                                                        
                                                    }
                                                    
                                                    //请求完成后，检查当前任务状态
                                                    //                                                    [self checkUploadStatus:item];
                                                    
                                                    if (item.state == UploadStateComplete || item.state == UploadStateError) {
                                                        if (item.state == UploadStateComplete) {
                                                            //todo 加跟踪

                                                        }else if (item.state == UploadStateError){
                                                            //todo 加跟踪

                                                        }
                                                        dispatch_sync(_synchronQueue, ^{
                                                            [weakSelf removeUploadTaskForItem:item];
                                                            [weakSelf startNextTaskIfAllow];
                                                        });
                                                    }
                                                }
                                            }else {
                                                YTKRequest *uploadRequestAPI = nil;
                                                for (int i = 0; i < totalCount; i++) {
                                                    if ([self isExecute]) {
                                                        [item setIsBigFile:YES];
                                                        if (item.state == UploadStateError) {
                                                            break;
                                                        }
                                                        start = i * fileBlock;
                                                        end = fileBlock * i + fileBlock;
                                                        if (i == totalCount - 1) {
                                                            uploadRequestAPI = [[DropboxUploadSessionFinishAPI alloc] initWithFileName:[item fileName] Parent:[item uploadParent] uploadFile:[item localPath] offset:start sessionID:sessionID accessToken:_accessToken];
                                                            NSData *data = [fileHandle readDataOfLength:fileBlock];
                                                            [uploadRequestAPI setResumableUploadBodyData:data];
                                                            [fileHandle seekToEndOfFile];
                                                        }else {
                                                            uploadRequestAPI = [[DropboxUploadSessionAppendAPI alloc] initWithFileName:[item fileName] Parent:[item uploadParent] uploadFile:[item localPath] offset:start sessionID:sessionID accessToken:_accessToken];
                                                            NSData *data = [fileHandle readDataOfLength:fileBlock];
                                                            [uploadRequestAPI setResumableUploadBodyData:data];
                                                            [fileHandle seekToFileOffset:end];
                                                        }
                                                        [item setRequestAPI:uploadRequestAPI];
                                                        [uploadRequestAPI release];
                                                        [_upLoader uploadItem:item success:^(__kindof YTKBaseRequest * _Nonnull request) {
                                                            
                                                        } fail:^(__kindof YTKBaseRequest * _Nonnull request) {
                                                            
                                                        }];
                                                        while ([item isBigFile]) {
                                                            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                                                        }
                                                        //请求完成后，检查当前任务状态
                                                        //                                                        [self checkUploadStatus:item];
                                                    }
                                                }
                                                if (item.state == UploadStateComplete || item.state == UploadStateError) {
                                                    if (item.state == UploadStateComplete) {
                                                        //todo 加跟踪

                                                    }else if (item.state == UploadStateError){
                                                        //todo 加跟踪

                                                    }
                                                    dispatch_sync(_synchronQueue, ^{
                                                        [weakSelf removeUploadTaskForItem:item];
                                                        [weakSelf startNextTaskIfAllow];
                                                    });
                                                }
                                            }
                                        } @catch (NSException *exception) {
                                            
                                        } @finally {
                                            
                                        }
                                    });
                                }
                            }
                            [weakRequestAPI release];
                        } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
                            item.state = UploadStateError;
                            //请求完成后，检查当前任务状态
                            dispatch_sync(_synchronQueue, ^{
                                [weakSelf removeUploadTaskForItem:item];
                                [weakSelf startNextTaskIfAllow];
                            });
                            [weakRequestAPI release];
                        }];
                    }else {
                        @try {
                            if ([self isExecute]) {
                                [item setIsBigFile:YES];
                                NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[item localPath]];
                                YTKRequest *requestAPI = [[DropboxUploadAPI alloc] initWithFileName:[item fileName] Parent:[item uploadParent] fileSize:fileSize fileStart:0 fileEnd:(fileSize - 1) accessToken:_accessToken];
                                NSData *data = [fileHandle readDataOfLength:fileSize];
                                [requestAPI setResumableUploadBodyData:data];
                                [item setRequestAPI:requestAPI];
                                [requestAPI release];
                                [_upLoader uploadItem:item success:^(__kindof YTKBaseRequest * _Nonnull request) {
                                    
                                } fail:^(__kindof YTKBaseRequest * _Nonnull request) {
                                    
                                }];
                                while ([item isBigFile]) {
                                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                                }
                                if (item.state == UploadStateComplete || item.state == UploadStateError) {
                                    if (item.state == UploadStateComplete) {
                                        //todo 加跟踪
                                    }else if (item.state == UploadStateError){
                                        //todo 加跟踪
                                    }
                                    dispatch_sync(_synchronQueue, ^{
                                        [weakSelf removeUploadTaskForItem:item];
                                        [weakSelf startNextTaskIfAllow];
                                    });
                                }
                                
                                //请求完成后，检查当前任务状态
                                //                                [self checkUploadStatus:item];
                            }
                        } @catch (NSException *exception) {
                        } @finally {
                        }
                    }
                }
            }
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
            dispatch_async(dispatch_get_main_queue(), ^{
                item.state = UploadStateWait;
                if ([allfileArray count] > 0) {
                    [self uploadItems:allfileArray];
                }else{
                    item.progress = 100;
                    item.state = UploadStateComplete;
                }
            });
        }
    });
}

- (void)createFolder:(NSString *)localPath parent:(NSString *)parent AllChildArray:(NSMutableArray *)allfileArray
{
    NSString *folderName = [localPath lastPathComponent];
    NSDictionary *dic = [self createFolder:folderName parent:parent];
    NSString *subparent = nil;
    if ([[dic allKeys] containsObject:@"metadata"]) {
        NSDictionary *subDic = [dic objectForKey:@"metadata"];
        if ([[subDic allKeys] containsObject:@"path_display"]) {
            subparent = [subDic objectForKey:@"path_display"];
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
            upLoadItme.uploadParent = subparent;
            upLoadItme.fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:sublocalPath error:nil] fileSize];
            [allfileArray addObject:upLoadItme];
            [upLoadItme release];
        }
    }
}

#pragma mark -- 判断当前的Token有效期
- (BOOL)isExecute {
    return YES;
}

#pragma mark -- 刷新令牌状态
- (BOOL)refreshTokenWithDrive {
    __block BOOL result = NO;
    //请求刷新令牌
    if (_userLoginToken) {
        __block BOOL isWait = YES;
        [self refreshToken:_userLoginToken withDriveID:[self driveID] success:^(DriveAPIResponse *response) {
            result = YES;
            isWait = NO;
        } fail:^(DriveAPIResponse *response) {
            result = NO;
            isWait = NO;
        }];
        while (isWait) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        return result;
    }else {
        NSLog(@"用户已退出");
        return result;
    }
}
#pragma mark -- 执行刷新令牌
- (void)refreshToken:(NSString *)token withDriveID:(NSString *)driveID success:(Callback)success fail:(Callback)fail {
    YTKRequest *requestAPI = [[RefreshTokenAPI alloc] initWithUserLoginToken:token withDriveID:driveID];
    __block YTKRequest *weakRequestAPI = requestAPI;
    [requestAPI startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        ResponseCode code = [self checkResponseTypeWithSuccess:request];
        if (code == ResponseSuccess) {
            NSDictionary *tmpDict = nil;
            if ([[request responseJSONObject] isKindOfClass:[NSDictionary class]]) {
                tmpDict = (NSDictionary *)[request responseJSONObject];
                NSString *driveID = [tmpDict objectForKey:@"id"];
                if ([[self driveID] isEqualToString:driveID]) {
                    self.accessToken = [tmpDict objectForKey:@"token"];
                    long longDate = [[tmpDict objectForKey:@"expires_timestamp"] longValue];
                    NSDate *Date = [[NSDate alloc] initWithTimeIntervalSince1970:longDate];
                    self.expirationDate = Date;
                    [self driveSetAccessTokenKey:driveID];
                }
            }
            NSString *codeStr = [[request userInfo] objectForKey:@"AuthValidRefreshToken"];
            NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
            success?success(response):nil;
            [response release];
        }else {
            NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
            NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
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

#pragma mark -- 激活已授权的云服务状态
- (void)driveSetAccessTokenKey:(NSString *)driveIDKey {
    //保存数据到本地
    NSDictionary *dic = [NSDictionary dictionaryWithObject:self.accessToken forKey:kAccessTokenKey];
    [[NSUserDefaults standardUserDefaults] setObject:dic forKey:driveIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -- 取消激活已授权的云服务状态
- (BOOL)driveGetAccessTokenKey:(NSString *)driveIDKey {
    BOOL result = NO;
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] objectForKey:driveIDKey];
    if ([dic objectForKey:kAccessTokenKey]) {
        self.accessToken = [dic objectForKey:kAccessTokenKey];
        result = YES;
    }
    return result;
}

#pragma mark -- 移除已授权的云服务状态
- (void)driveRemoveAccessTokenKey:(NSString *)driveIDKey {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:driveIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self logOut];
}

#pragma mark -- 检查会话请求状态
- (NSString *)checkRequestStatus:(YTKBaseRequest *)request {
    if ([request responseString]) {
        return request.responseString;
    }else {
        NSError *error = [request error];
        return error.localizedDescription;
    }
}

#pragma mark -- 检查下载或者上传文件状态
- (void)checkUploadStatus:(_Nonnull id<DownloadAndUploadDelegate>)item {
    if ([item state] == UploadStateError) {
        if (![[item requestAPI] responseString]) {
            NSError *error = [[item requestAPI] error];
            if ([error code] == NSURLErrorNotConnectedToInternet) {
                @throw [NSException exceptionWithName:@"requestNotConnectedToInternetException" reason:[[[item requestAPI] error] localizedDescription] userInfo:nil];
            }else if ([error code] == NSURLErrorNetworkConnectionLost) {
                @throw [NSException exceptionWithName:@"requestNetworkConnectionLostException" reason:[[[item requestAPI] error] localizedDescription] userInfo:nil];
            }
        }
        @throw [NSException exceptionWithName:@"requestUnKnowException" reason:[[[item requestAPI] error] localizedDescription] userInfo:nil];
    }
}

#pragma mark -- 检查请求响应的数据类型
- (ResponseCode)checkResponseTypeWithSuccess:(YTKBaseRequest * _Nonnull)response {
    if ([response responseData]) {
        if ([response responseJSONObject] && [[response responseJSONObject] isKindOfClass:[NSDictionary class]]) {
            if ([[[response responseJSONObject] allKeys] containsObject:@"url"]) {
                NSString *url = nil;
                url = [[response responseJSONObject] objectForKey:@"url"];
                if (url) {
                    [response setUserInfo:@{@"bindURL": url}];
                }
                return ResponseSuccess;
            }else if ([[[response responseJSONObject] allKeys] containsObject:@"error"]) {
                NSDictionary *errorDict = [[response responseJSONObject] objectForKey:@"error"];
                NSString *errorMessage = nil;
                if ([[errorDict allKeys] containsObject:@"code"]) {
                    NSString *errorStr = [errorDict objectForKey:@"code"];
                    if (errorStr) {
                        errorMessage = [errorDict objectForKey:@"message"];
                    }else {
                        if ([[errorDict allKeys] containsObject:@"path"]) {
                            NSDictionary *dict = [errorDict objectForKey:@"path"];
                            if ([[dict allKeys] containsObject:@".tag"]) {
                                errorMessage = [dict objectForKey:@".tag"];
                            }
                        }
                    }
                    if ([errorStr rangeOfString:@"InvalidAuthenticationToken"].location != NSNotFound) {
                        if (errorMessage) {
                            [response setUserInfo:@{@"errorMessage": errorMessage}];
                        }
                        return ResponseTokenInvalid;
                    }else if ([errorStr rangeOfString:@"The request timed out."].location != NSNotFound) {
                        if (errorMessage) {
                            [response setUserInfo:@{@"errorMessage": errorMessage}];
                        }
                        return ResponseTimeOut;
                    }else if ([errorStr rangeOfString:@"invalidRequest"].location != NSNotFound) {
                        if (errorMessage) {
                            [response setUserInfo:@{@"errorMessage": errorMessage}];
                        }
                        return ResponseInvalid;
                    }else {
                        if (errorMessage) {
                            [response setUserInfo:@{@"errorMessage": errorMessage}];
                        }
                        return ResponseUnknown;
                    }
                }else if ([[errorDict allKeys] containsObject:@".tag"]) {
                    errorMessage = [errorDict objectForKey:@".tag"];
                    if (errorMessage) {
                        [response setUserInfo:@{@"errorMessage": errorMessage}];
                    }
                    return ResponseUnknown;
                }else {
                    if (errorMessage) {
                        [response setUserInfo:@{@"errorMessage": errorMessage}];
                    }
                    return ResponseUnknown;
                }
                
            }else if ([[[response responseJSONObject] allKeys] containsObject:@"errors"]) {
                NSString *errorMessage = [[response responseJSONObject] objectForKey:@"message"];
                if (errorMessage) {
                    [response setUserInfo:@{@"errorMessage": errorMessage}];
                }
                return ResponseInvalid;
            }else if ([[[response responseJSONObject] allKeys] containsObject:@"expires_in"]) {
                NSString *successStr = [[response responseJSONObject] objectForKey:@"token"];
                self.accessToken = successStr;
                [response setUserInfo:@{@"AuthValidRefreshToken": @"Valid refresh token authorization succeeded"}];
                return ResponseSuccess;
            }else if ([[[response responseJSONObject] allKeys] containsObject:@"token"]) {
                NSString *successStr = [[response responseJSONObject] objectForKey:@"token"];
                self.userLoginToken = successStr;
                [response setUserInfo:@{@"AuthValidToken": @"Valid token authorization succeeded"}];
                return ResponseSuccess;
            }else if ([[[response responseJSONObject] allKeys] containsObject:@"context_info"]) {
                if ([[[response responseJSONObject] allKeys] containsObject:@"message"]) {
                    NSString *errorMessage = [[response responseJSONObject] objectForKey:@"message"];
                    if (errorMessage) {
                        [response setUserInfo:@{@"errorMessage": errorMessage}];
                    }
                }
                return ResponseInvalid;
            }else {
                return ResponseSuccess;
            }
        }else if ([response responseJSONObject] && [[response responseJSONObject] isKindOfClass:[NSArray class]]) {
            return ResponseSuccess;
        }else if ([response responseString] && [[response responseString] isKindOfClass:[NSString class]]) {
            NSString *errorStr = [response responseString];
            if ([errorStr rangeOfString:@"access token"].location != NSNotFound) {
                [response setUserInfo:@{@"errorMessage": @"The given OAuth 2 access token is malformed"}];
                return ResponseTokenInvalid;
            }else if ([errorStr isEqualToString:@""]) {
                return ResponseSuccess;
            }else {
                if (errorStr) {
                    [response setUserInfo:@{@"errorMessage": errorStr}];
                }
                return ResponseUnknown;
            }
        }else {
            return ResponseUnknown;
        }
    }else if ([[response error] localizedDescription]) {
        NSString *errorDescription = [[response error] localizedDescription];
        NSError *errorCode = [response error];
        if ([errorDescription isEqualToString:@"InvalidAuthenticationToken"]) {
            [response setUserInfo:@{@"errorMessage": errorDescription}];
            return ResponseTokenInvalid;
        }else if ([errorDescription isEqualToString:@"invalidRequest"]) {
            [response setUserInfo:@{@"errorMessage": errorDescription}];
            return ResponseInvalid;
        }else if (errorCode.code == -1001) {
            [response setUserInfo:@{@"errorMessage": errorDescription}];
            return ResponseTimeOut;
        }else if (errorCode.code == -1009) {
            [response setUserInfo:@{@"errorMessage": errorDescription}];
            return ResponseNotConnectedToInternet;
        }else if (errorCode.code == -1005) {
            [response setUserInfo:@{@"errorMessage": errorDescription}];
            return ResponseNetworkConnectionLost;
        }else {
            return ResponseUnknown;
        }
    }else {
        return ResponseUnknown;
    }
}
@end