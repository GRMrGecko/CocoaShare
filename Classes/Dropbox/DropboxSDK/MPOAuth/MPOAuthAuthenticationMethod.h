//
//  MPOAuthAuthenticationMethod.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 09.12.19.
//  Copyright 2009 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MPOAuthAccessTokenURLKey;

@class MPOAuthAPI;

@interface MPOAuthAuthenticationMethod : NSObject {
	MPOAuthAPI								*oauthAPI;
	NSURL									*oauthGetAccessTokenURL;
	NSTimer									*refreshTimer;
}

- (void)setOauthAPI:(MPOAuthAPI *)theAPI;
- (MPOAuthAPI *)oauthAPI;
- (void)setOauthGetAccessTokenURL:(NSURL *)theURL;
- (NSURL *)oauthGetAccessTokenURL;

- (id)initWithAPI:(MPOAuthAPI *)inAPI forURL:(NSURL *)inURL;
- (id)initWithAPI:(MPOAuthAPI *)inAPI forURL:(NSURL *)inURL withConfiguration:(NSDictionary *)inConfig;
- (void)authenticate;

- (void)setTokenRefreshInterval:(NSTimeInterval)inTimeInterval;
- (void)refreshAccessToken;
@end
