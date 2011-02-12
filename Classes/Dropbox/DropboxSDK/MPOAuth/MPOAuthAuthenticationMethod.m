//
//  MPOAuthAuthenticationMethod.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 09.12.19.
//  Copyright 2009 matrixPointer. All rights reserved.
//

#import "MPOAuthAuthenticationMethod.h"
#import "MPOAuthAuthenticationMethodOAuth.h"
#import "MPOAuthCredentialConcreteStore.h"
#import "MPURLRequestParameter.h"

#import "NSURL+MPURLParameterAdditions.h"

NSString * const MPOAuthAccessTokenURLKey					= @"MPOAuthAccessTokenURL";

@interface MPOAuthAuthenticationMethod ()
+ (Class)_authorizationMethodClassForURL:(NSURL *)inBaseURL withConfiguration:(NSDictionary **)outConfig;
- (id)initWithAPI:(MPOAuthAPI *)inAPI forURL:(NSURL *)inURL withConfiguration:(NSDictionary *)inConfig;
- (void)_automaticallyRefreshAccessToken:(NSTimer *)inTimer;
@end

@implementation MPOAuthAuthenticationMethod
- (id)initWithAPI:(MPOAuthAPI *)inAPI forURL:(NSURL *)inURL {
	return [self initWithAPI:inAPI forURL:inURL withConfiguration:nil];
}

- (id)initWithAPI:(MPOAuthAPI *)inAPI forURL:(NSURL *)inURL withConfiguration:(NSDictionary *)inConfig {
	if ([[self class] isEqual:[MPOAuthAuthenticationMethod class]]) {
		NSDictionary *configuration = nil;
		Class methodClass = [[self class] _authorizationMethodClassForURL:inURL withConfiguration:&configuration];
		[self release];
		
		self = [[methodClass alloc] initWithAPI:inAPI forURL:inURL withConfiguration:configuration];
	} else if ((self = [super init])) {
		oauthAPI = inAPI;
	}
	
	return self;
}

- (oneway void)dealloc {
	[oauthGetAccessTokenURL release];

	[refreshTimer invalidate];
	[refreshTimer release];
	refreshTimer = nil;

	[super dealloc];
}

- (void)setOauthAPI:(MPOAuthAPI *)theAPI {
	oauthAPI = theAPI;
}
- (MPOAuthAPI *)oauthAPI {
	return oauthAPI;
}
- (void)setOauthGetAccessTokenURL:(NSURL *)theURL {
	[oauthGetAccessTokenURL release];
	oauthGetAccessTokenURL =  [theURL retain];
}
- (NSURL *)oauthGetAccessTokenURL {
	return oauthGetAccessTokenURL;
}
#pragma mark -

+ (Class)_authorizationMethodClassForURL:(NSURL *)inBaseURL withConfiguration:(NSDictionary **)outConfig {
	Class methodClass = [MPOAuthAuthenticationMethodOAuth class];
	NSString *oauthConfigPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"oauthAutoConfig" ofType:@"plist"];
	NSDictionary *oauthConfigDictionary = [NSDictionary dictionaryWithContentsOfFile:oauthConfigPath];
	NSEnumerator *enumerator = [oauthConfigDictionary keyEnumerator];
	NSString *domainString = nil;
	while ((domainString = [enumerator nextObject])) {
		if ([inBaseURL domainMatches:domainString]) {
			NSDictionary *oauthConfig = [oauthConfigDictionary objectForKey:domainString];
			
			NSArray *requestedMethods = [oauthConfig objectForKey:@"MPOAuthAuthenticationPreferredMethods"];
			NSString *requestedMethod = nil;
			for (int i=0; i<[requestedMethods count]; i++) {
				requestedMethod = [requestedMethods objectAtIndex:i];
				Class requestedMethodClass = NSClassFromString(requestedMethod);
				
				if (requestedMethodClass) {
					methodClass = requestedMethodClass;
				}
				break;
			}
			
			if (requestedMethod) {
				*outConfig = [oauthConfig objectForKey:requestedMethod];
			} else {
				*outConfig = oauthConfig;
			}

			break;
		}
	}
	
	return methodClass; 
}

#pragma mark -

- (void)authenticate {
	[NSException raise:@"Not Implemented" format:@"All subclasses of MPOAuthAuthenticationMethod are required to implement -authenticate"];
}

- (void)setTokenRefreshInterval:(NSTimeInterval)inTimeInterval {
	if (refreshTimer==nil && inTimeInterval > 0.0) {
		refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(_automaticallyRefreshAccessToken:) userInfo:nil repeats:YES] retain];
	}
}

- (void)refreshAccessToken {
	MPURLRequestParameter *sessionHandleParameter = nil;
	MPOAuthCredentialConcreteStore *credentials = (MPOAuthCredentialConcreteStore *)[oauthAPI credentials];
	
	if (credentials.sessionHandle) {
		sessionHandleParameter = [[MPURLRequestParameter alloc] init];
		sessionHandleParameter.name = @"oauth_session_handle";
		sessionHandleParameter.value = credentials.sessionHandle;
	}
	
	[oauthAPI performMethod:nil
						   atURL:oauthGetAccessTokenURL
				  withParameters:sessionHandleParameter ? [NSArray arrayWithObject:sessionHandleParameter] : nil
					  withTarget:nil
					   andAction:nil];
	
	[sessionHandleParameter release];	
}

#pragma mark -

- (void)_automaticallyRefreshAccessToken:(NSTimer *)inTimer {
	[self refreshAccessToken];
}

@end
