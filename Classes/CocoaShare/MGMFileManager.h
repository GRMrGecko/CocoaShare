//
//  MGMFileManager.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/22/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@interface NSFileManager (MGMFileManager)
- (BOOL)moveItemAtPath:(NSString *)thePath toPath:(NSString *)theDestination;
- (BOOL)copyItemAtPath:(NSString *)thePath toPath:(NSString *)theDestination;
- (BOOL)removeItemAtPath:(NSString *)thePath;
- (BOOL)linkItemAtPath:(NSString *)thePath toPath:(NSString *)theDestination;
- (BOOL)createSymbolicLinkAtPath:(NSString *)thePath withDestinationPath:(NSString *)theDestination;
- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)thePath;
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)thePath;
- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)thePath;
- (void)setAttributes:(NSDictionary *)theAttributes ofItemAtPath:(NSString *)thePath;
- (NSDictionary *)attributesOfItemAtPath:(NSString *)thePath;
@end