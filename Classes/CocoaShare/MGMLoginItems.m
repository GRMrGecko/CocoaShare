//
//  MGMLoginItems.m
//  Conmote
//
//  Created by Mr. Gecko on 8/14/13.
//  Copyright (c) 2013 Mr. Gecko's Media (James Coleman). http://mrgeckosmedia.com/
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose
//  with or without fee is hereby granted, provided that the above copyright notice
//  and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//  REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT,
//  OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
//  DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
//  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

#import "MGMLoginItems.h"
#import "MGMPathSubscriber.h"

NSString * const MGMLoginItemsPath = @"~/Library/Preferences/loginwindow.plist";
NSString * const MGMLoginItemsKey = @"AutoLaunchedApplicationDictionary";
NSString * const MGMLoginItemPathKey = @"Path";
NSString * const MGMLoginItemHideKey = @"Hide";
NSString * const MGMLoginItemHideProperty = @"com.apple.loginitem.HideOnLaunch";
NSString * const MGMLoginItemsUpdated = @"MGMLoginItemsUpdated";

@interface MGMLoginItems (MGMPrivate)
- (void)updateItem:(MGMLoginItem *)theItem;
- (void)updateItems;
- (void)saveLoginWindowItems;
@end


void MGMLoginItemsFileListChanged(LSSharedFileListRef inList, void *context) {
	[(MGMLoginItems *)context updateItems];
}

@implementation MGMLoginItem
+ (id)itemWithItemRef:(LSSharedFileListItemRef)theItemRef loginItems:(MGMLoginItems *)theLoginItems {
	return [[[self alloc] initWithItemRef:theItemRef loginItems:theLoginItems] autorelease];
}
- (id)initWithItemRef:(LSSharedFileListItemRef)theItemRef loginItems:(MGMLoginItems *)theLoginItems {
	if ((self = [super init])) {
		loginItems = theLoginItems;
		if (theItemRef==NULL) {
			NSLog(@"MGMLoginItem: Invalid item reference.");
			[self release];
			return nil;
		}
		itemRef = (LSSharedFileListItemRef)CFRetain(theItemRef);
		NSURL *itemURL = nil;
		LSSharedFileListItemResolve(itemRef, 0, (CFURLRef *)&itemURL, NULL);
		if (itemURL==nil) {
			NSLog(@"MGMLoginItem: Unable to resolve item location.");
			[self release];
			return nil;
		}
		URL = itemURL;
		NSNumber *property = (NSNumber *)LSSharedFileListItemCopyProperty(itemRef, (CFStringRef)MGMLoginItemHideProperty);
		hideOnLaunch = [property boolValue];
		[property release];
		type = MGMLoginItemShared;
	}
	return self;
}

+ (id)itemWithItemInfo:(NSDictionary *)theItemInfo loginItems:(MGMLoginItems *)theLoginItems {
	return [[[self alloc] initWithItemInfo:theItemInfo loginItems:theLoginItems] autorelease];
}
- (id)initWithItemInfo:(NSDictionary *)theItemInfo loginItems:(MGMLoginItems *)theLoginItems {
	if ((self = [super init])) {
		loginItems = theLoginItems;
		if (theItemInfo==nil || [theItemInfo objectForKey:MGMLoginItemPathKey]==nil) {
			NSLog(@"MGMLoginItem: Invalid item info.");
			[self release];
			return nil;
		}
		itemInfo = [theItemInfo retain];
		NSURL *itemURL = [NSURL fileURLWithPath:[itemInfo objectForKey:MGMLoginItemPathKey]];
		if (itemURL==nil) {
			NSLog(@"MGMLoginItem: Unable to resolve item path.");
			[self release];
			return nil;
		}
		URL = [itemURL retain];
		hideOnLaunch = [[itemInfo objectForKey:MGMLoginItemHideKey] boolValue];
		type = MGMLoginItemInfo;
	}
	return self;
}

- (void)dealloc {
	[URL release];
	if (itemRef!=NULL)
		CFRelease(itemRef);
	[itemInfo release];
	[super dealloc];
}
- (LSSharedFileListItemRef)itemRef {
	return itemRef;
}
- (BOOL)setItemRef:(LSSharedFileListItemRef)theItemRef {
	if (theItemRef==NULL) {
		NSLog(@"MGMLoginItem: Invalid item reference.");
		return NO;
	}
	NSURL *itemURL = nil;
	LSSharedFileListItemResolve(theItemRef, 0, (CFURLRef *)&itemURL, NULL);
	if (itemURL==nil) {
		CFRelease(theItemRef);
		NSLog(@"MGMLoginItem: Unable to resolve item path.");
		return NO;
	}
	CFRelease(itemRef);
	itemRef = (LSSharedFileListItemRef)CFRetain(theItemRef);
	[URL release];
	URL = itemURL;
	NSNumber *property = (NSNumber *)LSSharedFileListItemCopyProperty(itemRef, (CFStringRef)MGMLoginItemHideProperty);
	hideOnLaunch = [property boolValue];
	[property release];
	type = MGMLoginItemShared;
	[itemInfo release];
	itemInfo = nil;
	return YES;
}
- (NSDictionary *)itemInfo {
	return itemInfo;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@:%p %@>", NSStringFromClass([self class]), self, [self path]];
}

- (BOOL)setItemInfo:(NSDictionary *)theItemInfo {
	if (theItemInfo==nil && [theItemInfo objectForKey:MGMLoginItemPathKey]) {
		NSLog(@"MGMLoginItem: Invalid item info.");
		return NO;
	}
	NSURL *itemURL = [NSURL fileURLWithPath:[theItemInfo objectForKey:MGMLoginItemPathKey]];
	if (itemURL==nil) {
		NSLog(@"MGMLoginItem: Unable to find item path.");
		return NO;
	}
	itemInfo = [theItemInfo retain];
	URL = [itemURL retain];
	hideOnLaunch = [[itemInfo objectForKey:MGMLoginItemHideKey] boolValue];
	type = MGMLoginItemInfo;
	CFRelease(itemRef);
	itemRef = NULL;
	return YES;
}
- (MGMLoginItemType)type {
	return  type;
}
- (void)setURL:(NSURL *)theURL {
	[URL release];
	URL = [theURL retain];
	[loginItems updateItem:self];
}
- (NSURL *)URL {
	return URL;
}
- (void)setPath:(NSString *)thePath {
	[self setURL:[NSURL fileURLWithPath:thePath]];
}
- (NSString *)path {
	return [URL path];
}
- (void)setHidesOnLaunch:(BOOL)doesHide {
	hideOnLaunch = doesHide;
	[loginItems updateItem:self];
}
- (BOOL)hideOnLaunch {
	return hideOnLaunch;
}
@end

static MGMLoginItems *MGMSharedLoginItems;

@implementation MGMLoginItems
+ (id)sharedItems {
	if (MGMSharedLoginItems==nil)
		MGMSharedLoginItems = [MGMLoginItems new];
	return MGMSharedLoginItems;
}
+ (id)items {
	return [[[self alloc] init] autorelease];
}
- (id)init {
	if ((self = [super init])) {
		loginItems = [NSMutableArray new];
		
		sharedSupported = (NSFoundationVersionNumber>=677.00/*NSFoundationVersionNumber10_5*/);
		
		if (sharedSupported) {
			itemsRef = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, NULL);
			UInt32 outSnapshotSeed = 0;
			NSArray *items = [(NSArray *)LSSharedFileListCopySnapshot(itemsRef, &outSnapshotSeed) autorelease];
			for (int i=0; i<[items count]; i++) {
				LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[items objectAtIndex:i];
				MGMLoginItem *item = [MGMLoginItem itemWithItemRef:itemRef loginItems:self];
				if (item!=nil)
					[loginItems addObject:item];
			}
			runLoop = CFRunLoopGetCurrent();
			LSSharedFileListAddObserver(itemsRef, runLoop, kCFRunLoopDefaultMode, &MGMLoginItemsFileListChanged, (void *)self);
		}
		
		subcriber = [MGMPathSubscriber new];
		[subcriber setDelegate:self];
		[subcriber addPath:[MGMLoginItemsPath stringByExpandingTildeInPath] fileOptions:MGMFOWrite | MGMFODelete];
		
		NSDictionary *loginWindowItems = [NSDictionary dictionaryWithContentsOfFile:[MGMLoginItemsPath stringByExpandingTildeInPath]];
		NSArray *items = [loginWindowItems objectForKey:MGMLoginItemsKey];
		for (unsigned int i=0; i<[items count]; i++) {
			NSDictionary *itemInfo = [items objectAtIndex:i];
			if (![self exists:[itemInfo objectForKey:MGMLoginItemPathKey]]) {
				MGMLoginItem *item = [MGMLoginItem itemWithItemInfo:itemInfo loginItems:self];
				if (item!=nil)
					[loginItems addObject:item];
			}
		}
	}
	return self;
}
- (void)dealloc {
	if (sharedSupported) {
		LSSharedFileListRemoveObserver(itemsRef, runLoop, kCFRunLoopDefaultMode, &MGMLoginItemsFileListChanged, (void *)self);
		CFRelease(itemsRef);
	}
	[loginItems release];
	[super dealloc];
}

- (void)updateItem:(MGMLoginItem *)theItem {
	if ([theItem type]==MGMLoginItemShared && sharedSupported) {
		NSMutableDictionary *itemsToSet = [NSMutableDictionary dictionary];
		NSMutableArray *itemsToClear = [NSMutableArray array];
		if ([theItem hideOnLaunch])
			[itemsToSet setObject:[NSNumber numberWithBool:YES] forKey:MGMLoginItemHideProperty];
		else
			[itemsToClear addObject:MGMLoginItemHideProperty];
		LSSharedFileListItemRef afterItemRef = kLSSharedFileListItemBeforeFirst;
		MGMLoginItem *lastItem = nil;
		for (unsigned int i=0; i<[loginItems count]; i++) {
			MGMLoginItem *item = [loginItems objectAtIndex:i];
			if ([item type]==MGMLoginItemShared) {
				if (lastItem==nil && [theItem isEqual:item]) {
					break;
				}
				if ([theItem isEqual:item]) {
					afterItemRef = [lastItem itemRef];
					break;
				}
				lastItem = item;
			}
		}
		
		LSSharedFileListItemRef newItem = LSSharedFileListInsertItemURL(itemsRef, afterItemRef, NULL, NULL, (CFURLRef)[theItem URL], (CFDictionaryRef)itemsToSet, (CFArrayRef)itemsToClear);
		LSSharedFileListItemRef oldItem = (LSSharedFileListItemRef)CFRetain([theItem itemRef]);
		if ([theItem setItemRef:newItem] && LSSharedFileListItemGetID(newItem)!=LSSharedFileListItemGetID(oldItem)) {
			LSSharedFileListItemRemove(itemsRef, oldItem);
		}
		CFRelease(newItem);
		CFRelease(oldItem);
		updated = YES;
	} else {
		[self saveLoginWindowItems];
	}
}

- (NSArray *)loginItems {
	return loginItems;
}
- (MGMLoginItem *)itemForPath:(NSString *)thePath {
	for (unsigned int i=0; i<[loginItems count]; i++) {
		MGMLoginItem *item = [loginItems objectAtIndex:i];
		if ([[item path] isEqual:thePath])
			return item;
	}
	return nil;
}

- (BOOL)thisApplicationExists {
	return [self exists:[[NSBundle mainBundle] bundlePath]];
}
- (BOOL)addThisApplication {
	return [self add:[[NSBundle mainBundle] bundlePath]];
}
- (BOOL)removeThisApplication {
	return [self remove:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL)exists:(NSString *)thePath {
	return ([self itemForPath:thePath]!=nil);
}
- (BOOL)add:(NSString *)thePath {
	return [self add:thePath hideOnLaunch:NO];
}
- (BOOL)add:(NSString *)thePath hideOnLaunch:(BOOL)doesHide {
	if ([self exists:thePath])
		return NO;
	if (sharedSupported) {
		NSMutableDictionary *itemsToSet = [NSMutableDictionary dictionary];
		NSMutableArray *itemsToClear = [NSMutableArray array];
		if (doesHide)
			[itemsToSet setObject:[NSNumber numberWithBool:YES] forKey:MGMLoginItemHideProperty];
		else
			[itemsToClear addObject:MGMLoginItemHideProperty];
		LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(itemsRef, kLSSharedFileListItemLast, NULL, NULL, (CFURLRef)[NSURL fileURLWithPath:thePath], (CFDictionaryRef)itemsToSet, (CFArrayRef)itemsToClear);
		MGMLoginItem *item = [MGMLoginItem itemWithItemRef:itemRef loginItems:self];
		CFRelease(itemRef);
		if (item==nil)
			return NO;
		[loginItems addObject:item];
		updated = YES;
	} else {
		NSDictionary *itemInfo = [NSDictionary dictionaryWithObjectsAndKeys:thePath, MGMLoginItemPathKey, [NSNumber numberWithBool:doesHide], MGMLoginItemHideKey, nil];
		MGMLoginItem *item = [MGMLoginItem itemWithItemInfo:itemInfo loginItems:self];
		if (item==nil)
			return NO;
		[loginItems addObject:item];
		[self saveLoginWindowItems];
	}
	return YES;
}
- (BOOL)remove:(NSString *)thePath {
	return [self removeItem:[self itemForPath:thePath]];
}
- (BOOL)removeItem:(MGMLoginItem *)theItem {
	if (theItem==nil)
		return NO;
	if ([theItem type]==MGMLoginItemShared) {
		OSStatus result = LSSharedFileListItemRemove(itemsRef, [theItem itemRef]);
		if (result!=noErr) {
			NSLog(@"Error removing %@ %d", theItem, result);
			return NO;
		}
		[loginItems removeObject:theItem];
		updated = YES;
	} else {
		[loginItems removeObject:theItem];
		[self saveLoginWindowItems];
	}
	return YES;
}

- (void)updateItems {
	if (updated) {
		updated = NO;
		return;
	}
	[loginItems release];
	loginItems = [NSMutableArray new];
	if (sharedSupported) {
		UInt32 outSnapshotSeed = 0;
		NSArray *items = [(NSArray *)LSSharedFileListCopySnapshot(itemsRef, &outSnapshotSeed) autorelease];
		for (int i=0; i<[items count]; i++) {
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[items objectAtIndex:i];
			MGMLoginItem *item = [MGMLoginItem itemWithItemRef:itemRef loginItems:self];
			if (item!=nil)
				[loginItems addObject:item];
		}
	}
	NSDictionary *loginWindowItems = [NSDictionary dictionaryWithContentsOfFile:[MGMLoginItemsPath stringByExpandingTildeInPath]];
	NSArray *items = [loginWindowItems objectForKey:MGMLoginItemsKey];
	for (unsigned int i=0; i<[items count]; i++) {
		NSDictionary *itemInfo = [items objectAtIndex:i];
		if (![self exists:[itemInfo objectForKey:MGMLoginItemPathKey]]) {
			MGMLoginItem *item = [MGMLoginItem itemWithItemInfo:itemInfo loginItems:self];
			if (item!=nil)
				[loginItems addObject:item];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMLoginItemsUpdated object:self];
}

- (void)saveLoginWindowItems {
	NSMutableDictionary *loginWindowItems = [NSMutableDictionary dictionaryWithContentsOfFile:[MGMLoginItemsPath stringByExpandingTildeInPath]];
	NSMutableArray *items = [NSMutableArray array];
	for (unsigned int i=0; i<[loginItems count]; i++) {
		MGMLoginItem *item = [loginItems objectAtIndex:i];
		if ([item type]==MGMLoginItemInfo) {
			NSDictionary *itemInfo = [NSDictionary dictionaryWithObjectsAndKeys:[item path], MGMLoginItemPathKey, [NSNumber numberWithBool:[item hideOnLaunch]], MGMLoginItemHideKey, nil];
			[items addObject:itemInfo];
		}
	}
	[loginWindowItems setObject:items forKey:MGMLoginItemsKey];
	[loginWindowItems writeToFile:[MGMLoginItemsPath stringByExpandingTildeInPath] atomically:YES];
}

- (void)subscribedPathChanged:(NSString *)thePath {
	[self updateItems];
}
@end