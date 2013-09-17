//
//  MGMTinyGrabPlugIn.h
//  CocoaShare
//
//  Created by James on 1/31/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@interface MGMTinyGrabPlugIn : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSTextField *emailField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSTextField *typeField;
	IBOutlet NSButton *loginButton;
}
- (void)releaseView;

- (void)lockLogin;
- (void)unlockLogin;
- (void)login:(id)sender;
- (IBAction)registerAccount:(id)sender;
@end