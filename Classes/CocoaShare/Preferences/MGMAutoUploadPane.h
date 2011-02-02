//
//  MGMAutoUploadPane.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>
#import <MGMUsers/MGMUsers.h>

@class MGMController;

@interface MGMAutoUploadPane : MGMPreferencesPane {
	MGMController *controller;
	IBOutlet NSView *view;
	IBOutlet NSTableView *filtersTable;
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *removeButton;
	IBOutlet NSTextField *pathField;
	IBOutlet NSButton *choosePathButton;
	IBOutlet NSTextField *filterField;
	IBOutlet NSTextField *testField;
	IBOutlet NSTextField *testStatusField;
	
	IBOutlet NSMenu *addMenu;
	
	int currentFilter;
}
- (id)initWithPreferences:(MGMPreferences *)thePreferences;
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem;
+ (NSString *)title;
- (NSView *)preferencesView;

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

- (IBAction)addFilter:(id)sender;
- (IBAction)addNewFilter:(id)sender;
- (IBAction)addScreenshotFilter:(id)sender;
- (IBAction)removeFilter:(id)sender;

- (IBAction)choosePath:(id)sender;
- (IBAction)pathChanged:(id)sender;
- (IBAction)filterChanged:(id)sender;
- (IBAction)test:(id)sender;
@end