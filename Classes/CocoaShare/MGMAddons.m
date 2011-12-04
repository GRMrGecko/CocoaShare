//
//  MGMAddons.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/22/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMAddons.h"
#import <QuartzCore/QuartzCore.h>

@implementation NSString (MGMAddons)
- (NSString *)replace:(NSString *)targetString with:(NSString *)replaceString {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSMutableString *temp = [NSMutableString new];
	NSRange replaceRange = NSMakeRange(0, [self length]);
	NSRange rangeInOriginalString = replaceRange;
	int replaced = 0;
	
	while (1) {
		NSRange rangeToCopy;
		NSRange foundRange = [self rangeOfString:targetString options:0 range:rangeInOriginalString];
		if (foundRange.length == 0) break;
		rangeToCopy = NSMakeRange(rangeInOriginalString.location, foundRange.location - rangeInOriginalString.location);	
		[temp appendString:[self substringWithRange:rangeToCopy]];
		[temp appendString:replaceString];
		rangeInOriginalString.length -= NSMaxRange(foundRange) -
		rangeInOriginalString.location;
		rangeInOriginalString.location = NSMaxRange(foundRange);
		replaced++;
		if (replaced % 100 == 0) {
			[pool drain];
			pool = [NSAutoreleasePool new];
		}
	}
	if (rangeInOriginalString.length > 0) [temp appendString:[self substringWithRange:rangeInOriginalString]];
	[pool drain];
	
	return [temp autorelease];
}
- (NSString *)escapePath {
	NSString *escapedPath = [self replace:@" " with:@"\\ "];
	escapedPath = [escapedPath replace:@"\"" with:@"\\\""];
	escapedPath = [escapedPath replace:@"'" with:@"\\'"];
	return escapedPath;
}
- (NSString *)addPercentEscapes {
	NSString *result = [self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("!*'();:^@&=+$,?%#[]|"), kCFStringEncodingUTF8);
	
	if (escapedString!=NULL)
		result = [(NSString *)escapedString autorelease];
	return result;
}
@end

NSString * const MGMMPFPath = @"path";
NSString * const MGMMPFName = @"name";

@implementation NSDictionary (MGMAddons)
- (NSData *)buildMultiPartBodyWithBoundary:(NSString *)theBoundary {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSMutableData *data = [NSMutableData data];
	NSArray *keys = [self allKeys];
	for (int i=0; i<[keys count]; i++) {
		NSString *key = [keys objectAtIndex:i];
		id object = [self objectForKey:key];
		[data appendData:[[NSString stringWithFormat:@"--%@\r\n", theBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
		if (![object isKindOfClass:[NSDictionary class]])
			  [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];  
		if ([object isKindOfClass:[NSString class]]) {
			[data appendData:[object dataUsingEncoding:NSUTF8StringEncoding]];
		} else if ([object isKindOfClass:[NSNumber class]]) {
			[data appendData:[[object stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
		} else if ([object isKindOfClass:[NSData class]]) {
			[data appendData:object];
		} else if ([object isKindOfClass:[NSURL class]]) {
			[data appendData:[[object absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
		} else if ([object isKindOfClass:[NSDictionary class]]) {
			if ([manager fileExistsAtPath:[object objectForKey:MGMMPFPath]] && [manager isReadableFileAtPath:[object objectForKey:MGMMPFPath]]) {
				[data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, [object objectForKey:MGMMPFName]] dataUsingEncoding:NSUTF8StringEncoding]];
				NSString *mimeString = @"application/octet-stream";
				CFStringRef extentionInfo = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[[object objectForKey:MGMMPFPath] pathExtension], CFSTR("public.data"));
				if (extentionInfo!=NULL) {
					CFStringRef mime = UTTypeCopyPreferredTagWithClass(extentionInfo, kUTTagClassMIMEType);
					CFRelease(extentionInfo);
					if (mime!=NULL) {
						mimeString = [(NSString *)mime autorelease];
					}
				}
				[data appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", mimeString] dataUsingEncoding:NSUTF8StringEncoding]];
				[data appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				[data appendData:[NSData dataWithContentsOfFile:[object objectForKey:MGMMPFPath]]];
			}
		}
		[data appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	[data appendData:[[NSString stringWithFormat:@"--%@--", theBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return data;
}
@end

@implementation NSBezierPath (MGMAddons)
+ (NSBezierPath *)pathWithRect:(NSRect)theRect radiusX:(float)theRadiusX radiusY:(float)theRadiusY {
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    float maxRadiusX = theRect.size.width / 2.0;
    float maxRadiusY = theRect.size.height / 2.0;
    theRadiusX = (theRadiusX<maxRadiusX ? theRadiusX : maxRadiusX);
    theRadiusY = (theRadiusY<maxRadiusY ? theRadiusY : maxRadiusY);
    float ellipse = 0.55228474983079;
    float controlX = theRadiusX * ellipse;
    float controlY = theRadiusY * ellipse;
    NSRect edges = NSInsetRect(theRect, theRadiusX, theRadiusY);
    
    [path moveToPoint:NSMakePoint(edges.origin.x, theRect.origin.y)];
    
	// top right corner
    [path lineToPoint:NSMakePoint(NSMaxX(edges), theRect.origin.y)];
    [path curveToPoint:NSMakePoint(NSMaxX(theRect), edges.origin.y) controlPoint1:NSMakePoint(NSMaxX(edges) + controlX, theRect.origin.y) controlPoint2:NSMakePoint(NSMaxX(theRect), edges.origin.y - controlY)];
    
    // bottom right corner
    [path lineToPoint:NSMakePoint(NSMaxX(theRect), NSMaxY(edges))];
    [path curveToPoint:NSMakePoint(NSMaxX(edges), NSMaxY(theRect)) controlPoint1:NSMakePoint(NSMaxX(theRect), NSMaxY(edges) + controlY) controlPoint2:NSMakePoint(NSMaxX(edges) + controlX, NSMaxY(theRect))];
    
    // bottom left corner
    [path lineToPoint:NSMakePoint(edges.origin.x, NSMaxY(theRect))];
    [path curveToPoint:NSMakePoint(theRect.origin.x, NSMaxY(edges)) controlPoint1:NSMakePoint(edges.origin.x - controlX, NSMaxY(theRect)) controlPoint2:NSMakePoint(theRect.origin.x, NSMaxY(edges) + controlY)];
    
    // top left corner
    [path lineToPoint:NSMakePoint(theRect.origin.x, edges.origin.y)];
    [path curveToPoint:NSMakePoint(edges.origin.x, theRect.origin.y) controlPoint1:NSMakePoint(theRect.origin.x, edges.origin.y - controlY) controlPoint2:NSMakePoint(edges.origin.x - controlX, theRect.origin.y)];
    
    [path closePath];
    return path;
}

- (void)fillGradientFrom:(NSColor *)theStartColor to:(NSColor *)theEndColor {
	CIFilter *filter = [CIFilter filterWithName:@"CILinearGradient"];
	
	theStartColor = [theStartColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	theEndColor = [theEndColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	if (![[NSGraphicsContext currentContext] isFlipped]) {
		NSColor *start = theStartColor;
		NSColor *end = theEndColor;
		theEndColor = start;
		theStartColor = end;
	}
	CIColor *startColor = [CIColor colorWithRed:[theStartColor redComponent] green:[theStartColor greenComponent] blue:[theStartColor blueComponent] alpha:[theStartColor alphaComponent]];
	CIColor *endColor = [CIColor colorWithRed:[theEndColor redComponent] green:[theEndColor greenComponent] blue:[theEndColor blueComponent] alpha:[theEndColor alphaComponent]];
	[filter setValue:startColor forKey:@"inputColor0"];
	[filter setValue:endColor forKey:@"inputColor1"];
	
	CIVector *startVector = [CIVector vectorWithX:0.0 Y:0.0];
	[filter setValue:startVector forKey:@"inputPoint0"];
	CIVector *endVector = [CIVector vectorWithX:0.0 Y:[self bounds].size.height];
	[filter setValue:endVector forKey:@"inputPoint1"];
	
	CIImage *coreimage = [filter valueForKey:@"outputImage"];
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	[self setClip];
	CIContext *context = [[NSGraphicsContext currentContext] CIContext];
	[context drawImage:coreimage atPoint:CGPointMake([self bounds].origin.x, [self bounds].origin.y) fromRect:CGRectMake(0.0, 0.0, [self bounds].size.width, [self bounds].size.height)];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}
@end