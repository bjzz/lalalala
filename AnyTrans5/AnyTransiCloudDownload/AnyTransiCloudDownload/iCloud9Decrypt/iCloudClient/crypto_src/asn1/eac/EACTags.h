//
//  EACTags.h
//  crypto
//
//  Created by JGehry on 7/4/16.
//  Copyright (c) 2016 pallas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASN1ApplicationSpecific.h"

@interface EACTags : NSObject

+ (int)OBJECT_IDENTIFIER;
+ (int)COUNTRY_CODE_NATIONAL_DATA;
+ (int)ISSUER_IDENTIFICATION_NUMBER;
+ (int)CARD_SERVICE_DATA;
+ (int)INITIAL_ACCESS_DATA;
+ (int)CARD_ISSUER_DATA;
+ (int)PRE_ISSUING_DATA;
+ (int)CARD_CAPABILITIES;
+ (int)STATUS_INFORMATION;
+ (int)EXTENDED_HEADER_LIST;
+ (int)APPLICATION_IDENTIFIER;
+ (int)APPLICATION_LABEL;
+ (int)FILE_REFERENCE;
+ (int)COMMAND_TO_PERFORM;
+ (int)DISCRETIONARY_DATA;
+ (int)OFFSET_DATA_OBJECT;
+ (int)TRACK1_APPLICATION;
+ (int)TRACK2_APPLICATION;
+ (int)TRACK3_APPLICATION;
+ (int)CARD_EXPIRATION_DATA;
+ (int)PRIMARY_ACCOUNT_NUMBER;
+ (int)NAME;
+ (int)TAG_LIST;
+ (int)HEADER_LIST;
+ (int)LOGIN_DATA;
+ (int)CARDHOLDER_NAME;
+ (int)TRACK1_CARD;
+ (int)TRACK2_CARD;
+ (int)TRACK3_CARD;
+ (int)APPLICATION_EXPIRATION_DATE;
+ (int)APPLICATION_EFFECTIVE_DATE;
+ (int)CARD_EFFECTIVE_DATE;
+ (int)INTERCHANGE_CONTROL;
+ (int)COUNTRY_CODE;
+ (int)INTERCHANGE_PROFILE;
+ (int)CURRENCY_CODE;
+ (int)DATE_OF_BIRTH;
+ (int)CARDHOLDER_NATIONALITY;
+ (int)LANGUAGE_PREFERENCES;
+ (int)CARDHOLDER_BIOMETRIC_DATA;
+ (int)PIN_USAGE_POLICY;
+ (int)SERVICE_CODE;
+ (int)TRANSACTION_COUNTER;
+ (int)TRANSACTION_DATE;
+ (int)CARD_SEQUENCE_NUMBER;
+ (int)SEX;
+ (int)CURRENCY_EXPONENT;
+ (int)STATIC_INTERNAL_AUTHENTIFICATION_ONE_STEP;
+ (int)SIGNATURE;
+ (int)STATIC_INTERNAL_AUTHENTIFICATION_FIRST_DATA;
+ (int)STATIC_INTERNAL_AUTHENTIFICATION_SECOND_DATA;
+ (int)DYNAMIC_INTERNAL_AUTHENTIFICATION;
+ (int)DYNAMIC_EXTERNAL_AUTHENTIFICATION;
+ (int)DYNAMIC_MUTUAL_AUTHENTIFICATION;
+ (int)CARDHOLDER_PORTRAIT_IMAGE;
+ (int)ELEMENT_LIST;
+ (int)ADDRESS;
+ (int)CARDHOLDER_HANDWRITTEN_SIGNATURE;
+ (int)APPLICATION_IMAGE;
+ (int)DISPLAY_IMAGE;
+ (int)TIMER;
+ (int)MESSAGE_REFERENCE;
+ (int)CARDHOLDER_PRIVATE_KEY;
+ (int)CARDHOLDER_PUBLIC_KEY;
+ (int)CERTIFICATION_AUTHORITY_PUBLIC_KEY;
+ (int)DEPRECATED;
+ (int)CERTIFICATE_HOLDER_AUTHORIZATION;
+ (int)INTEGRATED_CIRCUIT_MANUFACTURER_ID;
+ (int)CERTIFICATE_CONTENT;
+ (int)UNIFORM_RESOURCE_LOCATOR;
+ (int)ANSWER_TO_RESET;
+ (int)HISTORICAL_BYTES;
+ (int)DIGITAL_SIGNATURE;
+ (int)APPLICATION_TEMPLATE;
+ (int)FCP_TEMPLATE;
+ (int)WRAPPER;
+ (int)FMD_TEMPLATE;
+ (int)CARDHOLDER_RELATIVE_DATA;
+ (int)CARD_DATA;
+ (int)AUTHENTIFICATION_DATA;
+ (int)SPECIAL_USER_REQUIREMENTS;
+ (int)LOGIN_TEMPLATE;
+ (int)QUALIFIED_NAME;
+ (int)CARDHOLDER_IMAGE_TEMPLATE;
+ (int)APPLICATION_IMAGE_TEMPLATE;
+ (int)APPLICATION_RELATED_DATA;
+ (int)FCI_TEMPLATE;
+ (int)DISCRETIONARY_DATA_OBJECTS;
+ (int)COMPATIBLE_TAG_ALLOCATION_AUTHORITY;
+ (int)COEXISTANT_TAG_ALLOCATION_AUTHORITY;
+ (int)SECURITY_SUPPORT_TEMPLATE;
+ (int)SECURITY_ENVIRONMENT_TEMPLATE;
+ (int)DYNAMIC_AUTHENTIFICATION_TEMPLATE;
+ (int)SECURE_MESSAGING_TEMPLATE;
+ (int)NON_INTERINDUSTRY_DATA_OBJECT_NESTING_TEMPLATE;
+ (int)DISPLAY_CONTROL;
+ (int)CARDHOLDER_CERTIFICATE;
+ (int)CV_CERTIFICATE;
+ (int)CARDHOLER_REQUIREMENTS_INCLUDED_FEATURES;
+ (int)CARDHOLER_REQUIREMENTS_EXCLUDED_FEATURES;
+ (int)BIOMETRIC_DATA_TEMPLATE;
+ (int)DIGITAL_SIGNATURE_BLOCK;
+ (int)CARDHOLDER_PRIVATE_KEY_TEMPLATE;
+ (int)CARDHOLDER_PUBLIC_KEY_TEMPLATE;
+ (int)CERTIFICATE_HOLDER_AUTHORIZATION_TEMPLATE;
+ (int)CERTIFICATE_CONTENT_TEMPLATE;
+ (int)CERTIFICATE_BODY;
+ (int)BIOMETRIC_INFORMATION_TEMPLATE;
+ (int)BIOMETRIC_INFORMATION_GROUP_TEMPLATE;
+ (int)getTag:(int)paramInt;
+ (int)getTagNo:(int)paramInt;
+ (int)encodeTag:(ASN1ApplicationSpecific *)paramASN1ApplicationSpecific;
+ (int)decodeTag:(int)paramInt;

@end
