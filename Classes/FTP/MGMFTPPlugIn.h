//
//  MGMFTPPlugIn.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/25/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@interface MGMFTPPlugIn : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSTextField *hostField;
	IBOutlet NSTextField *userField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSTextField *pathField;
	IBOutlet NSTextField *urlField;
	IBOutlet NSButton *loginButton;
	
	NSString *filePath;
	NSString *fileName;
	
	NSTask *FTPTask;
	NSPipe *FTPPipe;
	NSPipe *FTPInputPipe;
}
- (void)releaseView;

- (void)lockLogin;
- (void)unlockLogin;
- (IBAction)login:(id)sender;
@end