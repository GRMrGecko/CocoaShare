//
//  MGMEventsPane.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMEventsPane.h"
#import "MGMController.h"
#import <MGMUsers/MGMUsers.h>

@implementation MGMEventsPane
- (id)initWithPreferences:(MGMPreferences *)thePreferences {
	if ((self = [super initWithPreferences:thePreferences])) {
		if (![NSBundle loadNibNamed:@"EventsPane" owner:self]) {
			NSLog(@"Error loading Events pane");
		} else {
			NSArray *sounds = [self sounds];
			NSMenu *soundsMenu = [[NSMenu new] autorelease];
			NSMenuItem *noneMenu = [[NSMenuItem new] autorelease];
			[noneMenu setTitle:[@"No Sound" localized]];
			[soundsMenu addItem:noneMenu];
			[soundsMenu addItem:[NSMenuItem separatorItem]];
			int selectedPath = -1;
			NSString *currentPath = [preferences objectForKey:[NSString stringWithFormat:MGMESound, [eventPopUp indexOfSelectedItem]]];
			for (int i=0; i<[sounds count]; i++) {
				if ([[sounds objectAtIndex:i] isEqual:currentPath])
					selectedPath = i;
				NSMenuItem *menuItem = [[NSMenuItem new] autorelease];
				[menuItem setTitle:[[[sounds objectAtIndex:i] lastPathComponent] stringByDeletingPathExtension]];
				[menuItem setRepresentedObject:[sounds objectAtIndex:i]];
				[soundsMenu addItem:menuItem];
			}
			[soundPopUp setMenu:soundsMenu];
			if (selectedPath!=-1)
				[soundPopUp selectItemAtIndex:selectedPath+2];
			[moveToField setEnabled:NO];
			[moveToChooseButton setEnabled:NO];
			[deleteMatrix setEnabled:NO];
			[growlButton setState:([preferences boolForKey:[NSString stringWithFormat:MGMEGrowl, [eventPopUp indexOfSelectedItem]]] ? NSOnState : NSOffState)];
		}
	}
	return self;
}
- (void)dealloc {
	[view release];
	[sound stop];
	[sound release];
	sound = nil;
	[super dealloc];
}
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem {
	[theItem setLabel:[self title]];
    [theItem setPaletteLabel:[theItem label]];
    [theItem setImage:[NSImage imageNamed:@"Events"]];
}
+ (NSString *)title {
	return [@"Events" localized];
}
- (NSView *)preferencesView {
	return view;
}

- (NSArray *)sounds {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSMutableArray *sounds = [NSMutableArray array];
	NSString *systemSoundsPath = @"/System/Library/Sounds/";
	NSString *userSoundsPath = [@"~/Library/Sounds/" stringByExpandingTildeInPath];
	NSArray *allowedExtensions = [NSArray arrayWithObjects:@"aiff", @"aif", @"mp3", @"wav", @"au", @"m4a", @"caf", nil];
	NSArray *checkPaths = [NSArray arrayWithObjects:systemSoundsPath, userSoundsPath, nil];
	for (int i=0; i<[checkPaths count]; i++) {
		NSDirectoryEnumerator *soundFolders = [manager enumeratorAtPath:[checkPaths objectAtIndex:i]];
		NSString *soundName = nil;
		while ((soundName = [soundFolders nextObject])) {
			NSString *path = [[[checkPaths objectAtIndex:i] stringByAppendingPathComponent:soundName] stringByResolvingSymlinksInPath];
			if ([allowedExtensions containsObject:[[soundName pathExtension] lowercaseString]])
				[sounds addObject:path];
		}
	}
	return sounds;
}

- (IBAction)eventChange:(id)sender {
	NSArray *sounds = [soundPopUp itemArray];
	int selectedPath = -1;
	NSString *currentPath = [preferences objectForKey:[NSString stringWithFormat:MGMESound, [eventPopUp indexOfSelectedItem]]];
	for (int i=0; i<[sounds count]; i++) {
		if ([[[sounds objectAtIndex:i] representedObject] isEqual:currentPath]) {
			selectedPath = i;
			break;
		}
	}
	if (selectedPath==-1)
		[soundPopUp selectItemAtIndex:0];
	else
		[soundPopUp selectItemAtIndex:selectedPath+2];
	if ([eventPopUp indexOfSelectedItem]==MGMEUploadingAutomatic || [eventPopUp indexOfSelectedItem]==MGMEUploading) {
		[moveToField setEnabled:NO];
		[moveToField setStringValue:@""];
		[moveToChooseButton setEnabled:NO];
		[deleteMatrix selectCellAtRow:0 column:0];
		[deleteMatrix setEnabled:NO];
	} else {
		[moveToField setEnabled:YES];
		NSString *path = [preferences objectForKey:[NSString stringWithFormat:MGMEPath, [eventPopUp indexOfSelectedItem]]];
		if (path!=nil)
			[moveToField setStringValue:path];
		[moveToChooseButton setEnabled:YES];
		[deleteMatrix selectCellAtRow:0 column:[preferences integerForKey:[NSString stringWithFormat:MGMEDelete, [eventPopUp indexOfSelectedItem]]]];
		[deleteMatrix setEnabled:YES];
	}
	[growlButton setState:([preferences boolForKey:[NSString stringWithFormat:MGMEGrowl, [eventPopUp indexOfSelectedItem]]] ? NSOnState : NSOffState)];
}
- (IBAction)soundChange:(id)sender {
	if ([[soundPopUp selectedItem] representedObject]!=nil) {
		if (sound!=nil) {
			[sound stop];
			[sound release];
		}
		sound = [[NSSound alloc] initWithContentsOfFile:[[soundPopUp selectedItem] representedObject] byReference:YES];
		[sound setDelegate:self];
		[sound play];
		[preferences setObject:[[soundPopUp selectedItem] representedObject] forKey:[NSString stringWithFormat:MGMESound, [eventPopUp indexOfSelectedItem]]];
	}
}
- (void)sound:(NSSound *)theSound didFinishPlaying:(BOOL)finishedPlaying {
	if (finishedPlaying) {
		[sound release];
		sound = nil;
	}
}

- (IBAction)moveChange:(id)sender {
	[preferences setObject:[moveToField stringValue] forKey:[preferences objectForKey:[NSString stringWithFormat:MGMEPath, [eventPopUp indexOfSelectedItem]]]];
}
- (IBAction)moveChoose:(id)sender {
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
		[moveToField setStringValue:path];
		[preferences setObject:path forKey:[preferences objectForKey:[NSString stringWithFormat:MGMEPath, [eventPopUp indexOfSelectedItem]]]];
	}
}

- (IBAction)deleteChange:(id)sender {
	[preferences setInteger:[deleteMatrix selectedColumn] forKey:[NSString stringWithFormat:MGMEDelete, [eventPopUp indexOfSelectedItem]]];
}
- (IBAction)growlChange:(id)sender {
	[preferences setBool:([growlButton state]==NSOnState) forKey:[NSString stringWithFormat:MGMEGrowl, [eventPopUp indexOfSelectedItem]]];
}
@end