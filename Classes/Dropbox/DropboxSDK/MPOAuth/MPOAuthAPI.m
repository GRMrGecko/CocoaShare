//
//  MPOAuthAPI.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPOAuthAPIRequestLoader.h"
#import "MPOAuthAPI.h"
#import "MPOAuthCredentialConcreteStore.h"
#import "MPOAuthURLRequest.h"
#import "MPOAuthURLResponse.h"
#import "MPURLRequestParameter.h"
#import "MPOAuthAuthenticationMethod.h"

#import "NSURL+MPURLParameterAdditions.h"

NSString *kMPOAuthCredentialConsumerKey				= @"kMPOAuthCredentialConsumerKey";
NSString *kMPOAuthCredentialConsumerSecret			= @"kMPOAuthCredentialConsumerSecret";
NSString *kMPOAuthCredentialUsername				= @"kMPOAuthCredentialUsername";
NSString *kMPOAuthCredentialPassword				= @"kMPOAuthCredentialPassword";
NSString *kMPOAuthCredentialRequestToken			= @"kMPOAuthCredentialRequestToken";
NSString *kMPOAuthCredentialRequestTokenSecret		= @"kMPOAuthCredentialRequestTokenSecret";
NSString *kMPOAuthCredentialAccessToken				= @"kMPOAuthCredentialAccessToken";
NSString *kMPOAuthCredentialAccessTokenSecret		= @"kMPOAuthCredentialAccessTokenSecret";
NSString *kMPOAuthCredentialSessionHandle			= @"kMPOAuthCredentialSessionHandle";

NSString *kMPOAuthSignatureMethod					= @"kMPOAuthSignatureMethod";
NSString * const MPOAuthTokenRefreshDateDefaultsKey		= @"MPOAuthAutomaticTokenRefreshLastExpiryDate";

@interface MPOAuthAPI ()
- (void)performMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction usingHTTPMethod:(NSString *)inHTTPMethod;
@end

@implementation MPOAuthAPI

- (id)initWithCredentials:(NSDictionary *)inCredentials andBaseURL:(NSURL *)inBaseURL {
	return [self initWithCredentials:inCredentials authenticationURL:inBaseURL andBaseURL:inBaseURL];
}

- (id)initWithCredentials:(NSDictionary *)inCredentials authenticationURL:(NSURL *)inAuthURL andBaseURL:(NSURL *)inBaseURL {
	return [self initWithCredentials:inCredentials authenticationURL:inBaseURL andBaseURL:inBaseURL autoStart:YES];	
}

- (id)initWithCredentials:(NSDictionary *)inCredentials authenticationURL:(NSURL *)inAuthURL andBaseURL:(NSURL *)inBaseURL autoStart:(BOOL)aFlag {
	if (self = [super init]) {
		[self setAuthenticationURL:inAuthURL];
		[self setBaseURL:inBaseURL];
		[self setAuthenticationState:MPOAuthAuthenticationStateUnauthenticated];
		credentials = [[MPOAuthCredentialConcreteStore alloc] initWithCredentials:inCredentials forBaseURL:inBaseURL withAuthenticationURL:inAuthURL];
		[self setAuthenticationMethod:[[MPOAuthAuthenticationMethod alloc] initWithAPI:self forURL:inAuthURL]];
		[self setSignatureScheme:MPOAuthSignatureSchemeHMACSHA1];

		activeLoaders = [[NSMutableArray alloc] initWithCapacity:10];
		
		if (aFlag) {
			[self authenticate];
		}
	}
	return self;	
}

- (oneway void)dealloc {
	[credentials release];
	[baseURL release];
	[authenticationURL release];
	[authenticationMethod release];
	[activeLoaders release];
	
	[super dealloc];
}

- (void)setCredentials:(id)theCredentials {
	credentials = theCredentials;
}
- (id<MPOAuthCredentialStore,MPOAuthParameterFactory>)credentials {
	return credentials;
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
- (void)setAuthenticationMethod:(MPOAuthAuthenticationMethod *)theMethod {
	[authenticationMethod release];
	authenticationMethod = [theMethod retain];
}
- (MPOAuthAuthenticationMethod *)authenticationMethod {
	return authenticationMethod;
}
- (void)setSignatureScheme:(MPOAuthSignatureScheme)theScheme {
	signatureScheme = theScheme;
	
	NSString *methodString = @"HMAC-SHA1";
	
	switch (signatureScheme) {
		case MPOAuthSignatureSchemePlainText:
			methodString = @"PLAINTEXT";
			break;
		case MPOAuthSignatureSchemeRSASHA1:
			methodString = @"RSA-SHA1";
		case MPOAuthSignatureSchemeHMACSHA1:
		default:
			// already initted to the default
			break;
	}
	
	[(MPOAuthCredentialConcreteStore *)credentials setSignatureMethod:methodString];
}
- (MPOAuthSignatureScheme)signatureScheme {
	return signatureScheme;
}

- (void)setAuthenticationState:(MPOAuthAuthenticationState)theState {
	oauthAuthenticationState = theState;
}
- (MPOAuthAuthenticationState)authenticationState {
	return oauthAuthenticationState;
}

- (void)setActiveLoaders:(NSMutableArray *)theLoaders {
	[activeLoaders release];
	activeLoaders = [theLoaders retain];
}
- (NSMutableArray *)activeLoaders {
	return activeLoaders;
}

#pragma mark -

- (void)authenticate {
	NSAssert([credentials consumerKey], @"A Consumer Key is required for use of OAuth.");
	[authenticationMethod authenticate];
}

- (BOOL)isAuthenticated {
	return ([self authenticationState] == MPOAuthAuthenticationStateAuthenticated);
}

#pragma mark -

- (void)performMethod:(NSString *)inMethod withTarget:(id)inTarget andAction:(SEL)inAction {
	[self performMethod:inMethod atURL:baseURL withParameters:nil withTarget:inTarget andAction:inAction usingHTTPMethod:@"GET"];
}

- (void)performMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction {
	[self performMethod:inMethod atURL:inURL withParameters:inParameters withTarget:inTarget andAction:inAction usingHTTPMethod:@"GET"];
}

- (void)performPOSTMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction {
	[self performMethod:inMethod atURL:inURL withParameters:inParameters withTarget:inTarget andAction:inAction usingHTTPMethod:@"POST"];
}

- (void)performMethod:(NSString *)inMethod atURL:(NSURL *)inURL withParameters:(NSArray *)inParameters withTarget:(id)inTarget andAction:(SEL)inAction usingHTTPMethod:(NSString *)inHTTPMethod {
	if (!inMethod && ![inURL path] && ![inURL query]) {
		[NSException raise:@"MPOAuthNilMethodRequestException" format:@"Nil was passed as the method to be performed on %@", inURL];
	}
	
	NSURL *requestURL = inMethod ? [NSURL URLWithString:inMethod relativeToURL:inURL] : inURL;
	MPOAuthURLRequest *aRequest = [[MPOAuthURLRequest alloc] initWithURL:requestURL andParameters:inParameters];
	MPOAuthAPIRequestLoader *loader = [[MPOAuthAPIRequestLoader alloc] initWithRequest:aRequest];
	
	aRequest.HTTPMethod = inHTTPMethod;
	loader.credentials = credentials;
	loader.target = inTarget;
	loader.action = inAction ? inAction : @selector(_performedLoad:receivingData:);
	
	[loader loadSynchronously:NO];
	//	[activeLoaders addObject:loader];
	
	[loader release];
	[aRequest release];
}

- (void)performURLRequest:(NSURLRequest *)inRequest withTarget:(id)inTarget andAction:(SEL)inAction {
	if (!inRequest && ![[inRequest URL] path] && ![[inRequest URL] query]) {
		[NSException raise:@"MPOAuthNilMethodRequestException" format:@"Nil was passed as the method to be performed on %@", inRequest];
	}

	MPOAuthURLRequest *aRequest = [[MPOAuthURLRequest alloc] initWithURLRequest:inRequest];
	MPOAuthAPIRequestLoader *loader = [[MPOAuthAPIRequestLoader alloc] initWithRequest:aRequest];
	
	loader.credentials = credentials;
	loader.target = inTarget;
	loader.action = inAction ? inAction : @selector(_performedLoad:receivingData:);
	
	[loader loadSynchronously:NO];
	//	[activeLoaders addObject:loader];
	
	[loader release];
	[aRequest release];	
}

- (NSData *)dataForMethod:(NSString *)inMethod {
	return [self dataForURL:baseURL andMethod:inMethod withParameters:nil];
}

- (NSData *)dataForMethod:(NSString *)inMethod withParameters:(NSArray *)inParameters {
	return [self dataForURL:baseURL andMethod:inMethod withParameters:inParameters];
}

- (NSData *)dataForURL:(NSURL *)inURL andMethod:(NSString *)inMethod withParameters:(NSArray *)inParameters {
	NSURL *requestURL = [NSURL URLWithString:inMethod relativeToURL:inURL];
	MPOAuthURLRequest *aRequest = [[MPOAuthURLRequest alloc] initWithURL:requestURL andParameters:inParameters];
	MPOAuthAPIRequestLoader *loader = [[MPOAuthAPIRequestLoader alloc] initWithRequest:aRequest];

	loader.credentials = credentials;
	[loader loadSynchronously:YES];
	
	[loader autorelease];
	[aRequest release];
	
	return loader.data;
}

#pragma mark -

- (id)credentialNamed:(NSString *)inCredentialName {
	return [credentials credentialNamed:inCredentialName];
}

- (void)setCredential:(id)inCredential withName:(NSString *)inName {
	[(MPOAuthCredentialConcreteStore *)credentials setCredential:inCredential withName:inName];
}

- (void)removeCredentialNamed:(NSString *)inName {
	[(MPOAuthCredentialConcreteStore *)credentials removeCredentialNamed:inName];
}

- (void)discardCredentials {
	[credentials discardOAuthCredentials];
	
	[self setAuthenticationState:MPOAuthAuthenticationStateUnauthenticated];
}

#pragma mark -
#pragma mark - Private APIs -

- (void)_performedLoad:(MPOAuthAPIRequestLoader *)inLoader receivingData:(NSData *)inData {
//	NSLog(@"loaded %@, and got %@", inLoader, inData);
}

@end
