//
//  MGMResizePane.h
//  CocoaShare
//
//  Created by Mr. Gecko on 12/30/15.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//
//

#import <Cocoa/Cocoa.h>
#import <MGMUsers/MGMUsers.h>

@class MGMController;

@interface MGMResizePane : MGMPreferencesPane {
	MGMController *controller;
	IBOutlet NSView *view;
	IBOutlet NSTableView *logicTable;
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *removeButton;
	
	IBOutlet NSTextField *widthField;
	IBOutlet NSTextField *heightField;
	IBOutlet NSTextField *scaleField;
	
	IBOutlet NSButton *filtersButton;
	IBOutlet NSWindow *filtersWindow;
	IBOutlet NSTableView *filtersTable;
	
	IBOutlet NSButton *networksButton;
	IBOutlet NSWindow *networksWindow;
	IBOutlet NSTableView *networksTable;
	
	IBOutlet NSTextField *IPPrefixField;
	
	NSMutableArray *AirPortNetworks;
	
	int currentLogic;
}
- (id)initWithPreferences:(MGMPreferences *)thePreferences;
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem;
+ (NSString *)title;
- (NSView *)preferencesView;

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

- (IBAction)addLogic:(id)sender;
- (IBAction)removeLogic:(id)sender;

- (IBAction)selectFilters:(id)sender;
- (IBAction)saveFilters:(id)sender;

- (IBAction)selectNetworks:(id)sender;
- (IBAction)saveNetworks:(id)sender;

- (IBAction)fieldsChanged:(id)sender;
@end
