//
//  MGMWebDavAddons.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMWebDavAddons.h"

@implementation NSURL (MGMWebDavAddons)
- (NSURL *)appendPathComponent:(NSString *)theComponent {
	NSMutableString *string = [NSMutableString string];
	if ([self scheme]!=nil)
		[string appendFormat:@"%@://", [self scheme]];
	if ([self host]!=nil)
		[string appendString:[self host]];
	if ([self port]!=0)
		[string appendFormat:@":%d", [self port]];
	if ([self path]!=nil) {
		if (theComponent!=nil) {
			[string appendString:[[self path] stringByAppendingPathComponent:theComponent]];
			if ([theComponent isEqual:@""] || [theComponent hasSuffix:@"/"])
				[string appendString:@"/"];
		} else {
			[string appendString:[self path]];
			if ([[self absoluteString] hasSuffix:@"/"])
				[string appendString:@"/"];
		}
	} else {
		[string appendString:[@"/" stringByAppendingPathComponent:theComponent]];
	}
	if ([self query]!=nil)
		[string appendFormat:@"?%@", [self query]];
	return [NSURL URLWithString:string];
}
@end