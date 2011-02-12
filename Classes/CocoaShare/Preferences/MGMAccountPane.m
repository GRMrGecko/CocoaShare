//
//  MGMAccountPane.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMAccountPane.h"
#import "MGMController.h"

@implementation MGMAccountPane
- (id)initWithPreferences:(MGMPreferences *)thePreferences {
	if ((self = [super initWithPreferences:thePreferences])) {
		if (![NSBundle loadNibNamed:@"AccountPane" owner:self]) {
			NSLog(@"Error loading Account pane");
		} else {
			controller = [MGMController sharedController];
			NSArray *accountPlugIns = [controller accountPlugIns];
			for (int i=0; i<[accountPlugIns count]; i++) {
				id<MGMPlugInProtocol> plugIn = [accountPlugIns objectAtIndex:i];
				NSString *name = ([plugIn respondsToSelector:@selector(plugInName)] ? [plugIn plugInName] : [@"Unknown name" localized]);
				[typePopUp addItemWithTitle:name];
			}
			[typePopUp selectItemAtIndex:[controller currentPlugInIndex]];
			if ([[controller currentPlugIn] respondsToSelector:@selector(plugInView)]) plugInView = [[controller currentPlugIn] plugInView];
			NSRect plugInFrame = NSZeroRect;
			if (plugInView!=nil)
				plugInFrame = [plugInView frame];
			[view setFrame:NSMakeRect(0, 0, (plugInFrame.size.width<130 ? 130 : plugInFrame.size.width), (plugInFrame.size.height<20 ? 20 : plugInFrame.size.height)+36)];
			[view addSubview:plugInView];
		}
	}
	return self;
}
- (void)dealloc {
	[view release];
	if ([[controller currentPlugIn] respondsToSelector:@selector(releaseView)]) [[controller currentPlugIn] releaseView];
	[super dealloc];
}
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem {
	[theItem setLabel:[self title]];
    [theItem setPaletteLabel:[theItem label]];
    [theItem setImage:[NSImage imageNamed:@"Account"]];
}
+ (NSString *)title {
	return [@"Account" localized];
}
- (NSView *)preferencesView {
	return view;
}

- (IBAction)typeChanged:(id)sender {
	[plugInView removeFromSuperview];
	plugInView = nil;
	if ([[controller currentPlugIn] respondsToSelector:@selector(releaseView)]) [[controller currentPlugIn] releaseView];
	[controller setCurrentPlugIn:[[controller accountPlugIns] objectAtIndex:[typePopUp indexOfSelectedItem]]];
	[typePopUp selectItemAtIndex:[controller currentPlugInIndex]];
	if ([[controller currentPlugIn] respondsToSelector:@selector(plugInView)]) plugInView = [[controller currentPlugIn] plugInView];
	NSRect plugInFrame = NSZeroRect;
	if (plugInView!=nil)
		plugInFrame = [plugInView frame];
	NSRect viewFrame = NSMakeRect(0, 0, (plugInFrame.size.width<130 ? 130 : plugInFrame.size.width), (plugInFrame.size.height<20 ? 20 : plugInFrame.size.height)+36);
	
	NSWindow *preferencesWindow = [preferences preferencesWindow];
	NSSize toolbarSize = [preferencesWindow toolbarSize];
    NSRect currentRect = [preferencesWindow frame];
    [preferencesWindow setFrame:NSMakeRect(currentRect.origin.x, currentRect.origin.y - ((viewFrame.size.height+toolbarSize.height) - currentRect.size.height), viewFrame.size.width, viewFrame.size.height+toolbarSize.height) display:YES animate:YES];
	[view addSubview:plugInView];
}
@end