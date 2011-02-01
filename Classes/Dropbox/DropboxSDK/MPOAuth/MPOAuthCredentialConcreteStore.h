//
//  MPOAuthCredentialConcreteStore.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.11.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPOAuthCredentialStore.h"
#import "MPOAuthParameterFactory.h"

@interface MPOAuthCredentialConcreteStore : NSObject <MPOAuthCredentialStore, MPOAuthParameterFactory> {
	NSMutableDictionary *store;
	NSURL				*baseURL;
	NSURL				*authenticationURL;
}
- (void)setStore:(NSMutableDictionary *)theStore;
- (NSMutableDictionary *)store;
- (void)setBaseURL:(NSURL *)theURL;
- (NSURL *)baseURL;
- (void)setAuthenticationURL:(NSURL *)theURL;
- (NSURL *)authenticationURL;

- (NSString *)tokenSecret;
- (NSString *)signingKey;

- (void)setRequestToken:(NSString *)theToken;
- (NSString *)requestToken;
- (void)setRequestTokenSecret:(NSString *)theSecret;
- (NSString *)requestTokenSecret;
- (void)setAccessToken:(NSString *)theToken;
- (NSString *)accessToken;
- (void)setAccessTokenSecret:(NSString *)theSecret;
- (NSString *)accessTokenSecret;

- (void)setSessionHandle:(NSString *)theHandle;
- (NSString *)sessionHandle;

- (id)initWithCredentials:(NSDictionary *)inCredential;
- (id)initWithCredentials:(NSDictionary *)inCredentials forBaseURL:(NSURL *)inBaseURL;
- (id)initWithCredentials:(NSDictionary *)inCredentials forBaseURL:(NSURL *)inBaseURL withAuthenticationURL:(NSURL *)inAuthenticationURL;

- (void)setCredential:(id)inCredential withName:(NSString *)inName;
- (void)removeCredentialNamed:(NSString *)inName;
	

@end
