//
//  MGMWebDavAddons.h
//  CocoaShare
//
//  Created by James on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@interface NSURL (MGMWebDavAddons)
- (NSURL *)appendPathComponent:(NSString *)theComponent;
@end