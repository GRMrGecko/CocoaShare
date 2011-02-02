//
//  MGMWebDavGet.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>
extern NSString * const MGMWebDavMGET;

@class MGMWebDavGet, MGMWebDav;

@protocol MGMWebDavDelegate;

@protocol MGMWebDavGetDelegate <MGMWebDavDelegate>
- (void)webDav:(MGMWebDav *)theSender get:(MGMWebDavGet *)theGet downloaded:(unsigned long)theBytes totalBytes:(unsigned long)theTotalBytes totalBytesExpected:(unsigned long)theExpectedBytes;
- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError getting:(MGMWebDavGet *)theGet;
- (void)webDav:(MGMWebDav *)theSender gotSuccessfully:(MGMWebDavGet *)theGet;
@end

@interface MGMWebDavGet : NSObject {
	id<MGMWebDavGetDelegate> delegate;
	NSString *uri;
	MGMWebDav *webDav;
	NSMutableURLRequest *request;
	NSURLConnection *connection;
	NSHTTPURLResponse *response;
	
	NSString *file;
	NSFileHandle *fileHandle;
	NSMutableData *dataBuffer;
	
	unsigned long totalExpected;
	unsigned long totalDownloaded;
}
+ (id)getAtURI:(NSString *)theURI;
- (id)initWithURI:(NSString *)theURI;

- (void)setDelegate:(id)theDelegate;
- (id<MGMWebDavGetDelegate>)delegate;

- (void)setURI:(NSString *)theURI;
- (NSString *)URI;

- (void)setFile:(NSString *)theFile;
- (NSString *)file;

- (NSMutableURLRequest *)request;
- (NSURLResponse *)response;

- (NSData *)data;
@end