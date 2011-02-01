//
//  MGMWebDavMkCol.m
//  CocoaShare
//
//  Created by James on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMWebDavMkCol.h"
#import "MGMWebDav.h"

NSString * const MGMWebDavMMKCOL = @"MKCOL";

@implementation MGMWebDavMkCol
+ (id)mkColAtURI:(NSString *)theURI {
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
	[request release];
	[connection release];
	[response release];
	[super dealloc];
}

- (void)setDelegate:(id)theDelegate {
	delegate = theDelegate;
}
- (id<MGMWebDavMkColDelegate>)delegate {
	if (delegate==nil)
		return (id<MGMWebDavMkColDelegate>)[webDav delegate];
	return delegate;
}

- (void)setURI:(NSString *)theURI {
	[uri release];
	uri = [theURI retain];
}
- (NSString *)URI {
	return uri;
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
		[request setHTTPMethod:MGMWebDavMMKCOL];
	}
	return request;
}

- (void)didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	response = [theResponse retain];
	if ([response statusCode]==201) {
		if ([[self delegate] respondsToSelector:@selector(webDav:mkCol:)]) [[self delegate] webDav:webDav mkCol:self];
	} else {
		NSString *description = [NSString stringWithFormat:@"The response was returned as %@ and not %@.", [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]], [NSHTTPURLResponse localizedStringForStatusCode:201]];
		NSError *error = [NSError errorWithDomain:MGMWebDavErrorDomain code:[response statusCode] userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
		if ([[self delegate] respondsToSelector:@selector(webDav:error:mkCol:)]) [[self delegate] webDav:webDav error:error mkCol:self];
	}
}
- (void)didFailWithError:(NSError *)theError {
	if ([[self delegate] respondsToSelector:@selector(webDav:error:mkCol:)]) [[self delegate] webDav:webDav error:theError mkCol:self];
}

- (NSURLResponse *)response {
	return response;
}
@end