//
//  MGMGeneralPane.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>
#import <MGMUsers/MGMUsers.h>

@interface MGMGeneralPane : MGMPreferencesPane {
	IBOutlet NSView *view;
	IBOutlet NSMatrix *display;
	IBOutlet NSButton *startup;
	IBOutlet NSMatrix *uploadName;
	IBOutlet NSTextField *historyCountField;
	IBOutlet NSButton *growlErrors;
	IBOutlet NSTextField *uploadLimit;
	IBOutlet NSPopUpButton *MUThemesButton;
}
- (id)initWithPreferences:(MGMPreferences *)thePreferences;
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem;
+ (NSString *)title;
- (NSView *)preferencesView;

- (IBAction)changeDisplay:(id)sender;
- (IBAction)changeStartup:(id)sender;
- (IBAction)changeUploadName:(id)sender;
- (IBAction)changeHistoryCount:(id)sender;
- (IBAction)changeGrowlErrors:(id)sender;
- (IBAction)changeUploadLimit:(id)sender;
- (IBAction)changeMUTheme:(id)sender;
@end