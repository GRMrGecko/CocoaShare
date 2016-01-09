//
//  MGMResizePane.m
//  CocoaShare
//
//  Created by Mr. Gecko on 12/30/15.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//
//

#import "MGMResizePane.h"
#import "MGMController.h"

@implementation MGMResizePane
- (id)initWithPreferences:(MGMPreferences *)thePreferences {
	if ((self = [super initWithPreferences:thePreferences])) {
		if (![NSBundle loadNibNamed:@"ResizePane" owner:self]) {
			NSLog(@"Error loading Events pane");
		} else {
			controller = [MGMController sharedController];
			[logicTable reloadData];
			[filtersTable reloadData];
			[self tableViewSelectionDidChange:nil];
			AirPortNetworks = [NSMutableArray new];
			NSDictionary *AirPortPreferences = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist"];
			if ([AirPortPreferences objectForKey:@"KnownNetworks"]!=nil) {// Leopard and above.
				NSDictionary *knownNetworks = [AirPortPreferences objectForKey:@"KnownNetworks"];
				NSArray *networkKeys = [knownNetworks allKeys];
				for (int i=0; i<[networkKeys count]; i++) {
					NSDictionary *network = [knownNetworks objectForKey:[networkKeys objectAtIndex:i]];
					NSString *SSID = [network objectForKey:@"SSIDString"];
					if (SSID==nil) {
						SSID = [network objectForKey:@"SSID_STR"];//Leopard
					}
					[AirPortNetworks addObject:SSID];
				}
			} else if ([AirPortPreferences objectForKey:@"List of known networks"]!=nil) {// Tiger.
				NSArray *knownNetworks = [AirPortPreferences objectForKey:@"List of known networks"];
				for (int i=0; i<[knownNetworks count]; i++) {
					NSDictionary *network = [knownNetworks objectAtIndex:i];
					NSString *SSID = [[[NSString alloc] initWithData:[network objectForKey:@"SSID"] encoding:NSUTF8StringEncoding] autorelease];
					[AirPortNetworks addObject:SSID];
				}
			}
			[networksTable reloadData];
		}
	}
	return self;
}
- (void)dealloc {
	[view release];
	[filtersWindow release];
	[networksWindow release];
	[AirPortNetworks release];
	[super dealloc];
}
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem {
	[theItem setLabel:[self title]];
	[theItem setPaletteLabel:[theItem label]];
	[theItem setImage:[NSImage imageNamed:@"Resize"]];
}
+ (NSString *)title {
	return [@"Resize" localized];
}
- (NSView *)preferencesView {
	return view;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
	if (theTableView==logicTable) {
		return [[controller resizeLogic] count];
	} else if (theTableView==filtersTable) {
		return [[controller filters] count];
	} else if (theTableView==networksTable) {
		return [AirPortNetworks count];
	}
	return 0;
}
- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theTableColumn row:(NSInteger)rowIndex {
	if (theTableView==logicTable) {
		if ([[theTableColumn identifier] isEqual:@"size"]) {
			NSDictionary *resizeLogic = [[controller resizeLogic] objectAtIndex:rowIndex];
			if ([[resizeLogic objectForKey:MGMRScale] intValue]!=0) {
				return [NSString stringWithFormat:@"%d%%", [[resizeLogic objectForKey:MGMRScale] intValue]];
			} else {
				return [NSString stringWithFormat:@"%dx%d", [[resizeLogic objectForKey:MGMRWidth] intValue], [[resizeLogic objectForKey:MGMRHeight] intValue]];
			}
		} else if ([[theTableColumn identifier] isEqual:@"logic"]) {
			NSMutableString *result = [NSMutableString string];
			NSDictionary *resizeLogic = [[controller resizeLogic] objectAtIndex:rowIndex];
			if ([[resizeLogic objectForKey:MGMRFilters] count]!=0 && [[resizeLogic objectForKey:MGMRNetworks] count]!=0) {
				[result appendString:@"Some networks and filters"];
			} else if ([[resizeLogic objectForKey:MGMRFilters] count]>=1) {
				[result appendString:@"Some filters"];
			} else if ([[resizeLogic objectForKey:MGMRNetworks] count]>=1) {
				if ([[resizeLogic objectForKey:MGMRNetworks] count]==1) {
					[result appendFormat:@"Network %@", [[resizeLogic objectForKey:MGMRNetworks] objectAtIndex:0]];
				} else {
					[result appendFormat:@"Networks including %@", [[resizeLogic objectForKey:MGMRNetworks] objectAtIndex:0]];
				}
			}
			if (![[resizeLogic objectForKey:MGMRIPPrefix] isEqual:@""]) {
				if ([result isEqual:@""]) {
					[result appendFormat:@"IP Prefix equals %@", [resizeLogic objectForKey:MGMRIPPrefix]];
				} else {
					[result appendString:@" and an IP Prefix"];
				}
			}
			if ([result isEqual:@""]) {
				return @"Anything";
			}
			return result;
		}
	} else if (theTableView==filtersTable) {
		if ([[theTableColumn identifier] isEqual:@"filter"]) {
			return [[[controller filters] objectAtIndex:rowIndex] objectForKey:MGMFFilter];
		} else if ([[theTableColumn identifier] isEqual:@"path"]) {
			return [[[controller filters] objectAtIndex:rowIndex] objectForKey:MGMFPath];
		}
	} else if (theTableView==networksTable) {
		return [AirPortNetworks objectAtIndex:rowIndex];
	}
	return @"";
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if (aNotification==nil || [aNotification object]==logicTable) {
		if ([logicTable selectedRow]>=0) {
			currentLogic = [logicTable selectedRow];
			NSMutableDictionary *logic = [[controller resizeLogic] objectAtIndex:currentLogic];
			[removeButton setEnabled:YES];
			[widthField setEditable:YES];
			[widthField setIntValue:[[logic objectForKey:MGMRWidth] intValue]];
			[heightField setEditable:YES];
			[heightField setIntValue:[[logic objectForKey:MGMRHeight] intValue]];
			[scaleField setEditable:YES];
			[scaleField setIntValue:[[logic objectForKey:MGMRScale] intValue]];
			[filtersButton setEnabled:YES];
			NSMutableIndexSet *filtersIndexSet = [NSMutableIndexSet indexSet];
			for (int i=0; i<[[controller filters] count]; i++) {
				if ([[logic objectForKey:MGMRFilters] containsObject:[[[controller filters] objectAtIndex:i] objectForKey:MGMFID]]) {
					[filtersIndexSet addIndex:i];
				}
			}
			[filtersTable selectRowIndexes:filtersIndexSet byExtendingSelection:NO];
			[networksButton setEnabled:YES];
			NSMutableIndexSet *networksIndexSet = [NSMutableIndexSet indexSet];
			for (int i=0; i<[AirPortNetworks count]; i++) {
				if ([[logic objectForKey:MGMRNetworks] containsObject:[AirPortNetworks objectAtIndex:i]]) {
					[networksIndexSet addIndex:i];
				}
			}
			[networksTable selectRowIndexes:networksIndexSet byExtendingSelection:NO];
			[IPPrefixField setEditable:YES];
			[IPPrefixField setStringValue:[logic objectForKey:MGMRIPPrefix]];
		} else {
			[removeButton setEnabled:NO];
			[widthField setEditable:NO];
			[widthField setStringValue:@""];
			[heightField setEditable:NO];
			[heightField setStringValue:@""];
			[scaleField setEditable:NO];
			[scaleField setStringValue:@""];
			[filtersButton setEnabled:NO];
			[networksButton setEnabled:NO];
			[IPPrefixField setEditable:NO];
			[IPPrefixField setStringValue:@""];
			[logicTable reloadData];
		}
	}
}

- (IBAction)addLogic:(id)sender {
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	NSString *uuidString = [(NSString *)CFUUIDCreateString(NULL, uuid) autorelease];
	CFRelease(uuid);
	[[controller resizeLogic] addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:uuidString, MGMRID, [NSNumber numberWithInt:0], MGMRWidth, [NSNumber numberWithInt:0], MGMRHeight, [NSNumber numberWithInt:0], MGMRScale, [NSMutableArray array], MGMRFilters, [NSMutableArray array], MGMRNetworks, @"", MGMRIPPrefix, nil]];
	[logicTable reloadData];
	int index = [[controller resizeLogic] count]-1;
	[logicTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[NSThread detachNewThreadSelector:@selector(saveResizeLogic) toTarget:controller withObject:nil];
}
- (IBAction)removeLogic:(id)sender {
	if ([logicTable selectedRow]>=0) {
		int row = [logicTable selectedRow];
		[logicTable deselectAll:self];
		[[controller resizeLogic] removeObjectAtIndex:row];
		[logicTable reloadData];
		[NSThread detachNewThreadSelector:@selector(saveResizeLogic) toTarget:controller withObject:nil];
	}
}


- (IBAction)selectFilters:(id)sender {
	[NSApp beginSheet:filtersWindow modalForWindow:[preferences preferencesWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
}
- (IBAction)saveFilters:(id)sender {
	[NSApp endSheet:filtersWindow];
	[filtersWindow orderOut:sender];
	
	NSMutableDictionary *logic = [[controller resizeLogic] objectAtIndex:currentLogic];
	NSMutableArray *filters = [logic objectForKey:MGMRFilters];
	[filters removeAllObjects];
	NSIndexSet *indexSet = [filtersTable selectedRowIndexes];
	NSUInteger currentIndex = [indexSet firstIndex];
	while (currentIndex!=NSNotFound) {
		[filters addObject:[[[controller filters] objectAtIndex:currentIndex] objectForKey:MGMFID]];
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
	}
	[NSThread detachNewThreadSelector:@selector(saveResizeLogic) toTarget:controller withObject:nil];
}

- (IBAction)selectNetworks:(id)sender {
	[NSApp beginSheet:networksWindow modalForWindow:[preferences preferencesWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
}
- (IBAction)saveNetworks:(id)sender {
	[NSApp endSheet:networksWindow];
	[networksWindow orderOut:sender];
	
	NSMutableDictionary *logic = [[controller resizeLogic] objectAtIndex:currentLogic];
	NSMutableArray *networks = [logic objectForKey:MGMRNetworks];
	[networks removeAllObjects];
	NSIndexSet *indexSet = [networksTable selectedRowIndexes];
	NSUInteger currentIndex = [indexSet firstIndex];
	while (currentIndex!=NSNotFound) {
		[networks addObject:[AirPortNetworks objectAtIndex:currentIndex]];
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
	}
	[NSThread detachNewThreadSelector:@selector(saveResizeLogic) toTarget:controller withObject:nil];
}

- (IBAction)fieldsChanged:(id)sender {
	NSMutableDictionary *logic = [[controller resizeLogic] objectAtIndex:currentLogic];
	int width = [widthField intValue];
	if (width<0)
		width = 0;
	[logic setObject:[NSNumber numberWithInt:width] forKey:MGMRWidth];
	[widthField setIntValue:width];
	int height = [heightField intValue];
	if (height<0)
		height = 0;
	[logic setObject:[NSNumber numberWithInt:height] forKey:MGMRHeight];
	[heightField setIntValue:height];
	int scale = [scaleField intValue];
	if (scale<0)
		scale = 0;
	if (scale>100)
		scale = 100;
	[logic setObject:[NSNumber numberWithInt:scale] forKey:MGMRScale];
	[scaleField setIntValue:scale];
	[logic setObject:[IPPrefixField stringValue] forKey:MGMRIPPrefix];
	[NSThread detachNewThreadSelector:@selector(saveResizeLogic) toTarget:controller withObject:nil];
}
@end
