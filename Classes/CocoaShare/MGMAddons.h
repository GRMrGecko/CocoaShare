//
//  MGMAddons.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/22/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@interface NSString (MGMAddons)
- (NSString *)replace:(NSString *)targetString with:(NSString *)replaceString;
- (NSString *)escapePath;
- (NSString *)addPercentEscapes;
@end

extern NSString * const MGMMPFPath;
extern NSString * const MGMMPFName;

@interface NSDictionary (MGMAddons)
- (NSData *)buildMultiPartBodyWithBoundary:(NSString *)theBoundary;
@end

@interface NSBezierPath (MGMAddons)
+ (NSBezierPath *)pathWithRect:(NSRect)theRect radiusX:(float)theRadiusX radiusY:(float)theRadiusY;
- (void)fillGradientFrom:(NSColor *)theStartColor to:(NSColor *)theEndColor;
@end