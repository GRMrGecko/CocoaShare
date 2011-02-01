//
//  MPOAuthAuthenticationMethodOAuth.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 09.12.19.
//  Copyright 2009 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPOAuthAuthenticationMethod.h"
#import "MPOAuthAPI.h"
#import "MPOAuthAPIRequestLoader.h"

extern NSString * const MPOAuthNotificationRequestTokenReceived;
extern NSString * const MPOAuthNotificationRequestTokenRejected;

@protocol MPOAuthAuthenticationMethodOAuthDelegate;

@interface MPOAuthAuthenticationMethodOAuth : MPOAuthAuthenticationMethod <MPOAuthAPIInternalClient> {
	NSURL									*oauthRequestTokenURL;
	NSURL									*oauthAuthorizeTokenURL;
	BOOL									oauth10aModeActive;
	
	id<MPOAuthAuthenticationMethodOAuthDelegate> delegate;
}

- (void)setDelegate:(id)theDelegate;
- (id<MPOAuthAuthenticationMethodOAuthDelegate>)delegate;

- (void)setOauthRequestTokenURL:(NSURL *)theURL;
- (NSURL *)oauthRequestTokenURL;
- (void)setOauthAuthorizeTokenURL:(NSURL *)theURL;
- (NSURL *)oauthAuthorizeTokenURL;

- (void)setOauth10aModeActive:(BOOL)isActive;
- (BOOL)oauth10aModeActive;

- (void)authenticate;

@end

@protocol MPOAuthAuthenticationMethodOAuthDelegate <NSObject>
- (NSURL *)callbackURLForCompletedUserAuthorization;
- (BOOL)automaticallyRequestAuthenticationFromURL:(NSURL *)inAuthURL withCallbackURL:(NSURL *)inCallbackURL;

@optional
- (NSString *)oauthVerifierForCompletedUserAuthorization;
- (void)authenticationDidFailWithError:(NSError *)error;
@end

