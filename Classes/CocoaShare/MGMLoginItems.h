//
//  MGMLoginItems.h
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

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

@class MGMLoginItems, MGMPathSubscriber;

enum MGMLoginItemType {
	MGMLoginItemShared = 0,
	MGMLoginItemInfo = 1
} typedef MGMLoginItemType;

@interface MGMLoginItem : NSObject {
	MGMLoginItems *loginItems;
	LSSharedFileListItemRef itemRef;
	NSDictionary *itemInfo;
	MGMLoginItemType type;
	
	NSURL *URL;
	BOOL hideOnLaunch;
}
+ (id)itemWithItemRef:(LSSharedFileListItemRef)theItemRef loginItems:(MGMLoginItems *)theLoginItems;
- (id)initWithItemRef:(LSSharedFileListItemRef)theItemRef loginItems:(MGMLoginItems *)theLoginItems;
+ (id)itemWithItemInfo:(NSDictionary *)theItemInfo loginItems:(MGMLoginItems *)theLoginItems;
- (id)initWithItemInfo:(NSDictionary *)theItemInfo loginItems:(MGMLoginItems *)theLoginItems;
- (LSSharedFileListItemRef)itemRef;
- (BOOL)setItemRef:(LSSharedFileListItemRef)theItemRef;
- (NSDictionary *)itemInfo;
- (BOOL)setItemInfo:(NSDictionary *)theItemInfo;
- (MGMLoginItemType)type;
- (void)setURL:(NSURL *)theURL;
- (NSURL *)URL;
- (void)setPath:(NSString *)thePath;
- (NSString *)path;
- (void)setHidesOnLaunch:(BOOL)doesHide;
- (BOOL)hideOnLaunch;
@end

@interface MGMLoginItems : NSObject {
	BOOL sharedSupported;
	BOOL updated;
	LSSharedFileListRef itemsRef;
	CFRunLoopRef runLoop;
	NSMutableArray *loginItems;
	MGMPathSubscriber *subcriber;
}
+ (id)sharedItems;
+ (id)items;
- (NSArray *)loginItems;
- (MGMLoginItem *)itemForPath:(NSString *)thePath;
- (BOOL)thisApplicationExists;
- (BOOL)addThisApplication;
- (BOOL)removeThisApplication;
- (BOOL)exists:(NSString *)thePath;
- (BOOL)add:(NSString *)thePath;
- (BOOL)add:(NSString *)thePath hideOnLaunch:(BOOL)doesHide;
- (BOOL)remove:(NSString *)thePath;
- (BOOL)removeItem:(MGMLoginItem *)theItem;
@end