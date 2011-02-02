//
//  MGMWebDav.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>
#import "MGMWebDavAddons.h"
#import "MGMWebDavOptions.h"
#import "MGMWebDavPropFind.h"
#import "MGMWebDavPut.h"
#import "MGMWebDavGet.h"
#import "MGMWebDavDelete.h"
#import "MGMWebDavMkCol.h"

extern NSString * const MGMWebDavErrorDomain;

extern NSString * const MGMWebDavDepth;
extern NSString * const MGMWebDavContentType;
extern NSString * const MGMWebDavXMLType;

@class MGMWebDav;

@protocol MGMWebDavDelegate <NSObject>
- (void)webDav:(MGMWebDav *)theSender loginFailedWithError:(NSError *)theError;
- (void)webDavLoginSuccessful:(MGMWebDav *)theSender;
@end

@protocol MGMWebDavHandler <NSObject>
- (void)setWebDav:(MGMWebDav *)theWebDav;
- (void)setConnection:(NSURLConnection *)theConnection;
- (NSURLConnection *)connection;
- (void)setRequest:(NSMutableURLRequest *)theRequest;
- (NSMutableURLRequest *)request;
- (NSURLCredential *)credentailsForChallenge:(NSURLAuthenticationChallenge *)theChallenge;
- (void)uploaded:(unsigned long)theBytes totalBytes:(unsigned long)theTotalBytes totalBytesExpected:(unsigned long)theExpectedBytes;
- (NSURLRequest *)willSendRequest:(NSURLRequest *)theRequest redirectResponse:(NSHTTPURLResponse *)theResponse;
- (void)didReceiveResponse:(NSHTTPURLResponse *)theResponse;
- (void)didReceiveData:(NSData *)theData;
- (void)didFailWithError:(NSError *)theError;
- (void)didFinishLoading;
@end

@interface MGMWebDav : NSObject {
	id<MGMWebDavDelegate> delegate;
	
	NSURL *rootURL;
	NSURLCredential *credentials;
	//CFHTTPAuthenticationRef authentication;
	NSMutableArray *handlers;
}
+ (id)webDav;
+ (id)webDavWithDelegate:(id)theDelegate;
- (id)initWithDelegate:(id)theDelegate;

- (void)setDelegate:(id)theDelegate;
- (id<MGMWebDavDelegate>)delegate;
- (void)setRootURL:(NSURL *)theURL;
- (NSURL *)rootURL;
- (void)setCredentials:(NSURLCredential *)theCredentials;
- (void)setUser:(NSString *)theUser password:(NSString *)thePassword;
- (NSURLCredential *)credentials;

- (void)addHandler:(id)theHandler;
- (void)cancelHandler:(id)theHandler;
- (void)cancelAll;
@end