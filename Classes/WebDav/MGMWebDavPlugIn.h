//
//  MGMWebDavPlugIn.h
//  CocoaShare
//
//  Created by James on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@class MGMWebDav;

@interface MGMWebDavPlugIn : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSTextField *urlField;
	IBOutlet NSTextField *userField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSButton *loginButton;
	
	MGMWebDav *webDav;
	BOOL userLoggingIn;
	NSString *filePath;
}
- (void)releaseView;

- (void)lockLogin;
- (void)unlockLogin;
- (void)login;
- (IBAction)login:(id)sender;
@end