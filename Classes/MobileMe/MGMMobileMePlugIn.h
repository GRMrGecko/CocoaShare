//
//  MGMMobileMePlugIn.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@class MGMWebDav;

@interface MGMMobileMePlugIn : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSTextField *userField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSButton *loginButton;
	
	IBOutlet NSOutlineView *publicOutline;
	BOOL loadingPublic;
	NSMutableArray *publicFolder;
	
	BOOL userLoggingIn;
	BOOL loggedIn;
	MGMWebDav *webDav;
	
	NSString *filePath;
}
- (void)releaseView;

- (void)lockLogin;
- (void)unlockLogin;
- (void)login;
- (IBAction)login:(id)sender;
@end