//
//  MGMWebDavPut.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

extern NSString * const MGMWebDavMPUT;

@class MGMWebDavPut, MGMWebDav;
@protocol MGMWebDavDelegate;

@protocol MGMWebDavPutDelegate <MGMWebDavDelegate>
- (void)webDav:(MGMWebDav *)theSender put:(MGMWebDavPut *)thePut uploaded:(unsigned long)theBytes totalBytes:(unsigned long)theTotalBytes totalBytesExpected:(unsigned long)theExpectedBytes;
- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError putting:(MGMWebDavPut *)thePut;
- (void)webDav:(MGMWebDav *)theSender successfullyPut:(MGMWebDavPut *)thePut;
@end

@interface MGMWebDavPut : NSObject {
	id<MGMWebDavPutDelegate> delegate;
	NSString *uri;
	MGMWebDav *webDav;
	NSData *data;
	NSMutableURLRequest *request;
	NSURLConnection *connection;
	NSHTTPURLResponse *response;
}
+ (id)putAtURI:(NSString *)theURI;
- (id)initWithURI:(NSString *)theURI;

- (void)setDelegate:(id)theDelegate;
- (id<MGMWebDavPutDelegate>)delegate;

- (void)setURI:(NSString *)theURI;
- (NSString *)URI;

- (void)setData:(NSData *)theData;
- (NSData *)data;

- (NSMutableURLRequest *)request;
- (NSURLResponse *)response;
@end