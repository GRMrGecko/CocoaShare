//
//  MGMPlugInProtocol.h
//  CocoaShare
//
//  Created by James on 1/18/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@protocol MGMPlugInProtocol <NSObject>
- (BOOL)isAccountPlugIn;
- (NSString *)plugInName;
- (NSView *)plugInView;
- (void)releaseView;
- (NSArray *)allowedExtensions;
- (void)setCurrentPlugIn:(BOOL)isCurrent;
- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName;
@end