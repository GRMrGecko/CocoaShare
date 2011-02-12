//
//  MGMEventsPane.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>
#import <MGMUsers/MGMUsers.h>

@interface MGMEventsPane : MGMPreferencesPane <NSSoundDelegate> {
	IBOutlet NSView *view;
	IBOutlet NSPopUpButton *eventPopUp;
	IBOutlet NSPopUpButton *soundPopUp;
	IBOutlet NSTextField *moveToField;
	IBOutlet NSButton *moveToChooseButton;
	IBOutlet NSMatrix *deleteMatrix;
	IBOutlet NSButton *growlButton;
	
	NSSound *sound;
}
- (id)initWithPreferences:(MGMPreferences *)thePreferences;
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem;
+ (NSString *)title;
- (NSView *)preferencesView;

- (NSArray *)sounds;

- (IBAction)eventChange:(id)sender;
- (IBAction)soundChange:(id)sender;

- (IBAction)moveChange:(id)sender;
- (IBAction)moveChoose:(id)sender;

- (IBAction)deleteChange:(id)sender;
- (IBAction)growlChange:(id)sender;
@end