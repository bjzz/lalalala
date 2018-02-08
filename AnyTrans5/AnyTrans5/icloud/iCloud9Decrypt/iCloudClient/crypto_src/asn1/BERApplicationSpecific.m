//
//  BERApplicationSpecific.m
//  crypto
//
//  Created by JGehry on 6/13/16.
//  Copyright (c) 2016 pallas. All rights reserved.
//

#import "BERApplicationSpecific.h"
#import "Arrays.h"

@implementation BERApplicationSpecific

+ (NSMutableData *)getEncoding:(BOOL)paramBoolean paramASN1Encodable:(ASN1Encodable *)paramASN1Encodable {
    NSMutableData *arrayOfByte1 = [[paramASN1Encodable toASN1Primitive] getEncoded:@"BER"];
    if (paramBoolean) {
        return arrayOfByte1;
    }
    int i = [self getLengthOfHeader:arrayOfByte1];
    NSMutableData *arrayOfByte2 = [[[NSMutableData alloc] initWithSize:(int)arrayOfByte1.length - i] autorelease];
    [arrayOfByte2 copyFromIndex:0 withSource:arrayOfByte1 withSourceIndex:i withLength:(int)[arrayOfByte2 length]];
    return arrayOfByte2;
}

+ (NSMutableData *)getEncodedVector:(ASN1EncodableVector *)paramASN1EncodableVector {
    MemoryStreamEx *localMemoryStream = [MemoryStreamEx memoryStreamEx];
    for (int i = 0; i != [paramASN1EncodableVector size]; i++) {
        @try {
            [localMemoryStream write:[((ASN1Object *)[paramASN1EncodableVector get:i]) getEncoded:@"BER"]];
        }
        @catch (NSException *exception) {
            @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"malformed object: %@%@", exception.description, exception.description] userInfo:nil];
        }
    }
    NSMutableData *data = [localMemoryStream availableData];
    NSMutableData *retData = nil;
    if (data) {
        retData = [Arrays copyOfWithData:data withNewLength:(int)[data length]];
    }
    return (retData ? [retData autorelease] : nil);
}

- (instancetype)initParamBoolean:(BOOL)paramBoolean paramInt:(int)paramInt paramArrayOfByte:(NSMutableData *)paramArrayOfByte
{
    if (self = [super initParamBoolean:paramBoolean paramInt:paramInt paramArrayOfByte:paramArrayOfByte]) {
        return self;
    }else {
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
}

- (instancetype)initParamInt:(int)paramInt paramASN1Encodable:(ASN1Encodable *)paramASN1Encodable
{
    if (self = [super init]) {
        [self initParamBoolean:YES paramInt:paramInt paramASN1Encodable:paramASN1Encodable];
        return self;
    }else {
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
}

- (instancetype)initParamBoolean:(BOOL)paramBoolean paramInt:(int)paramInt paramASN1Encodable:(ASN1Encodable *)paramASN1Encodable
{
    self = [super initParamBoolean:((paramBoolean) || ([[paramASN1Encodable toASN1Primitive] isConstructed])) paramInt:paramInt paramArrayOfByte:[BERApplicationSpecific getEncoding:paramBoolean paramASN1Encodable:paramASN1Encodable]];
    if (self) {
    }
    return self;
}

- (instancetype)initParamInt:(int)paramInt paramASN1EncodableVector:(ASN1EncodableVector *)paramASN1EncodableVector
{
    if (self = [super initParamBoolean:YES paramInt:paramInt paramArrayOfByte:[BERApplicationSpecific getEncodedVector:paramASN1EncodableVector]]) {
        return self;
    }else {
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
}

- (void)encode:(ASN1OutputStream *)paramASN1OutputStream {
    int i = 64;
    if (self.isConstructed) {
        i = i | 0x20;
    }
    [paramASN1OutputStream writeTag:i paramInt2:self.tag];
    [paramASN1OutputStream write:128];
    [paramASN1OutputStream writeParamArrayOfByte:self.octets];
    [paramASN1OutputStream write:0];
    [paramASN1OutputStream write:0];
}

@end
