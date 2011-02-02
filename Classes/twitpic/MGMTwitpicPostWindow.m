//
//  MGMTwitpicPostWindow.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMTwitpicPostWindow.h"
#import "MGMAddons.h"

@implementation MGMTwitpicPostWindow
- (id)initWithContentRect:(NSRect)theRect styleMask:(unsigned int)theStyleMask backing:(NSBackingStoreType)theBufferingType defer:(BOOL)isDefer {
	if (self = [super initWithContentRect:theRect styleMask:NSBorderlessWindowMask backing:theBufferingType defer:isDefer]) {
		[self setLevel:NSStatusWindowLevel];
        [self setAlphaValue:1.0];
        [self setOpaque:NO];
        [self setMovableByWindowBackground:YES];
        forceDisplay = NO;
        [self setBackgroundColor:[self whiteBackground]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:self];
	}
	return self;
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)windowDidResize:(NSNotification *)aNotification {
	[self setBackgroundColor:[self whiteBackground]];
	if (forceDisplay)
		[self display];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animationFlag {
	forceDisplay = YES;
	[super setFrame:frameRect display:displayFlag animate:animationFlag];
	forceDisplay = NO;
}

- (NSColor *)whiteBackground {
	float alpha = 0.9;
	NSImage *bg = [[NSImage alloc] initWithSize:[self frame].size];
	[bg lockFocus];
	
	float radius = 6.0;
	float stroke = 3.0;
	NSRect bgRect = NSMakeRect(stroke/2, stroke/2, [bg size].width-stroke, [bg size].height-stroke);
	NSBezierPath *bgPath = [NSBezierPath pathWithRect:bgRect radiusX:radius radiusY:radius];
	[bgPath setLineWidth:stroke];
	
	[[NSColor colorWithCalibratedWhite:1.0 alpha:alpha] set];
	[bgPath fill];
	[[NSColor colorWithCalibratedWhite:0.6 alpha:alpha] set];
	[bgPath stroke];
	
	[bg unlockFocus];
	
	return [NSColor colorWithPatternImage:[bg autorelease]];
}

- (BOOL)canBecomeKeyWindow {
	return YES;
}
@end