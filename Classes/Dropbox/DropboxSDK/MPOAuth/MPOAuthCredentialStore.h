//
//  MPOAuthCredentialStore.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.06.
//  Copyright 2008 matrixPointer. All rights reserved.
//

extern NSString *kMPOAuthCredentialConsumerKey;
extern NSString *kMPOAuthCredentialConsumerSecret;
extern NSString *kMPOAuthCredentialUsername;
extern NSString *kMPOAuthCredentialPassword;
extern NSString *kMPOAuthCredentialRequestToken;
extern NSString *kMPOAuthCredentialRequestTokenSecret;
extern NSString *kMPOAuthCredentialAccessToken;
extern NSString *kMPOAuthCredentialAccessTokenSecret;
extern NSString *kMPOAuthCredentialSessionHandle;
extern NSString *kMPOAuthCredentialRealm;

@protocol MPOAuthCredentialStore <NSObject>

- (NSString *)consumerKey;
- (NSString *)consumerSecret;
- (NSString *)username;
- (NSString *)password;
- (NSString *)requestToken;
- (NSString *)requestTokenSecret;
- (NSString *)accessToken;
- (NSString *)accessTokenSecret;

- (NSString *)credentialNamed:(NSString *)inCredentialName;
- (void)discardOAuthCredentials;
@end
