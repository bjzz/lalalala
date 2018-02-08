//
//  SecT409K1Point.h
//  
//
//  Created by Pallas on 5/31/16.
//
//  Complete

#import "ECPoint.h"

@interface SecT409K1Point : AbstractF2mPoint

/**
 * @deprecated Use ECCurve.createPoint to construct points
 */
- (id)initWithCurve:(ECCurve*)curve withX:(ECFieldElement*)x withY:(ECFieldElement*)y;

@end
