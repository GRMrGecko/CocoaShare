//
//  MGMAccountPane.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>
#import <MGMUsers/MGMUsers.h>

@class MGMController;
@interface MGMAccountPane : MGMPreferencesPane {
	MGMController *controller;
	IBOutlet NSView *view;
	IBOutlet NSPopUpButton *typePopUp;
	
	NSView *plugInView;
}
- (id)initWithPreferences:(MGMPreferences *)thePreferences;
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem;
+ (NSString *)title;
- (NSView *)preferencesView;

- (IBAction)typeChanged:(id)sender;
@end