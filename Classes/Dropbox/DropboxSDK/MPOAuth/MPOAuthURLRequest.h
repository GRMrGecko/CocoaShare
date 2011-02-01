//
//  MPOAuthURLRequest.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPOAuthURLRequest : NSObject {
@private
	NSURL			*url;
	NSString		*HTTPMethod;
	NSURLRequest	*urlRequest;
	NSMutableArray	*parameters;
}

- (void)setURL:(NSURL *)theURL;
- (NSURL *)url;
- (void)setHTTPMethod:(NSString *)theMethod;
- (NSString *)HTTPMethod;
- (void)setURLRequest:(NSURLRequest *)theRequest;
- (NSURLRequest *)urlRequest;
- (void)setParameters:(NSMutableArray *)theParameters;
- (NSMutableArray *)parameters;

- (id)initWithURL:(NSURL *)inURL andParameters:(NSArray *)parameters;
- (id)initWithURLRequest:(NSURLRequest *)inRequest;

- (void)addParameters:(NSArray *)inParameters;

- (NSMutableURLRequest*)urlRequestSignedWithSecret:(NSString *)inSecret usingMethod:(NSString *)inScheme;

@end
