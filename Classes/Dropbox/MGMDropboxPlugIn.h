//
//  MGMDropboxPlugIn.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/19/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>
#import "DBRestClient.h"
#import "DBAccountInfo.h"
#import "DBMetadata.h"

@interface MGMDropboxPlugIn : NSObject <DBRestClientDelegate> {
	IBOutlet NSView *view;
	IBOutlet NSTextField *emailField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSButton *loginButton;
	
	IBOutlet NSOutlineView *publicOutline;
	BOOL loadingPublic;
	NSMutableArray *publicFolder;
	
	BOOL userLoggingIn;
	BOOL loggedIn;
	DBSession *dropboxSession;
	DBRestClient *dropbox;
	DBAccountInfo *dropboxAccountInfo;
	
	NSString *filePath;
}
- (void)releaseView;

- (void)login;
- (void)lockLogin;
- (void)unlockLogin;
- (IBAction)login:(id)sender;
- (NSDictionary *)dataForPath:(NSString *)thePath inArray:(NSArray *)theArray;
@end