//
//  MGMLocalized.m
//  CocoaShare
//
//  Created by Mr. Gecko on 2/2/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMLocalized.h"

@implementation NSString (MGMLocalized)
- (NSString *)localized {
	return [self localizedFor:nil inTable:nil];
}
- (NSString *)localizedInTable:(NSString *)theTable {
	return [self localizedFor:nil inTable:theTable];
}
- (NSString *)localizedFor:(id)sender {
	return [self localizedFor:sender inTable:nil];
}
- (NSString *)localizedFor:(id)sender inTable:(NSString *)theTable {
	NSString *localized = nil;
	if (sender!=nil)
		localized = [[NSBundle bundleForClass:[sender class]] localizedStringForKey:self value:@"" table:theTable];
	if ([localized isEqual:@""] || localized==nil)
		localized = [[NSBundle mainBundle] localizedStringForKey:self value:@"" table:theTable];
	return localized;
}
@end