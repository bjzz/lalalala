//
//  CommitmentTypeQualifier.h
//  crypto
//
//  Created by JGehry on 7/6/16.
//  Copyright (c) 2016 pallas. All rights reserved.
//

#import "ASN1Object.h"
#import "ASN1ObjectIdentifier.h"
#import "ASN1Encodable.h"

@interface CommitmentTypeQualifier : ASN1Object {
@private
    ASN1ObjectIdentifier *_commitmentTypeIdentifier;
    ASN1Encodable *_qualifier;
}

+ (CommitmentTypeQualifier *)getInstance:(id)paramObject;
- (instancetype)initParamASN1ObjectIdentifier:(ASN1ObjectIdentifier *)paramASN1ObjectIdentifier;
- (instancetype)initParamASN1ObjectIdentifier:(ASN1ObjectIdentifier *)paramASN1ObjectIdentifier paramASN1Encodable:(ASN1Encodable *)paramASN1Encodable;
- (ASN1ObjectIdentifier *)getCommitmentTypeIdentifier;
- (ASN1Encodable *)getQualifier;
- (ASN1Primitive *)toASN1Primitive;

@end
