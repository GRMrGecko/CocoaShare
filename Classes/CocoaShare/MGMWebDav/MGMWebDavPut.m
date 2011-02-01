//
//  MGMWebDavPut.m
//  CocoaShare
//
//  Created by James on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMWebDavPut.h"
#import "MGMWebDav.h"

NSString * const MGMWebDavMPUT = @"PUT";

@implementation MGMWebDavPut
+ (id)putAtURI:(NSString *)theURI {
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
	[data release];
	[request release];
	[connection release];
	[response release];
	[super dealloc];
}

- (void)setDelegate:(id)theDelegate {
	delegate = theDelegate;
}
- (id<MGMWebDavPutDelegate>)delegate {
	if (delegate==nil)
		return (id<MGMWebDavPutDelegate>)[webDav delegate];
	return delegate;
}

- (void)setURI:(NSString *)theURI {
	[uri release];
	uri = [theURI retain];
}
- (NSString *)URI {
	return uri;
}

- (void)setData:(NSData *)theData {
	[data release];
	data = [theData retain];
}
- (NSData *)data {
	return data;
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
		[request setHTTPMethod:MGMWebDavMPUT];
		[request setHTTPBody:data];
	}
	return request;
}

- (void)uploaded:(unsigned long)theBytes totalBytes:(unsigned long)theTotalBytes totalBytesExpected:(unsigned long)theExpectedBytes {
	if ([[self delegate] respondsToSelector:@selector(webDav:put:uploaded:totalBytes:totalBytesExpected:)]) [[self delegate] webDav:webDav put:self uploaded:theBytes totalBytes:theTotalBytes totalBytesExpected:theExpectedBytes];
}
- (void)didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	response = [theResponse retain];
	if ([response statusCode]==201 || [response statusCode]==204) {
		if ([[self delegate] respondsToSelector:@selector(webDav:successfullyPut:)]) [[self delegate] webDav:webDav successfullyPut:self];
	} else {
		NSString *description = [NSString stringWithFormat:@"The response was returned as %@ and not %@.", [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]], [NSHTTPURLResponse localizedStringForStatusCode:201]];
		NSError *error = [NSError errorWithDomain:MGMWebDavErrorDomain code:[response statusCode] userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
		if ([[self delegate] respondsToSelector:@selector(webDav:error:putting:)]) [[self delegate] webDav:webDav error:error putting:self];
	}
}
- (void)didFailWithError:(NSError *)theError {
	if ([[self delegate] respondsToSelector:@selector(webDav:error:putting:)]) [[self delegate] webDav:webDav error:theError putting:self];
}

- (NSURLResponse *)response {
	return response;
}
@end