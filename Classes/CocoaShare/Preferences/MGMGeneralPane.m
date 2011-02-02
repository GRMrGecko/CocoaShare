//
//  MGMGeneralPane.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMGeneralPane.h"
#import "MGMController.h"
#import "MGMLoginItems.h"

@implementation MGMGeneralPane
- (id)initWithPreferences:(MGMPreferences *)thePreferences {
	if (self = [super initWithPreferences:thePreferences]) {
		if (![NSBundle loadNibNamed:@"GeneralPane" owner:self]) {
			NSLog(@"Error loading General pane");
		} else {
			[display selectCellAtRow:[preferences integerForKey:MGMDisplay] column:0];
			[startup setState:([preferences boolForKey:MGMStartup] ? NSOnState : NSOffState)];
			[uploadName selectCellAtRow:[preferences integerForKey:MGMUploadName] column:0];
			[historyCountField setIntValue:[preferences integerForKey:MGMHistoryCount]];
			[growlErrors setState:([preferences boolForKey:MGMGrowlErrors] ? NSOnState : NSOffState)];
		}
	}
	return self;
}
- (void)dealloc {
	[view release];
	[super dealloc];
}
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem {
	[theItem setLabel:[self title]];
    [theItem setPaletteLabel:[theItem label]];
    [theItem setImage:[NSImage imageNamed:@"General"]];
}
+ (NSString *)title {
	return [@"General" localized];
}
- (NSView *)preferencesView {
	return view;
}

- (IBAction)changeDisplay:(id)sender {
	int previousDisplay = [preferences integerForKey:MGMDisplay];
	int newDisplay = [display selectedRow];
	[preferences setInteger:newDisplay forKey:MGMDisplay];
	
	MGMController *controller = [MGMController sharedController];
	
	if (newDisplay==0) {
		if (previousDisplay!=1)
			[controller setDockHidden:NO];
		[controller removeMenu];
	} else if (newDisplay==1) {
		if (previousDisplay!=0)
			[controller setDockHidden:NO];
		[controller addMenu];
	} else if (newDisplay==2) {
		[controller setDockHidden:YES];
		[controller addMenu];
	}
}
- (IBAction)changeStartup:(id)sender {
	BOOL openStartup = ([startup state]==NSOnState);
	[preferences setBool:openStartup forKey:MGMStartup];
	if (openStartup)
		[[MGMLoginItems items] addSelf];
	else
		[[MGMLoginItems items] removeSelf];
}
- (IBAction)changeUploadName:(id)sender {
	[preferences setInteger:[uploadName selectedRow] forKey:MGMUploadName];
}
- (IBAction)changeHistoryCount:(id)sender {
	[preferences setInteger:[historyCountField intValue] forKey:MGMHistoryCount];
}
- (IBAction)changeGrowlErrors:(id)sender {
	[preferences setBool:([growlErrors state]==NSOnState) forKey:MGMGrowlErrors];
}
@end