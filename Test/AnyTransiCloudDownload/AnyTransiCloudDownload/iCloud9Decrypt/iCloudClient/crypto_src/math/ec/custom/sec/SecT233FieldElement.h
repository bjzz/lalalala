//
//  SecT233FieldElement.h
//  
//
//  Created by Pallas on 5/31/16.
//
//  Complete

#import "ECFieldElement.h"

@class BigInteger;

@interface SecT233FieldElement : ECFieldElement {
@protected
    NSMutableArray *                    _x; // uint64_t[]
}

// return == uint[]
- (NSMutableArray*)x;

- (id)initWithBigInteger:(BigInteger*)x;
- (id)initWithUintArray:(NSMutableArray*)x;

- (int)representation;
- (int)M;
- (int)K1;
- (int)K2;
- (int)K3;

- (BOOL)equalsWithSecT233FieldElement:(SecT233FieldElement*)other;

@end
