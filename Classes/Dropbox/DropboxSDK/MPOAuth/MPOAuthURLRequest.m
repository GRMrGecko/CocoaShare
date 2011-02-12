//
//  MPOAuthURLRequest.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPOAuthURLRequest.h"
#import "MPURLRequestParameter.h"
#import "MPOAuthSignatureParameter.h"
#import "MPDebug.h"

#import "NSURL+MPURLParameterAdditions.h"
#import "NSString+URLEscapingAdditions.h"

@implementation MPOAuthURLRequest

- (id)initWithURL:(NSURL *)inURL andParameters:(NSArray *)inParameters {
	if ((self = [super init])) {
		url = [inURL retain];
		parameters = inParameters ? [inParameters mutableCopy] : [[NSMutableArray alloc] initWithCapacity:10];
		[self setHTTPMethod:@"GET"];
	}
	return self;
}

- (id)initWithURLRequest:(NSURLRequest *)inRequest {
	if ((self = [super init])) {
		url = [[[inRequest URL] urlByRemovingQuery] retain];
		parameters = [[MPURLRequestParameter parametersFromString:[[inRequest URL] query]] mutableCopy];
		[self setHTTPMethod:[inRequest HTTPMethod]];
	}
	return self;
}

- (oneway void)dealloc {
	[url release];
	[HTTPMethod release];
	[urlRequest release];
	[parameters release];
	[super dealloc];
}

- (void)setURL:(NSURL *)theURL {
	[url release];
	url = [theURL retain];
}
- (NSURL *)url {
	return url;
}
- (void)setHTTPMethod:(NSString *)theMethod {
	[HTTPMethod release];
	HTTPMethod = [theMethod retain];
}
- (NSString *)HTTPMethod {
	return HTTPMethod;
}
- (void)setURLRequest:(NSURLRequest *)theRequest {
	[urlRequest release];
	urlRequest = [theRequest retain];
}
- (NSURLRequest *)urlRequest {
	return urlRequest;
}
- (void)setParameters:(NSMutableArray *)theParameters {
	[parameters release];
	parameters = [theParameters retain];
}
- (NSMutableArray *)parameters {
	return parameters;
}

#pragma mark -

- (NSMutableURLRequest*)urlRequestSignedWithSecret:(NSString *)inSecret usingMethod:(NSString *)inScheme {
	[parameters sortUsingSelector:@selector(compare:)];

	NSMutableURLRequest *aRequest = [[NSMutableURLRequest alloc] init];
	NSMutableString *parameterString = [[NSMutableString alloc] initWithString:[MPURLRequestParameter parameterStringForParameters:parameters]];
	MPOAuthSignatureParameter *signatureParameter = [[MPOAuthSignatureParameter alloc] initWithText:parameterString andSecret:inSecret forRequest:self usingMethod:inScheme];
	[parameterString appendFormat:@"&%@", [signatureParameter URLEncodedParameterString]];
	
	[aRequest setHTTPMethod:HTTPMethod];
	
	if ([[self HTTPMethod] isEqualToString:@"GET"] && [parameters count]) {
		NSString *urlString = [NSString stringWithFormat:@"%@?%@", [url absoluteString], parameterString];
		MPLog( @"urlString - %@", urlString);
		
		[aRequest setURL:[NSURL URLWithString:urlString]];
	} else if ([[self HTTPMethod] isEqualToString:@"POST"]) {
		NSData *postData = [parameterString dataUsingEncoding:NSUTF8StringEncoding];
		MPLog(@"urlString - %@", url);
		MPLog(@"postDataString - %@", parameterString);
		
		[aRequest setURL:url];
		[aRequest setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
		[aRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[aRequest setHTTPBody:postData];
	} else {
		[NSException raise:@"UnhandledHTTPMethodException" format:@"The requested HTTP method, %@, is not supported", HTTPMethod];
	}
	
	[parameterString release];
	[signatureParameter release];		
	
	urlRequest = [aRequest retain];
	[aRequest release];
		
	return aRequest;
}

#pragma mark -

- (void)addParameters:(NSArray *)inParameters {
	[parameters addObjectsFromArray:inParameters];
}

@end
