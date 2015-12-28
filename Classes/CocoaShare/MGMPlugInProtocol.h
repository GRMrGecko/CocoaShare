//
//  MGMPlugInProtocol.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/18/11.
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
- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName multiUpload:(int)multiUploadState;
/*
 This is to receive the state for multiple uploads. You can use ether this method or the one without the multi upload state.
 0 - Not a upload queue with multiple uploads.
 1 - First upload in the queue.
 2 - An upload in the queue.
 3 - Last upload in the queue.
 4 - The multi upload page.
 */
- (void)createMultiUploadPage;
/*
 If the plugin is responsible for creating the multi upload page, use this method to be called instead of having CocoaShare itself create a page.
 If you have this method, you must ether:
  1. Tell CocoaShare to upload the page to go through the usual file sending with [self addPathToUploads:filePath isAutomatic:YES multiUpload:4];
  2. Call multiUploadPageCreated: with the URL of the multi upload page.
 */
@end