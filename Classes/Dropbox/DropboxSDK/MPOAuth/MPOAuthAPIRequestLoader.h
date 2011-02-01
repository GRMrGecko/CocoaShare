//
//  MPOAuthAPIRequestLoader.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MPOAuthNotificationRequestTokenReceived;
extern NSString * const MPOAuthNotificationRequestTokenRejected;
extern NSString * const MPOAuthNotificationAccessTokenReceived;
extern NSString * const MPOAuthNotificationAccessTokenRejected;
extern NSString * const MPOAuthNotificationAccessTokenRefreshed;
extern NSString * const MPOAuthNotificationErrorHasOccurred;

@protocol MPOAuthCredentialStore;
@protocol MPOAuthParameterFactory;

@class MPOAuthURLRequest;
@class MPOAuthURLResponse;
@class MPOAuthCredentialConcreteStore;

@interface MPOAuthAPIRequestLoader : NSObject {
	MPOAuthCredentialConcreteStore	*credentials;
	MPOAuthURLRequest				*oauthRequest;
	MPOAuthURLResponse				*oauthResponse;
	NSMutableData					*data;
	NSString						*responseString;
	NSError							*error;
	id								target;
	SEL								action;
}

- (void)setCredentials:(id)theCredentials;
- (id<MPOAuthCredentialStore,MPOAuthParameterFactory>)credentials;
- (void)setOauthRequest:(MPOAuthURLRequest *)theRequest;
- (MPOAuthURLRequest *)oauthRequest;
- (void)setOauthResponse:(MPOAuthURLResponse *)theResponse;
- (MPOAuthURLResponse *)oauthResponse;
- (NSData *)data;
- (NSString *)responseString;
- (void)setTarget:(id)theTarget;
- (id)target;
- (void)setAction:(SEL)theAction;
- (SEL)action;

- (id)initWithURL:(NSURL *)inURL;
- (id)initWithRequest:(MPOAuthURLRequest *)inRequest;

- (void)loadSynchronously:(BOOL)inSynchronous;
@end