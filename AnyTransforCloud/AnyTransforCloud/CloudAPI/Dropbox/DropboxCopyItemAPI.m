//
//  DropboxCopyItemAPI.m
//  DriveSync
//
//  Created by JGehry on 2018/5/3.
//  Copyright © 2018 imobie. All rights reserved.
//

#import "DropboxCopyItemAPI.h"

@implementation DropboxCopyItemAPI

- (NSString *)baseUrl {
    return DropboxAPIBaseURL;
}

- (NSString *)requestUrl {
    return DropboxCopy;
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodPOST;
}

- (id)requestArgument {
    NSString *sourceName = nil;
    NSString *targetName = nil;
    if ([_folderOrfileID rangeOfString:@"id:"].location != NSNotFound) {
        sourceName = [NSString stringWithFormat:@"%@", _folderOrfileID];
    }else {
        if ([_folderOrfileID isEqualToString:@"0"]) {
            sourceName = @"/";
        }else {
            sourceName = [NSString stringWithFormat:@"%@", _folderOrfileID];;
        }
    }
    if ([_newParentIDOrPath rangeOfString:@"id:"].location != NSNotFound) {
        targetName = [NSString stringWithFormat:@"%@", _newParentIDOrPath];
    }else {
        if ([_parent isEqualToString:@"0"]) {
            targetName = [NSString stringWithFormat:@"/%@", _newParentIDOrPath];
        }else {
            targetName = [NSString stringWithFormat:@"%@", _newParentIDOrPath];
        }
    }
    return @{@"from_path": sourceName,
             @"to_path": targetName,
             @"autorename": @YES
             };
}

@end
