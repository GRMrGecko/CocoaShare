//
//  MPOAuthURLResponse.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPOAuthURLResponse : NSObject {
	NSURLResponse	*urlResponse;
	NSDictionary	*oauthParameters;
}
- (void)setResponse:(NSURLResponse *)theResponse;
- (NSURLResponse *)response;

- (void)setOauthParameters:(NSDictionary *)theParameters;
- (NSDictionary *)oauthParameters;
@end
