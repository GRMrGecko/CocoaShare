//
//  MGMWebDavDelete.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

extern NSString * const MGMWebDavMDELETE;

@class MGMWebDavDelete, MGMWebDav;
@protocol MGMWebDavDelegate;

@protocol MGMWebDavDeleteDelegate <MGMWebDavDelegate>
- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError deleting:(MGMWebDavDelete *)theDelete;
- (void)webDav:(MGMWebDav *)theSender deleted:(MGMWebDavDelete *)theDelete;
@end

@interface MGMWebDavDelete : NSObject {
	id<MGMWebDavDeleteDelegate> delegate;
	NSString *uri;
	MGMWebDav *webDav;
	NSMutableURLRequest *request;
	NSURLConnection *connection;
	NSHTTPURLResponse *response;
}
+ (id)deleteAtURI:(NSString *)theURI;
- (id)initWithURI:(NSString *)theURI;

- (void)setDelegate:(id)theDelegate;
- (id<MGMWebDavDeleteDelegate>)delegate;

- (void)setURI:(NSString *)theURI;
- (NSString *)URI;

- (NSMutableURLRequest *)request;
- (NSURLResponse *)response;
@end