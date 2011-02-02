//
//  MGMWebDavPropFind.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

extern NSString * const MGMWebDavMPROPFIND;

extern NSString * const MGMWebDavDepth;

extern NSString * const MGMWebDavPCreationDate;
extern NSString * const MGMWebDavPDisplayName;
extern NSString * const MGMWebDavPContentLength;
extern NSString * const MGMWebDavPContentType;
extern NSString * const MGMWebDavPETag;
extern NSString * const MGMWebDavPLastModified;
extern NSString * const MGMWebDavPResourceType;
extern NSString * const MGMWebDavPSupportedLock;
extern NSString * const MGMWebDavPQuotaAvailableBytes;
extern NSString * const MGMWebDavPQuotaUsedBytes;
extern NSString * const MGMWebDavPQuota;
extern NSString * const MGMWebDavPQuotaUsed;

extern NSString * const MGMWebDavPURL;
extern NSString * const MGMWebDavPURI;
extern NSString * const MGMWebDavPStatus;

extern NSString * const MGMWebDavPRCollection;
extern NSString * const MGMWebDavPRFile;

@class MGMWebDavPropFind, MGMWebDav;
@protocol MGMWebDavDelegate;

@protocol MGMWebDavPropFindDelegate <MGMWebDavDelegate>
- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError recevingProperties:(MGMWebDavPropFind *)thePropFind;
- (void)webDav:(MGMWebDav *)theSender receivedProperties:(MGMWebDavPropFind *)thePropFind;
@end

@interface MGMWebDavPropFind : NSObject {
	id<MGMWebDavPropFindDelegate> delegate;
	NSString *uri;
	NSMutableArray *properties;
	int depth;
	MGMWebDav *webDav;
	NSMutableURLRequest *request;
	NSURLConnection *connection;
	NSHTTPURLResponse *response;
	NSMutableData *dataBuffer;
	NSXMLDocument *xmlDocument;
	NSMutableArray *contents;
}
+ (id)propfindAtURI:(NSString *)theURI;
- (id)initWithURI:(NSString *)theURI;

- (void)setDelegate:(id)theDelegate;
- (id<MGMWebDavPropFindDelegate>)delegate;

- (void)setURI:(NSString *)theURI;
- (NSString *)URI;

- (NSArray *)properties;
- (void)addProperty:(NSString *)theProperty;
- (void)removeProperty:(NSString *)theProperty;

- (void)setDepth:(int)theDepth;
- (int)depth;

- (NSMutableURLRequest *)request;
- (NSURLResponse *)response;

- (NSData *)data;
- (NSXMLDocument *)xmlDocument;
- (NSArray *)contents;
@end