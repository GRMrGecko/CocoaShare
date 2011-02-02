//
//  MGMMenuItem.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/16/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@protocol MGMMenuItemDelegate <NSObject>
- (void)menuClicked:(id)sender;
- (void)menuDraggingEntered:(id)sender;
- (void)menuDraggingExited:(id)sender;
- (void)menu:(id)sender droppedFiles:(NSArray *)files;
@end


@interface MGMMenuItem : NSView {
	id<MGMMenuItemDelegate> delegate;
	NSImage *image;
	NSImage *alternateImage;
	
	BOOL isHighlighted;
}
- (void)setDelegate:(id)theDelegate;
- (id<MGMMenuItemDelegate>)delegate;

- (void)setImage:(NSImage *)theImage;
- (NSImage *)image;
- (void)setAlternateImage:(NSImage *)theImage;
- (NSImage *)alternateImage;
@end