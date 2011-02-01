//
//  MPOAuthCredentialConcreteStore.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.11.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPOAuthCredentialConcreteStore.h"
#import "MPURLRequestParameter.h"

#import "MPOAuthCredentialConcreteStore+KeychainAdditions.h"
#import "NSString+URLEscapingAdditions.h"

extern NSString * const MPOAuthCredentialRequestTokenKey;
extern NSString * const MPOAuthCredentialRequestTokenSecretKey;
extern NSString * const MPOAuthCredentialAccessTokenKey;
extern NSString * const MPOAuthCredentialAccessTokenSecretKey;
extern NSString * const MPOAuthCredentialSessionHandleKey;

@implementation MPOAuthCredentialConcreteStore

- (id)initWithCredentials:(NSDictionary *)inCredentials {
    return [self initWithCredentials:inCredentials forBaseURL:nil];
}

- (id)initWithCredentials:(NSDictionary *)inCredentials forBaseURL:(NSURL *)inBaseURL {
	return [self initWithCredentials:inCredentials forBaseURL:inBaseURL withAuthenticationURL:inBaseURL];
}

- (id)initWithCredentials:(NSDictionary *)inCredentials forBaseURL:(NSURL *)inBaseURL withAuthenticationURL:(NSURL *)inAuthenticationURL {
	if (self = [super init]) {
		store = [[NSMutableDictionary alloc] initWithDictionary:inCredentials];
		[self setBaseURL:inBaseURL];
		[self setAuthenticationURL:inAuthenticationURL];
    }
	return self;
}

- (oneway void)dealloc {
	[store release];
	[baseURL release];
	[authenticationURL release];
	[super dealloc];
}

- (void)setStore:(NSMutableDictionary *)theStore {
	[store release];
	store = [theStore retain];
}
- (NSMutableDictionary *)store {
	return store;
}
- (void)setBaseURL:(NSURL *)theURL {
	[baseURL release];
	baseURL = [theURL retain];
}
- (NSURL *)baseURL {
	return baseURL;
}
- (void)setAuthenticationURL:(NSURL *)theURL {
	[authenticationURL release];
	authenticationURL = [theURL retain];
}
- (NSURL *)authenticationURL {
	return authenticationURL;
}

#pragma mark -

- (NSString *)consumerKey {
	return [store objectForKey:kMPOAuthCredentialConsumerKey];
}

- (NSString *)consumerSecret {
	return [store objectForKey:kMPOAuthCredentialConsumerSecret];
}

- (NSString *)username {
	return [store objectForKey:kMPOAuthCredentialUsername];
}

- (NSString *)password {
	return [store objectForKey:kMPOAuthCredentialPassword];
}

- (NSString *)requestToken {
	return [store objectForKey:kMPOAuthCredentialRequestToken];
}

- (void)setRequestToken:(NSString *)inToken {
	if (inToken) {
		[store setObject:inToken forKey:kMPOAuthCredentialRequestToken];
	} else {
		[store removeObjectForKey:kMPOAuthCredentialRequestToken];
		[self removeValueFromKeychainUsingName:kMPOAuthCredentialRequestToken];
	}
}

- (NSString *)requestTokenSecret {
	return [store objectForKey:kMPOAuthCredentialRequestTokenSecret];
}

- (void)setRequestTokenSecret:(NSString *)inTokenSecret {
	if (inTokenSecret) {
		[store setObject:inTokenSecret forKey:kMPOAuthCredentialRequestTokenSecret];
	} else {
		[store removeObjectForKey:kMPOAuthCredentialRequestTokenSecret];
		[self removeValueFromKeychainUsingName:kMPOAuthCredentialRequestTokenSecret];
	}	
}

- (NSString *)accessToken {
	return [store objectForKey:kMPOAuthCredentialAccessToken];
}

- (void)setAccessToken:(NSString *)inToken {
	if (inToken) {
		[store setObject:inToken forKey:kMPOAuthCredentialAccessToken];
	} else {
		[store removeObjectForKey:kMPOAuthCredentialAccessToken];
		[self removeValueFromKeychainUsingName:kMPOAuthCredentialAccessToken];
	}	
}

- (NSString *)accessTokenSecret {
	return [store objectForKey:kMPOAuthCredentialAccessTokenSecret];
}

- (void)setAccessTokenSecret:(NSString *)inTokenSecret {
	if (inTokenSecret) {
		[store setObject:inTokenSecret forKey:kMPOAuthCredentialAccessTokenSecret];
	} else {
		[store removeObjectForKey:kMPOAuthCredentialAccessTokenSecret];
		[self removeValueFromKeychainUsingName:kMPOAuthCredentialAccessTokenSecret];
	}	
}

- (NSString *)sessionHandle {
	return [store objectForKey:kMPOAuthCredentialSessionHandle];
}

- (void)setSessionHandle:(NSString *)inSessionHandle {
	if (inSessionHandle) {
		[store setObject:inSessionHandle forKey:kMPOAuthCredentialSessionHandle];
	} else {
		[store removeObjectForKey:kMPOAuthCredentialSessionHandle];
		[self removeValueFromKeychainUsingName:kMPOAuthCredentialSessionHandle];
	}
}

#pragma mark -

- (NSString *)credentialNamed:(NSString *)inCredentialName {
	return [store objectForKey:inCredentialName];
}

- (void)setCredential:(id)inCredential withName:(NSString *)inName {
	[store setObject:inCredential forKey:inName];
	[self addToKeychainUsingName:inName andValue:inCredential];
}

- (void)removeCredentialNamed:(NSString *)inName {
	[store removeObjectForKey:inName];
	[self removeValueFromKeychainUsingName:inName];
}

- (void)discardOAuthCredentials {
	[self setRequestToken:nil];
	[self setRequestTokenSecret:nil];
	[self setAccessToken:nil];
	[self setAccessTokenSecret:nil];
	[self setSessionHandle:nil];
}

#pragma mark -

- (NSString *)tokenSecret {
	NSString *tokenSecret = @"";
	
	if ([self accessToken]) {
		tokenSecret = [self accessTokenSecret];
	} else if ([self requestToken]) {
		tokenSecret = [self requestTokenSecret];
	}
	
	return tokenSecret;
}

- (NSString *)signingKey {
	NSString *consumerSecret = [[self consumerSecret] stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *tokenSecret = [[self tokenSecret] stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	return [NSString stringWithFormat:@"%@%&%@", consumerSecret, tokenSecret];
}

#pragma mark -

- (NSString *)timestamp {
	return [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
}

- (NSString *)signatureMethod {
	return [store objectForKey:kMPOAuthSignatureMethod];
}

- (NSArray *)oauthParameters {
	NSMutableArray *oauthParameters = [[NSMutableArray alloc] initWithCapacity:5];	
	MPURLRequestParameter *tokenParameter = [self oauthTokenParameter];
	
	[oauthParameters addObject:[self oauthConsumerKeyParameter]];
	if (tokenParameter) [oauthParameters addObject:tokenParameter];
	[oauthParameters addObject:[self oauthSignatureMethodParameter]];
	[oauthParameters addObject:[self oauthTimestampParameter]];
	[oauthParameters addObject:[self oauthNonceParameter]];
	[oauthParameters addObject:[self oauthVersionParameter]];
	
	return [oauthParameters autorelease];
}

- (void)setSignatureMethod:(NSString *)inSignatureMethod {
	[store setObject:inSignatureMethod forKey:kMPOAuthSignatureMethod];
}

- (MPURLRequestParameter *)oauthConsumerKeyParameter {
	MPURLRequestParameter *aRequestParameter = [[MPURLRequestParameter alloc] init];
	aRequestParameter.name = @"oauth_consumer_key";
	aRequestParameter.value = [self consumerKey];
	
	return [aRequestParameter autorelease];
}

- (MPURLRequestParameter *)oauthTokenParameter {
	MPURLRequestParameter *aRequestParameter = nil;
	
	if ([self accessToken] || [self requestToken]) {
		aRequestParameter = [[MPURLRequestParameter alloc] init];
		aRequestParameter.name = @"oauth_token";
		
		if ([self accessToken]) {
			aRequestParameter.value = [self accessToken];
		} else if ([self requestToken]) {
			aRequestParameter.value = [self requestToken];
		}
	}
	
	return [aRequestParameter autorelease];
}

- (MPURLRequestParameter *)oauthSignatureMethodParameter {
	MPURLRequestParameter *aRequestParameter = [[MPURLRequestParameter alloc] init];
	aRequestParameter.name = @"oauth_signature_method";
	aRequestParameter.value = [self signatureMethod];
	
	return [aRequestParameter autorelease];
}

- (MPURLRequestParameter *)oauthTimestampParameter {
	MPURLRequestParameter *aRequestParameter = [[MPURLRequestParameter alloc] init];
	aRequestParameter.name = @"oauth_timestamp";
	aRequestParameter.value = [self timestamp];
	
	return [aRequestParameter autorelease];
}

- (MPURLRequestParameter *)oauthNonceParameter {
	MPURLRequestParameter *aRequestParameter = [[MPURLRequestParameter alloc] init];
	aRequestParameter.name = @"oauth_nonce";
	
	NSString *generatedNonce = nil;
	CFUUIDRef generatedUUID = CFUUIDCreate(kCFAllocatorDefault);
	
	generatedNonce = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, generatedUUID);
	CFRelease(generatedUUID);
	
	aRequestParameter.value = generatedNonce;
	[generatedNonce release];
	
	return [aRequestParameter autorelease];
}

- (MPURLRequestParameter *)oauthVersionParameter {
	MPURLRequestParameter *versionParameter = [store objectForKey:@"versionParameter"];
	
	if (!versionParameter) {
		versionParameter = [[MPURLRequestParameter alloc] init];
		versionParameter.name = @"oauth_version";
		versionParameter.value = @"1.0";
		[versionParameter autorelease];
	}
	
	return versionParameter;
}

@end
