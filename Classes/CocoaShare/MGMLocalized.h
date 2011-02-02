//
//  MGMLocalized.h
//  CocoaShare
//
//  Created by Mr. Gecko on 2/2/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@interface NSString (MGMLocalized)
- (NSString *)localized;
- (NSString *)localizedInTable:(NSString *)theTable;
- (NSString *)localizedFor:(id)sender;
- (NSString *)localizedFor:(id)sender inTable:(NSString *)theTable;
@end