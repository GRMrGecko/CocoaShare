//
//  MGMWebDavMkCol.h
//  CocoaShare
//
//  Created by James on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

extern NSString * const MGMWebDavMMKCOL;

@class MGMWebDavMkCol, MGMWebDav;
@protocol MGMWebDavDelegate;

@protocol MGMWebDavMkColDelegate <MGMWebDavDelegate>
- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError mkCol:(MGMWebDavMkCol *)theMkCol;
- (void)webDav:(MGMWebDav *)theSender mkCol:(MGMWebDavMkCol *)theMkCol;
@end

@interface MGMWebDavMkCol : NSObject {
	id<MGMWebDavMkColDelegate> delegate;
	NSString *uri;
	MGMWebDav *webDav;
	NSMutableURLRequest *request;
	NSURLConnection *connection;
	NSHTTPURLResponse *response;
}
+ (id)mkColAtURI:(NSString *)theURI;
- (id)initWithURI:(NSString *)theURI;

- (void)setDelegate:(id)theDelegate;
- (id<MGMWebDavMkColDelegate>)delegate;

- (void)setURI:(NSString *)theURI;
- (NSString *)URI;

- (NSMutableURLRequest *)request;
- (NSURLResponse *)response;
@end