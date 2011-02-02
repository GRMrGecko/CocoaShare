//
//  MGMTwitpicPlugIn.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@interface MGMTwitpicPlugIn : NSObject {
	IBOutlet NSView *view;
	IBOutlet NSTextField *userField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSButton *postButton;
	
	NSString *filePath;
	NSString *fileName;
	IBOutlet NSWindow *postWindow;
	IBOutlet NSTextView *postView;
}
- (void)releaseView;

- (IBAction)save:(id)sender;

- (IBAction)post:(id)sender;
- (IBAction)upload:(id)sender;
- (void)sendFile:(NSString *)theFile withName:(NSString *)theName post:(BOOL)shouldPost message:(NSString *)theMessage;
@end