//
//  CollectionShare.m
//  AnyTransforCloud
//
//  Created by JGehry on 2018/4/27.
//  Copyright © 2018 IMB. All rights reserved.
//

#import "CollectionShare.h"
#import "GetCollectionShareListAPI.h"
#import "AdditionalCollectionShareAPI.h"
#import "RemoveCollectionShareAPI.h"

@implementation CollectionShare

- (void)getListWithPageLimit:(int)pageLimit withPageIndex:(int)pageIndex success:(Callback)success fail:(Callback)fail {
    YTKRequest *requestAPI = [[GetCollectionShareListAPI alloc] initWithItemLimit:pageLimit withPageIndex:pageIndex userLoginToken:_userLoginToken];
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

- (void)addShareToCollection:(NSArray *)shareIDArray success:(Callback)success fail:(Callback)fail {
    if ([shareIDArray count] > 0) {
        NSMutableArray *mutRequestArray = [[NSMutableArray alloc] init];
        YTKRequest *requestAPI = nil;
        for (NSDictionary *itemDict in shareIDArray) {
            NSString *itemID = [itemDict objectForKey:@"shareID"];
            requestAPI = [[AdditionalCollectionShareAPI alloc] initWithShareID:itemID userLoginToken:_userLoginToken];
            [mutRequestArray addObject:requestAPI];
            [requestAPI release];
            requestAPI = nil;
        }
        YTKBatchRequest *batchRequestAPI = [[YTKBatchRequest alloc] initWithRequestArray:mutRequestArray];
        [mutRequestArray release];
        mutRequestArray = nil;
        __block YTKBatchRequest *weakBatchRequestAPI = batchRequestAPI;
        [batchRequestAPI startWithCompletionBlockWithSuccess:^(YTKBatchRequest * _Nonnull batchRequest) {
            YTKRequest *request = [batchRequest.requestArray lastObject];
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
            [weakBatchRequestAPI release];
        } failure:^(YTKBatchRequest * _Nonnull batchRequest) {
            //to do需要更具返回值判断错误
            YTKRequest *request = [batchRequest failedRequest];
            ResponseCode code = [self checkResponseTypeWithFailed:request];
            NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
            NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
            fail?fail(response):nil;
            [response release];
            [weakBatchRequestAPI release];
        }];
    }
}

- (void)deleteCollectionOrShareID:(NSArray *)collectionOrShareIDArray success:(Callback)success fail:(Callback)fail {
    if ([collectionOrShareIDArray count] > 0) {
        NSMutableArray *mutRequestArray = [[NSMutableArray alloc] init];
        YTKRequest *requestAPI = nil;
        for (NSDictionary *itemDict in collectionOrShareIDArray) {
            NSString *itemID = [itemDict objectForKey:@"collectionOrShareID"];
            requestAPI = [[RemoveCollectionShareAPI alloc] initWithCollectionShareID:itemID userLoginToken:_userLoginToken];
            [mutRequestArray addObject:requestAPI];
            [requestAPI release];
            requestAPI = nil;
        }
        YTKBatchRequest *batchRequestAPI = [[YTKBatchRequest alloc] initWithRequestArray:mutRequestArray];
        [mutRequestArray release];
        mutRequestArray = nil;
        __block YTKBatchRequest *weakBatchRequestAPI = batchRequestAPI;
        [batchRequestAPI startWithCompletionBlockWithSuccess:^(YTKBatchRequest * _Nonnull batchRequest) {
            YTKRequest *request = [batchRequest.requestArray lastObject];
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
            [weakBatchRequestAPI release];
        } failure:^(YTKBatchRequest * _Nonnull batchRequest) {
            //to do需要更具返回值判断错误
            YTKRequest *request = [batchRequest failedRequest];
            ResponseCode code = [self checkResponseTypeWithFailed:request];
            NSString *codeStr = [[request userInfo] objectForKey:@"errorMessage"];
            NSData *data = [codeStr dataUsingEncoding:NSUTF8StringEncoding];
            DriveAPIResponse *response = [[DriveAPIResponse alloc] initWithResponseData:data status:code];
            fail?fail(response):nil;
            [response release];
            [weakBatchRequestAPI release];
        }];
    }
}

@end
