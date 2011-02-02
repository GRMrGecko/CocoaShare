//
//  MGMMenuItem.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/16/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMMenuItem.h"


@implementation MGMMenuItem
- (id)initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:NSMakeRect(0, 0, 22, 22)])) {
		[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	}
	return self;
}
- (void)dealloc {
	[image release];
	[alternateImage release];
	[super dealloc];
}

- (void)setDelegate:(id)theDelegate {
	delegate = theDelegate;
}
- (id<MGMMenuItemDelegate>)delegate {
	return delegate;
}

- (void)setImage:(NSImage *)theImage {
	[image release];
	image = [theImage copy];
	[self display];
}
- (NSImage *)image {
	return image;
}
- (void)setAlternateImage:(NSImage *)theImage {
	[alternateImage release];
	alternateImage = [theImage copy];
}
- (NSImage *)alternateImage {
	return alternateImage;
}

- (void)drawRect:(NSRect)theRect {
	NSImage *displayImage = image;
	if (isHighlighted) {
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:theRect];
		[[NSColor selectedMenuItemColor] set];
		[path fill];
		displayImage = alternateImage;
	}
	[displayImage drawInRect:NSMakeRect((22-[image size].width)/2, (22-[image size].height)/2, [image size].width, [image size].height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)mouseDown:(NSEvent *)theEvent {
	isHighlighted = YES;
	[self display];
	if ([delegate respondsToSelector:@selector(menuClicked:)]) [delegate menuClicked:self];
	isHighlighted = NO;
	[self display];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType]) {
		if ([delegate respondsToSelector:@selector(menuDraggingEntered:)]) [delegate menuDraggingEntered:self];
		return NSDragOperationEvery;
	}
	return NSDragOperationNone;
}
- (void)draggingExited:(id <NSDraggingInfo>)sender {
	if ([delegate respondsToSelector:@selector(menuDraggingExited:)]) [delegate menuDraggingExited:self];
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	NSPasteboard *pboard = [sender draggingPasteboard];
	if ([delegate respondsToSelector:@selector(menuDraggingExited:)]) [delegate menuDraggingExited:self];
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		if ([delegate respondsToSelector:@selector(menu:droppedFiles:)]) [delegate menu:self droppedFiles:files];
		return YES;
	}
	return NO;
}
@end