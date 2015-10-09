//
//  MGMHTTPPlugIn.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/18/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@interface MGMHTTPPlugIn : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSTextField *urlField;
	IBOutlet NSTextField *userField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSButton *loginButton;
	BOOL userLoggingIn;
	int loginTries;
    
    BOOL isJSON;
}
- (void)releaseView;

- (void)login;
- (void)lockLogin;
- (void)unlockLogin;
- (IBAction)login:(id)sender;
@end