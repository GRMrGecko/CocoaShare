//
//  MGMWebDavOptions.h
//  CocoaShare
//
//  Created by James on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

extern NSString * const MGMWebDavMOPTIONS;

@class MGMWebDavOptions, MGMWebDav;
@protocol MGMWebDavDelegate;

@protocol MGMWebDavOptionsDelegate <MGMWebDavDelegate>
- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError recevingOptions:(MGMWebDavOptions *)theOptions;
- (void)webDav:(MGMWebDav *)theSender receivedOptions:(MGMWebDavOptions *)theOptions;
@end

@interface MGMWebDavOptions : NSObject {
	id<MGMWebDavOptionsDelegate> delegate;
	NSString *uri;
	MGMWebDav *webDav;
	NSMutableURLRequest *request;
	NSURLConnection *connection;
	NSHTTPURLResponse *response;
}
+ (id)optionsAtURI:(NSString *)theURI;
- (id)initWithURI:(NSString *)theURI;

- (void)setDelegate:(id)theDelegate;
- (id<MGMWebDavOptionsDelegate>)delegate;

- (void)setURI:(NSString *)theURI;
- (NSString *)URI;

- (NSMutableURLRequest *)request;
- (NSArray *)allowedMethods;
- (NSURLResponse *)response;
@end