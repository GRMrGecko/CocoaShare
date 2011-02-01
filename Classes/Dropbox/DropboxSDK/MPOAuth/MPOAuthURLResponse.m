//
//  MPOAuthURLResponse.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPOAuthURLResponse.h"

@implementation MPOAuthURLResponse

- (id)init {
	if (self = [super init]) {
		
	}
	return self;
}

- (void)dealloc {
	[urlResponse release];
	[oauthParameters release];
	[super dealloc];
}

- (void)setResponse:(NSURLResponse *)theResponse {
	[urlResponse release];
	urlResponse = [theResponse retain];
}
- (NSURLResponse *)response {
	return urlResponse;
}

- (void)setOauthParameters:(NSDictionary *)theParameters {
	[oauthParameters release];
	oauthParameters = [theParameters retain];
}
- (NSDictionary *)oauthParameters {
	return oauthParameters;
}
@end
