//
//  MGMWebDavOptions.m
//  CocoaShare
//
//  Created by James on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMWebDavOptions.h"
#import "MGMWebDav.h"

NSString * const MGMWebDavMOPTIONS = @"OPTIONS";

@implementation MGMWebDavOptions
+ (id)optionsAtURI:(NSString *)theURI {
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
- (id<MGMWebDavOptionsDelegate>)delegate {
	if (delegate==nil)
		return (id<MGMWebDavOptionsDelegate>)[webDav delegate];
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
		[request setHTTPMethod:MGMWebDavMOPTIONS];
	}
	return request;
}

- (void)didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	response = [theResponse retain];
	if ([[theResponse allHeaderFields] objectForKey:@"Dav"]!=nil) {
		if ([[self delegate] respondsToSelector:@selector(webDav:receivedOptions:)]) [[self delegate] webDav:webDav receivedOptions:self];
	} else {
		NSError *error = [NSError errorWithDomain:MGMWebDavErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:@"The HTTP server does not have WebDav enabled in this directory." forKey:NSLocalizedDescriptionKey]];
		if ([[self delegate] respondsToSelector:@selector(webDav:error:recevingOptions:)]) [[self delegate] webDav:webDav error:error recevingOptions:self];
	}
}
- (void)didFailWithError:(NSError *)theError {
	if ([[self delegate] respondsToSelector:@selector(webDav:error:recevingOptions:)]) [[self delegate] webDav:webDav error:theError recevingOptions:self];
}

- (NSArray *)allowedMethods {
	NSString *allowed = [[response allHeaderFields] objectForKey:@"Allow"];
	return [allowed componentsSeparatedByString:@","];
}
- (NSURLResponse *)response {
	return response;
}
@end