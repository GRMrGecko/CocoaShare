//
//  MGMWebDav.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMWebDav.h"

NSString * const MGMWebDavErrorDomain = @"com.MrGeckosMedia.WebDav";
NSString * const MGMWebDavUA = @"WebDAVFS/1.2.7 MGMWebDav/0.1";

NSString * const MGMWebDavUserAgent = @"User-Agent";
NSString * const MGMWebDavContentType = @"Content-Type";
NSString * const MGMWebDavXMLType = @"text/xml";

@interface MGMWebDav (MGMPrivate)
- (id<MGMWebDavHandler>)handlerForConnection:(NSURLConnection *)theConnection;
- (CFHTTPMessageRef)httpMessageFromResponse:(NSHTTPURLResponse *)theResponse;
- (CFHTTPMessageRef)httpMessageFromRequest:(NSURLRequest *)theRequest;
@end

@implementation MGMWebDav
+ (id)webDav {
	return [[[self alloc] init] autorelease];
}
- (id)init {
	if ((self = [super init])) {
		handlers = [NSMutableArray new];
	}
	return self;
}
+ (id)webDavWithDelegate:(id)theDelegate {
	return [[[self alloc] initWithDelegate:theDelegate] autorelease];
}
- (id)initWithDelegate:(id)theDelegate {
	if ((self = [self init])) {
		delegate = theDelegate;
	}
	return self;
}
- (void)dealloc {
	[rootURL release];
	[credentials release];
	[handlers release];
	[super dealloc];
}

- (void)setDelegate:(id)theDelegate {
	delegate = theDelegate;
}
- (id<MGMWebDavDelegate>)delegate {
	return delegate;
}
- (void)setRootURL:(NSURL *)theURL {
	[rootURL release];
	rootURL = [theURL retain];
}
- (NSURL *)rootURL {
	return rootURL;
}
- (void)setCredentials:(NSURLCredential *)theCredentials {
	[credentials release];
	credentials = [theCredentials retain];
}
- (void)setUser:(NSString *)theUser password:(NSString *)thePassword {
	[self setCredentials:[NSURLCredential credentialWithUser:theUser password:thePassword persistence:NSURLCredentialPersistenceForSession]];
}
- (NSURLCredential *)credentials {
	return credentials;
}

- (void)addHandler:(id)theHandler {
	id<MGMWebDavHandler> handler = theHandler;
	if ([handler respondsToSelector:@selector(setWebDav:)]) [handler setWebDav:self];
	if ([handler respondsToSelector:@selector(request)]) {
		[handlers addObject:handler];
		NSMutableURLRequest *request = [handler request];
		[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
		[request setValue:MGMWebDavUA forHTTPHeaderField:MGMWebDavUserAgent];
		/*if (authentication!=NULL) {
			CFHTTPMessageRef message = [self httpMessageFromRequest:request];
			CFStreamError error;
			CFHTTPMessageApplyCredentials(message, authentication, (CFStringRef)[credentials user], (CFStringRef)[credentials password], &error);
			NSLog(@"%d", error.error);
			CFStringRef value = CFHTTPMessageCopyHeaderFieldValue(message, CFSTR("Authorization"));
			NSLog(@"%@", (NSString *)value);
			if (value!=NULL)
				CFRelease(value);
			value = CFHTTPAuthenticationCopyRealm(authentication);
			NSLog(@"%@", (NSString *)value);
			if (value!=NULL)
				CFRelease(value);
			CFRelease(message);
		}*/
		if ([handler respondsToSelector:@selector(setConnection:)])
			[handler setConnection:[NSURLConnection connectionWithRequest:request delegate:self]];
	}
}
- (id<MGMWebDavHandler>)handlerForConnection:(NSURLConnection *)theConnection {
	for (unsigned long i=0; i<[handlers count]; i++) {
		id<MGMWebDavHandler> handler = [handlers objectAtIndex:i];
		if ([handler respondsToSelector:@selector(connection)]) {
			if ([handler connection]==theConnection)
				return handler;
		}
	}
	return nil;
}
- (void)cancelHandler:(id)theHandler {
	id<MGMWebDavHandler> handler = theHandler;
	if ([handler respondsToSelector:@selector(connection)])
		[[handler connection] cancel];
	[handlers removeObject:handler];
}
- (void)cancelAll {
	while ([handlers count]>0) {
		id<MGMWebDavHandler> handler = [handlers objectAtIndex:0];
		if ([handler respondsToSelector:@selector(connection)])
			[[handler connection] cancel];
		[handlers removeObject:handler];
	}
}

- (CFHTTPMessageRef)httpMessageFromResponse:(NSHTTPURLResponse *)theResponse {
	CFHTTPMessageRef message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, [theResponse statusCode], (CFStringRef)[NSHTTPURLResponse localizedStringForStatusCode:[theResponse statusCode]], kCFHTTPVersion1_1);
	
	NSDictionary *headers = [theResponse allHeaderFields];
	NSArray *keys = [headers allKeys];
	for (int i=0; i<[keys count]; i++) {
		CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef)[keys objectAtIndex:i], (CFStringRef)[headers objectForKey:[keys objectAtIndex:i]]);
	}
	return message;
}
- (CFHTTPMessageRef)httpMessageFromRequest:(NSURLRequest *)theRequest {
	CFHTTPMessageRef message = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)[theRequest HTTPMethod], (CFURLRef)[theRequest URL], kCFHTTPVersion1_1);

	NSDictionary *headers = [theRequest allHTTPHeaderFields];
	NSArray *keys = [headers allKeys];
	for (int i=0; i<[keys count]; i++) {
		CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef)[keys objectAtIndex:i], (CFStringRef)[headers objectForKey:[keys objectAtIndex:i]]);
	}
	
	if ([theRequest HTTPBody]!=nil)
		CFHTTPMessageSetBody(message, (CFDataRef)[theRequest HTTPBody]);
	return message;
}

- (void)connection:(NSURLConnection *)theConnection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)theChallenge {
	//NSHTTPURLResponse *response = (NSHTTPURLResponse *)[theChallenge failureResponse];
	/*NSString *authRequest = [[(NSHTTPURLResponse *)[theChallenge failureResponse] allHeaderFields] objectForKey:@"Www-Authenticate"];
	NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceCharacterSet];
	NSRange range = [authRequest rangeOfCharacterFromSet:whiteSpace];
	NSString *authType = [authRequest substringToIndex:range.location];
	NSArray *parametersArray = [[authRequest substringFromIndex:range.location+range.length] componentsSeparatedByString:@","];
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	NSCharacterSet *quote = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
	for (int i=0; i<[parametersArray count]; i++) {
		NSString *parameter = [[parametersArray objectAtIndex:i] stringByTrimmingCharactersInSet:whiteSpace];
		NSRange range = [parameter rangeOfString:@"="];
		if (range.location!=NSNotFound)
			[parameters setObject:[[parameter substringFromIndex:range.location+range.length] stringByTrimmingCharactersInSet:quote] forKey:[[parameter substringToIndex:range.location] stringByTrimmingCharactersInSet:quote]];
	}
	NSLog(@"%@", authRequest);
	NSLog(@"%@ %@", authType, parameters);*/
	
	/*if (authentication!=NULL)
		CFRelease(authentication);
	CFHTTPMessageRef message = [self httpMessageFromResponse:response];
	authentication = CFHTTPAuthenticationCreateFromResponse(kCFAllocatorDefault, message);
	
	NSLog(@"%p", authentication);
	CFRelease(message);*/
	
	id<MGMWebDavHandler> handler = [self handlerForConnection:theConnection];
	if ([theChallenge previousFailureCount]<=1 && (credentials!=nil || [handler respondsToSelector:@selector(credentailsForChallenge:)])) {
		if ([handler respondsToSelector:@selector(credentailsForChallenge:)]) {
			[[theChallenge sender] useCredential:[handler credentailsForChallenge:theChallenge] forAuthenticationChallenge:theChallenge];
		} else {
			[[theChallenge sender] useCredential:credentials forAuthenticationChallenge:theChallenge];
		}
		return;
	}
	[[theChallenge sender] cancelAuthenticationChallenge:theChallenge];
}
- (void)connection:(NSURLConnection *)theConnection didSendBodyData:(NSInteger)theBytes totalBytesWritten:(NSInteger)theTotalBytes totalBytesExpectedToWrite:(NSInteger)theExpectedBytes {
	id<MGMWebDavHandler> handler = [self handlerForConnection:theConnection];
	if ([handler respondsToSelector:@selector(uploaded:totalBytes:totalBytesExpected:)])
		[handler uploaded:theBytes totalBytes:theTotalBytes totalBytesExpected:theExpectedBytes];
}
- (NSURLRequest *)connection:(NSURLConnection *)theConnection willSendRequest:(NSURLRequest *)theRequest redirectResponse:(NSHTTPURLResponse *)theResponse {
	id<MGMWebDavHandler> handler = [self handlerForConnection:theConnection];
	NSMutableURLRequest *request = nil;
	if ([handler respondsToSelector:@selector(willSendRequest:redirectResponse:)]) {
		request = [[handler willSendRequest:theRequest redirectResponse:theResponse] mutableCopy];
		[request setValue:MGMWebDavUA forHTTPHeaderField:MGMWebDavUserAgent];
		if ([handler respondsToSelector:@selector(setRequest:)]) [handler setRequest:request];
		return [request autorelease];
	}
	request = [theRequest mutableCopy];
	if ([handler respondsToSelector:@selector(request)]) {
		NSMutableURLRequest *oldRequest = [handler request];
		[request setHTTPMethod:[oldRequest HTTPMethod]];
		[request setAllHTTPHeaderFields:[oldRequest allHTTPHeaderFields]];
		[request setHTTPBody:[oldRequest HTTPBody]];
	}
	[request setValue:MGMWebDavUA forHTTPHeaderField:MGMWebDavUserAgent];
	if ([handler respondsToSelector:@selector(setRequest:)]) [handler setRequest:request];
	return [request autorelease];
}
- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	id<MGMWebDavHandler> handler = [self handlerForConnection:theConnection];
	if ([handler respondsToSelector:@selector(didReceiveResponse:)])
		[handler didReceiveResponse:theResponse];
}
- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)theData {
	id<MGMWebDavHandler> handler = [self handlerForConnection:theConnection];
	if ([handler respondsToSelector:@selector(didReceiveData:)])
		[handler didReceiveData:theData];
}
- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)theError {
	id<MGMWebDavHandler> handler = [self handlerForConnection:theConnection];
	if ([handler respondsToSelector:@selector(didFailWithError:)])
		[handler didFailWithError:theError];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
	id<MGMWebDavHandler> handler = [self handlerForConnection:theConnection];
	if ([handler respondsToSelector:@selector(didFinishLoading)])
		[handler didFinishLoading];
	[handlers removeObject:handler];
}
@end