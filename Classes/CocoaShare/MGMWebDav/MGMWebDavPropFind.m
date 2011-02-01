//
//  MGMWebDavPropFind.m
//  CocoaShare
//
//  Created by James on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMWebDavPropFind.h"
#import "MGMWebDav.h"

NSString * const MGMWebDavMPROPFIND = @"PROPFIND";

NSString * const MGMWebDavDepth = @"Depth";

NSString * const MGMWebDavPCreationDate = @"creationdate";
NSString * const MGMWebDavPDisplayName = @"displayname";
NSString * const MGMWebDavPContentLength = @"getcontentlength";
NSString * const MGMWebDavPContentType = @"getcontenttype";
NSString * const MGMWebDavPETag = @"getetag";
NSString * const MGMWebDavPLastModified = @"getlastmodified";
NSString * const MGMWebDavPResourceType = @"resourcetype";
NSString * const MGMWebDavPSupportedLock = @"supportedlock";
NSString * const MGMWebDavPQuotaAvailableBytes = @"quota-available-bytes";
NSString * const MGMWebDavPQuotaUsedBytes = @"quota-used-bytes";
NSString * const MGMWebDavPQuota = @"quota";
NSString * const MGMWebDavPQuotaUsed = @"quotaused";

NSString * const MGMWebDavPURL = @"url";
NSString * const MGMWebDavPURI = @"uri";
NSString * const MGMWebDavPStatus = @"status";

NSString * const MGMWebDavPRCollection = @"collection";
NSString * const MGMWebDavPRFile = @"file";

@implementation MGMWebDavPropFind
+ (id)propfindAtURI:(NSString *)theURI {
	return [[[self alloc] initWithURI:theURI] autorelease];
}
- (id)initWithURI:(NSString *)theURI {
	if ((self = [self init])) {
		uri = [theURI retain];
		depth = 0;
	}
	return self;
}
- (id)init {
	if ((self = [super init])) {
		properties = [NSMutableArray new];
		dataBuffer = [NSMutableData new];
		contents = [NSMutableArray new];
	}
	return self;
}
- (void)dealloc {
	[uri release];
	[properties release];
	[request release];
	[connection release];
	[response release];
	[dataBuffer release];
	[xmlDocument release];
	[contents release];
	[super dealloc];
}

- (void)setDelegate:(id)theDelegate {
	delegate = theDelegate;
}
- (id<MGMWebDavPropFindDelegate>)delegate {
	if (delegate==nil)
		return (id<MGMWebDavPropFindDelegate>)[webDav delegate];
	return delegate;
}

- (void)setURI:(NSString *)theURI {
	[uri release];
	uri = [theURI retain];
}
- (NSString *)URI {
	return uri;
}

- (NSArray *)properties {
	return properties;
}
- (void)addProperty:(NSString *)theProperty {
	if (![properties containsObject:theProperty])
		[properties addObject:theProperty];
}
- (void)removeProperty:(NSString *)theProperty {
	[properties removeObject:theProperty];
}

- (void)setDepth:(int)theDepth {
	depth = theDepth;
}
- (int)depth {
	return depth;
}

- (void)setWebDav:(MGMWebDav *)theWebDav {
	webDav = theWebDav;
}
- (void)setConnection:(NSURLConnection *)theConnection {
	[connection release];
	connection = [theConnection retain];
}
- (NSURLConnection *)connection {
	return connection;
}

- (void)setRequest:(NSMutableURLRequest *)theRequest {
	[request release];
	request = [theRequest retain];
}
- (NSMutableURLRequest *)request {
	if (request==nil) {
		request = [[NSMutableURLRequest requestWithURL:[[webDav rootURL] appendPathComponent:uri]] retain];
		[request setHTTPMethod:MGMWebDavMPROPFIND];
		[request setValue:[[NSNumber numberWithInt:depth] stringValue] forHTTPHeaderField:MGMWebDavDepth];
		[request setValue:MGMWebDavXMLType forHTTPHeaderField:MGMWebDavContentType];
		NSMutableString *xml = [NSMutableString string];
		[xml appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
		[xml appendString:@"<D:propfind xmlns:D=\"DAV:\">"];
		if ([properties count]>0) {
			[xml appendString:@"<D:prop>"];
			for (int i=0; i<[properties count]; i++) {
				[xml appendFormat:@"<D:%@/>", [properties objectAtIndex:i]];
			}
			[xml appendString:@"</D:prop>"];
		} else {
			[xml appendString:@"<D:allprop/>"];
		}
		[xml appendString:@"</D:propfind>"];
		[request setHTTPBody:[xml dataUsingEncoding:NSUTF8StringEncoding]];
	}
	return request;
}

- (void)didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	response = [theResponse retain];
	if ([response statusCode]!=207) {
		NSString *description = [NSString stringWithFormat:@"The response was returned as %@ and not %@.", [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]], [NSHTTPURLResponse localizedStringForStatusCode:207]];
		NSError *error = [NSError errorWithDomain:MGMWebDavErrorDomain code:[response statusCode] userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
		if ([[self delegate] respondsToSelector:@selector(webDav:error:recevingProperties:)]) [[self delegate] webDav:webDav error:error recevingProperties:self];
		[webDav cancelHandler:self];
	}
}
- (void)didReceiveData:(NSData *)theData {
	[dataBuffer appendData:theData];
}
- (void)didFailWithError:(NSError *)theError {
	if ([[self delegate] respondsToSelector:@selector(webDav:error:recevingProperties:)]) [[self delegate] webDav:webDav error:theError recevingProperties:self];
}
- (void)didFinishLoading {
	NSError *error = nil;
	xmlDocument = [[NSXMLDocument alloc] initWithData:dataBuffer options:0 error:&error];
	if (error!=nil)
		NSLog(@"%@", error);
	NSArray *responses = [[xmlDocument rootElement] elementsForLocalName:@"response" URI:@"DAV:"];
	for (unsigned long i=0; i<[responses count]; i++) {
		NSXMLElement *thisResponse = [responses objectAtIndex:i];
		NSMutableDictionary *content = [NSMutableDictionary dictionary];
		
		NSArray *hrefElements = [thisResponse elementsForLocalName:@"href" URI:@"DAV:"];
		if ([hrefElements count]<=0)
			continue;
		NSString *href = [[hrefElements objectAtIndex:0] stringValue];
		NSURL *url = nil;
		if ([href hasPrefix:@"http"])
			url = [NSURL URLWithString:href];
		else
			url = [NSURL URLWithString:href relativeToURL:[request URL]];
		[content setObject:url forKey:MGMWebDavPURL];
		NSString *path = [url path];
		NSRange range = [path rangeOfString:[[webDav rootURL] path] options:NSCaseInsensitiveSearch];
		if (range.length!=0 && range.location==0) {
			path = [path substringFromIndex:range.length];
			if ([[url absoluteString] hasSuffix:@"/"])
				path = [path stringByAppendingString:@"/"];
			[content setObject:path forKey:MGMWebDavPURI];
		}
		
		NSArray *propStats = [thisResponse elementsForLocalName:@"propstat" URI:@"DAV:"];
		if ([propStats count]>0) {
			NSXMLElement *propStat = [propStats objectAtIndex:0];
			NSArray *props = [propStat elementsForLocalName:@"prop" URI:@"DAV:"];
			if ([props count]>0) {
				props = [[props objectAtIndex:0] children];
				for (int i=0; i<[props count]; i++) {
					NSXMLElement *prop = [props objectAtIndex:i];
					NSString *name = [prop localName];
					if ([name isEqual:MGMWebDavPResourceType]) {
						if ([prop childCount]>0)
							[content setObject:[[prop childAtIndex:0] localName] forKey:name];
						else
							[content setObject:MGMWebDavPRFile forKey:name];
					} else if ([name isEqual:MGMWebDavPCreationDate]) {
						NSString *dateString = [prop stringValue];
						NSDateFormatter *dateFormatter = [NSDateFormatter new];
						[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
						[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
						NSDate *date = [dateFormatter dateFromString:dateString];
						[dateFormatter release];
						[content setObject:date forKey:name];
					} else if ([name isEqual:MGMWebDavPLastModified]) {
						NSString *dateString = [prop stringValue];
						NSDateFormatter *dateFormatter = [NSDateFormatter new];
						[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
						NSDate *date = [dateFormatter dateFromString:dateString];
						[dateFormatter release];
						[content setObject:date forKey:name];
					} else if ([name isEqual:MGMWebDavPSupportedLock]) {
						// Don't exactly understand what this is.
					} else {
						if ([prop stringValue]!=nil)
							[content setObject:[prop stringValue] forKey:name];
					}
				}
			}
			NSArray *statuses = [propStat elementsForLocalName:@"status" URI:@"DAV:"];
			if ([statuses count]>0)
				[content setObject:[[statuses objectAtIndex:0] stringValue] forKey:MGMWebDavPStatus];
		}
		[contents addObject:content];
	}
	if ([[self delegate] respondsToSelector:@selector(webDav:receivedProperties:)]) [[self delegate] webDav:webDav receivedProperties:self];
}

- (NSURLResponse *)response {
	return response;
}

- (NSData *)data {
	return dataBuffer;
}
- (NSXMLDocument *)xmlDocument {
	return xmlDocument;
}
- (NSArray *)contents {
	return contents;
}
@end