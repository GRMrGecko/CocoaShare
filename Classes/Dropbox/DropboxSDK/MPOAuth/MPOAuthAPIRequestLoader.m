//
//  MPOAuthAPIRequestLoader.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPOAuthAPIRequestLoader.h"
#import "MPOAuthURLRequest.h"
#import "MPOAuthURLResponse.h"
#import "MPOAuthConnection.h"
#import "MPOAuthCredentialStore.h"
#import "MPOAuthCredentialConcreteStore.h"
#import "MPURLRequestParameter.h"
#import "NSURLResponse+Encoding.h"
#import "MPDebug.h"

NSString * const MPOAuthNotificationRequestTokenReceived	= @"MPOAuthNotificationRequestTokenReceived";
NSString * const MPOAuthNotificationRequestTokenRejected	= @"MPOAuthNotificationRequestTokenRejected";
NSString * const MPOAuthNotificationAccessTokenReceived		= @"MPOAuthNotificationAccessTokenReceived";
NSString * const MPOAuthNotificationAccessTokenRejected		= @"MPOAuthNotificationAccessTokenRejected";
NSString * const MPOAuthNotificationAccessTokenRefreshed	= @"MPOAuthNotificationAccessTokenRefreshed";
NSString * const MPOAuthNotificationOAuthCredentialsReady	= @"MPOAuthNotificationOAuthCredentialsReady";
NSString * const MPOAuthNotificationErrorHasOccurred		= @"MPOAuthNotificationErrorHasOccurred";

@interface MPOAuthAPIRequestLoader ()
- (void)_interrogateResponseForOAuthData;
@end

@protocol MPOAuthAPIInternalClient;

@implementation MPOAuthAPIRequestLoader

- (id)initWithURL:(NSURL *)inURL {
	return [self initWithRequest:[[[MPOAuthURLRequest alloc] initWithURL:inURL andParameters:nil] autorelease]];
}

- (id)initWithRequest:(MPOAuthURLRequest *)inRequest {
	if (self = [super init]) {
		[self setOauthRequest:inRequest];
		data = [[NSMutableData alloc] init];
	}
	return self;
}

- (oneway void)dealloc {
	[credentials release];
	[oauthRequest release];
	[oauthResponse release];
	[data release];
	[responseString release];

	[super dealloc];
}

- (void)setCredentials:(id)theCredentials {
	[credentials release];
	credentials = [theCredentials retain];
}
- (id<MPOAuthCredentialStore,MPOAuthParameterFactory>)credentials {
	return credentials;
}
- (void)setOauthRequest:(MPOAuthURLRequest *)theRequest {
	[oauthRequest release];
	oauthRequest = [theRequest retain];
}
- (MPOAuthURLRequest *)oauthRequest {
	return oauthRequest;
}
- (void)setOauthResponse:(MPOAuthURLResponse *)theResponse {
	[oauthResponse release];
	oauthResponse = [theResponse retain];
}
- (MPOAuthURLResponse *)oauthResponse {
	if (oauthResponse==nil)
		oauthResponse = [[MPOAuthURLResponse alloc] init];
	return oauthResponse;
}
- (NSData *)data {
	return data;
}
- (NSString *)responseString {
	if (responseString==nil)
		responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return responseString;
}
- (void)setTarget:(id)theTarget {
	target = theTarget;
}
- (id)target {
	return target;
}
- (void)setAction:(SEL)theAction {
	action = theAction;
}
- (SEL)action {
	return action;
}

#pragma mark -

- (void)loadSynchronously:(BOOL)inSynchronous {
	NSAssert(credentials, @"Unable to load without valid credentials");
	NSAssert(credentials.consumerKey, @"Unable to load, credentials contain no consumer key");
	
	if (!inSynchronous) {
		[MPOAuthConnection connectionWithRequest:oauthRequest delegate:self credentials:credentials];
	} else {
		MPOAuthURLResponse *theOAuthResponse = nil;
		data = [[MPOAuthConnection sendSynchronousRequest:oauthRequest usingCredentials:credentials returningResponse:&theOAuthResponse error:nil] retain];
		[self setOauthResponse:theOAuthResponse];
		[self _interrogateResponseForOAuthData];
	}
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)theError {
		MPLog(@"%p: [%@ %@] %@, %@", self, NSStringFromClass([self class]), NSStringFromSelector(_cmd), connection, theError);
	if ([target respondsToSelector:@selector(loader:didFailWithError:)]) {
		[target performSelector: @selector(loader:didFailWithError:) withObject: self withObject: theError];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[[self oauthResponse] setResponse:response];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	MPLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData {
	[data appendData:theData];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	MPLog( @"[%@ %@]: %@, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), request, redirectResponse);
	return request;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self _interrogateResponseForOAuthData];
	
	if (action) {
		if ([target conformsToProtocol:@protocol(MPOAuthAPIInternalClient)]) {
			[target performSelector:action withObject:self withObject:data];
		} else {
			[target performSelector:action withObject:[oauthRequest url] withObject:responseString];
		}
	}
}

#pragma mark -

- (void)_interrogateResponseForOAuthData {
	NSString *response = responseString;
	NSDictionary *foundParameters = nil;
	int status = [(NSHTTPURLResponse *)[[self oauthResponse] response] statusCode];
	
	if ([response length] > 5 && [[response substringToIndex:5] isEqualToString:@"oauth"]) {
		foundParameters = [MPURLRequestParameter parameterDictionaryFromString:response];
		oauthResponse.oauthParameters = foundParameters;
		
		if (status == 401 || ([response length] > 13 && [[response substringToIndex:13] isEqualToString:@"oauth_problem"])) {
			NSString *aParameterValue = nil;
			MPLog(@"oauthProblem = %@", foundParameters);
			
			if ([foundParameters count] && (aParameterValue = [foundParameters objectForKey:@"oauth_problem"])) {
				if ([aParameterValue isEqualToString:@"token_rejected"]) {
					if ([credentials requestToken] && ![credentials accessToken]) {
						[credentials setRequestToken:nil];
						[credentials setRequestTokenSecret:nil];
						
						[[NSNotificationCenter defaultCenter] postNotificationName:MPOAuthNotificationRequestTokenRejected
																			object:nil
																		  userInfo:foundParameters];
					} else if ([credentials accessToken] && ![credentials requestToken]) {
						// your access token may be invalid due to a number of reasons so it's up to the
						// user to decide whether or not to remove them
						[[NSNotificationCenter defaultCenter] postNotificationName:MPOAuthNotificationAccessTokenRejected
																			object:nil
																		  userInfo:foundParameters];
						
					}						
				}
				
				// something's messed up, so throw an error
				[[NSNotificationCenter defaultCenter] postNotificationName:MPOAuthNotificationErrorHasOccurred
																	object:nil
																  userInfo:foundParameters];
			}
		} else if ([response length] > 11 && [[response substringToIndex:11] isEqualToString:@"oauth_token"]) {
			NSString *aParameterValue = nil;
			MPLog(@"foundParameters = %@", foundParameters);

			if ([foundParameters count] && (aParameterValue = [foundParameters objectForKey:@"oauth_token"])) {
				if (![credentials requestToken] && ![credentials accessToken]) {
					[credentials setRequestToken:aParameterValue];
					[credentials setRequestTokenSecret:[foundParameters objectForKey:@"oauth_token_secret"]];
					
					[[NSNotificationCenter defaultCenter] postNotificationName:MPOAuthNotificationRequestTokenReceived
																		object:nil
																	  userInfo:foundParameters];
					
				} else if (![credentials accessToken] && [credentials requestToken]) {
					[credentials setRequestToken:nil];
					[credentials setRequestTokenSecret:nil];
					[credentials setAccessToken:aParameterValue];
					[credentials setAccessTokenSecret:[foundParameters objectForKey:@"oauth_token_secret"]];
					
					[[NSNotificationCenter defaultCenter] postNotificationName:MPOAuthNotificationAccessTokenReceived
																		object:nil
																	  userInfo:foundParameters];
					
				} else if ([credentials accessToken] && ![credentials requestToken]) {
					// replace the current token
					[credentials setAccessToken:aParameterValue];
					[credentials setAccessTokenSecret:[foundParameters objectForKey:@"oauth_token_secret"]];
					
					[[NSNotificationCenter defaultCenter] postNotificationName:MPOAuthNotificationAccessTokenRefreshed
																		object:nil
																	  userInfo:foundParameters];
				}
			}
		}
	}
}

@end
