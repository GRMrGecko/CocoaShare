//
//  MGMAutoUploadPane.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMAutoUploadPane.h"
#import "MGMController.h"
#import "RegexKitLite.h"
#import <GeckoReporter/GeckoReporter.h>

@implementation MGMAutoUploadPane
- (id)initWithPreferences:(MGMPreferences *)thePreferences {
	if (self = [super initWithPreferences:thePreferences]) {
		if (![NSBundle loadNibNamed:@"AutoUploadPane" owner:self]) {
			NSLog(@"Error loading Auto Upload pane");
		} else {
			controller = [MGMController sharedController];
			[filtersTable reloadData];
			[self tableViewSelectionDidChange:nil];
		}
	}
	return self;
}
- (void)dealloc {
	[view release];
	[addMenu release];
	[super dealloc];
}
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem {
	[theItem setLabel:[self title]];
    [theItem setPaletteLabel:[theItem label]];
    [theItem setImage:[NSImage imageNamed:@"AutoUpload"]];
}
+ (NSString *)title {
	return [@"Auto Upload" localized];
}
- (NSView *)preferencesView {
	return view;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[controller filters] count];
}
- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theTableColumn row:(NSInteger)rowIndex {
	if ([[theTableColumn identifier] isEqual:@"filter"]) {
		return [[[controller filters] objectAtIndex:rowIndex] objectForKey:MGMFFilter];
	} else if ([[theTableColumn identifier] isEqual:@"path"]) {
		return [[[controller filters] objectAtIndex:rowIndex] objectForKey:MGMFPath];
	}
	return @"";
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([filtersTable selectedRow]>=0) {
		currentFilter = [filtersTable selectedRow];
		[removeButton setEnabled:YES];
		[pathField setEnabled:YES];
		[pathField setStringValue:[[[controller filters] objectAtIndex:currentFilter] objectForKey:MGMFPath]];
		[choosePathButton setEnabled:YES];
		[filterField setEnabled:YES];
		[filterField setStringValue:[[[controller filters] objectAtIndex:currentFilter] objectForKey:MGMFFilter]];
		[testField setEnabled:YES];
	} else {
		[removeButton setEnabled:NO];
		[pathField setEnabled:NO];
		[pathField setStringValue:@""];
		[choosePathButton setEnabled:NO];
		[filterField setEnabled:NO];
		[filterField setStringValue:@""];
		[testField setEnabled:NO];
	}
}

- (IBAction)addFilter:(id)sender {
	NSPoint location = [addButton frame].origin;
	location.y += 20;
	NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseUp location:location modifierFlags:0 timestamp:0 windowNumber:[[preferences preferencesWindow] windowNumber] context:nil eventNumber:0 clickCount:1 pressure:0];
	[NSMenu popUpContextMenu:addMenu withEvent:event forView:addButton];
}
- (IBAction)addNewFilter:(id)sender {
	[[controller filters] addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"", MGMFPath, @"", MGMFFilter, nil]];
	[filtersTable reloadData];
	int index = [[controller filters] count]-1;
	[filtersTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[NSThread detachNewThreadSelector:@selector(saveFilters) toTarget:controller withObject:nil];
}
- (IBAction)addScreenshotFilter:(id)sender {
	NSString *filter = nil;
	if ([[MGMSystemInfo info] isAfterLeopard])
		filter = @"MD:(?i)isScreenCapture\\z";
	else
		filter = [@"(?i)Picture [0-9]+\\.(?:bmp|gif|jpg|pdf|pict|png|sgi|tga|tif|tiff)\\z" localized];
	[[controller filters] addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"~/Desktop", MGMFPath, filter, MGMFFilter, nil]];
	[filtersTable reloadData];
	int index = [[controller filters] count]-1;
	[filtersTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[NSThread detachNewThreadSelector:@selector(saveFilters) toTarget:controller withObject:nil];
}
- (IBAction)removeFilter:(id)sender {
	if ([filtersTable selectedRow]>=0) {
		[[controller filters] removeObjectAtIndex:[filtersTable selectedRow]];
		[filtersTable deselectAll:self];
		[filtersTable reloadData];
		[NSThread detachNewThreadSelector:@selector(saveFilters) toTarget:controller withObject:nil];
	}
}

- (IBAction)choosePath:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setTitle:[@"Choose Folder" localized]];
	[panel setPrompt:[@"Choose" localized]];
	int returnCode = [panel runModal];
	if (returnCode==NSOKButton) {
		NSString *path = [[[panel URLs] objectAtIndex:0] path];
		[pathField setStringValue:path];
		NSMutableDictionary *filter = [[[controller filters] objectAtIndex:currentFilter] mutableCopy];
		[filter setObject:path forKey:MGMFPath];
		[[controller filters] replaceObjectAtIndex:currentFilter withObject:filter];
		[filter release];
		[filtersTable reloadData];
		[NSThread detachNewThreadSelector:@selector(saveFilters) toTarget:controller withObject:nil];
	}
}
- (IBAction)pathChanged:(id)sender {
	NSMutableDictionary *filter = [[[controller filters] objectAtIndex:currentFilter] mutableCopy];
	[filter setObject:[pathField stringValue] forKey:MGMFPath];
	[[controller filters] replaceObjectAtIndex:currentFilter withObject:filter];
	[filter release];
	[filtersTable reloadData];
	[NSThread detachNewThreadSelector:@selector(saveFilters) toTarget:controller withObject:nil];
}
- (IBAction)filterChanged:(id)sender {
	NSMutableDictionary *filter = [[[controller filters] objectAtIndex:currentFilter] mutableCopy];
	[filter setObject:[filterField stringValue] forKey:MGMFFilter];
	[[controller filters] replaceObjectAtIndex:currentFilter withObject:filter];
	[filter release];
	[filtersTable reloadData];
	[NSThread detachNewThreadSelector:@selector(saveFilters) toTarget:controller withObject:nil];
	[self test:self];
}
- (IBAction)test:(id)sender {
	NSString *filter = [filterField stringValue];
	if ([filter hasPrefix:@"MD:"]) {
		if ([filter hasPrefix:@"MD: "])
			filter = [filter substringFromIndex:4];
		else
			filter = [filter substringFromIndex:3];
	}
	BOOL result = [[testField stringValue] isMatchedByRegex:filter];
	[testStatusField setStringValue:(result ? [@"Match" localized] : [@"No Match" localized])];
}
@end