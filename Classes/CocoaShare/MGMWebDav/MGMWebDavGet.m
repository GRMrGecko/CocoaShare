//
//  MGMWebDavGet.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMWebDavGet.h"
#import "MGMWebDav.h"
#import "MGMLocalized.h"

NSString * const MGMWebDavMGET = @"GET";

@implementation MGMWebDavGet
+ (id)getAtURI:(NSString *)theURI {
	return [[[self alloc] initWithURI:theURI] autorelease];
}
- (id)initWithURI:(NSString *)theURI {
	if ((self = [super init])) {
		uri = [theURI retain];
	}
	return self;
}
- (void)dealloc {
	[uri release];
	[file release];
	[fileHandle release];
	[dataBuffer release];
	[request release];
	[connection release];
	[response release];
	[super dealloc];
}

- (void)setDelegate:(id)theDelegate {
	delegate = theDelegate;
}
- (id<MGMWebDavGetDelegate>)delegate {
	if (delegate==nil)
		return (id<MGMWebDavGetDelegate>)[webDav delegate];
	return delegate;
}

- (void)setURI:(NSString *)theURI {
	[uri release];
	uri = [theURI retain];
}
- (NSString *)URI {
	return uri;
}

- (void)setFile:(NSString *)theFile {
	[file release];
	file = [theFile retain];
}
- (NSString *)file {
	return file;
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
		[request setHTTPMethod:MGMWebDavMGET];
		
		NSFileManager *manager = [NSFileManager defaultManager];
		if ([manager fileExistsAtPath:[file stringByDeletingLastPathComponent]]) {
			[manager createFileAtPath:file contents:nil attributes:nil];
			fileHandle = [[NSFileHandle fileHandleForWritingAtPath:file] retain];
		} else {
			dataBuffer = [NSMutableData new];
		}
	}
	return request;
}

- (void)didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	response = [theResponse retain];
	if ([response statusCode]!=200) {
		[fileHandle closeFile];
		[fileHandle release];
		fileHandle = nil;
		NSString *description = [NSString stringWithFormat:[@"The response was returned as %@ and not %@." localized], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]], [NSHTTPURLResponse localizedStringForStatusCode:200]];
		NSError *error = [NSError errorWithDomain:MGMWebDavErrorDomain code:[response statusCode] userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
		if ([[self delegate] respondsToSelector:@selector(webDav:error:getting:)]) [[self delegate] webDav:webDav error:error getting:self];
		[webDav cancelHandler:self];
	}
	totalExpected = [response expectedContentLength];
}
- (void)didReceiveData:(NSData *)theData {
	totalDownloaded += [theData length];
	if ([[self delegate] respondsToSelector:@selector(webDav:get:downloaded:totalBytes:totalBytesExpected:)]) [[self delegate] webDav:webDav get:self downloaded:[theData length] totalBytes:totalDownloaded totalBytesExpected:totalExpected];
	
	if (fileHandle!=nil) {
		[fileHandle writeData:theData];
		[fileHandle synchronizeFile];
	} else {
		[dataBuffer appendData:theData];
	}
}
- (void)didFailWithError:(NSError *)theError {
	[fileHandle closeFile];
	[fileHandle release];
	fileHandle = nil;
	if ([[self delegate] respondsToSelector:@selector(webDav:error:getting:)]) [[self delegate] webDav:webDav error:theError getting:self];
}
- (void)didFinishLoading {
	[fileHandle closeFile];
	[fileHandle release];
	fileHandle = nil;
	if ([[self delegate] respondsToSelector:@selector(webDav:gotSuccessfully:)]) [[self delegate] webDav:webDav gotSuccessfully:self];
}

- (NSURLResponse *)response {
	return response;
}

- (NSData *)data {
	return dataBuffer;
}
@end