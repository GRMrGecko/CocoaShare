//
//  MPOAuthParameterFactory.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.06.
//  Copyright 2008 matrixPointer. All rights reserved.
//

extern NSString *kMPOAuthSignatureMethod;

@class MPURLRequestParameter;

@protocol MPOAuthParameterFactory <NSObject>

- (void)setSignatureMethod:(NSString *)theMethod;
- (NSString *)signatureMethod;
- (NSString *)signingKey;
- (NSString *)timestamp;

- (NSArray *)oauthParameters;

- (MPURLRequestParameter *)oauthConsumerKeyParameter;
- (MPURLRequestParameter *)oauthTokenParameter;
- (MPURLRequestParameter *)oauthSignatureMethodParameter;
- (MPURLRequestParameter *)oauthTimestampParameter;
- (MPURLRequestParameter *)oauthNonceParameter;
- (MPURLRequestParameter *)oauthVersionParameter;

@end
