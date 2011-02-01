//
//  MGMDropboxPlugIn.m
//  CocoaShare
//
//  Created by James on 1/19/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMDropboxPlugIn.h"
#import "MGMController.h"
#import "MGMAddons.h"

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";

NSString * const MGMDropboxEmail = @"MGMDropboxUser";
NSString * const MGMDropboxPath = @"MGMDropboxPath";
#warning Add and remove the keys when publishing source code.
NSString * const MGMDropboxKey = @"";
NSString * const MGMDropboxSecret = @"";

NSString * const MGMDropboxPublic = @"/Public";
NSString * const MGMDropboxFPath = @"path";
NSString * const MGMDropboxFContents = @"contents";

@implementation MGMDropboxPlugIn
- (void)dealloc {
	[self releaseView];
	[publicFolder release];
	[dropboxSession release];
	[dropbox release];
	[dropboxAccountInfo release];
	[filePath release];
	[super dealloc];
}

- (BOOL)isAccountPlugIn {
	return YES;
}
- (NSString *)plugInName {
	return @"Dropbox";
}
- (NSView *)plugInView {
	if (view==nil) {
		if (![NSBundle loadNibNamed:@"DropboxAccountPane" owner:self]) {
			NSLog(@"Unable to load Dropbox Account Pane");
		} else {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSString *user = [defaults objectForKey:MGMDropboxEmail];
			if (user!=nil)
				[emailField setStringValue:user];
			NSString *password = [[MGMController sharedController] password];
			if (password!=nil)
				[passwordField setStringValue:password];
			if (loggedIn) {
				loadingPublic = YES;
				[dropbox loadMetadata:MGMDropboxPublic];
			}
		}
	}
	return view;
}
- (void)releaseView {
	[view release];
	view = nil;
	emailField = nil;
	passwordField = nil;
	loginButton = nil;
	publicOutline = nil;
	[publicFolder release];
	publicFolder = nil;
}
- (void)setCurrentPlugIn:(BOOL)isCurrent {
	if (isCurrent) {
		dropboxSession = [[DBSession alloc] initWithConsumerKey:MGMDropboxKey consumerSecret:MGMDropboxSecret];
		[DBSession setSharedSession:dropboxSession];
		dropbox = [[DBRestClient alloc] initWithSession:dropboxSession];
		[dropbox setDelegate:self];
		userLoggingIn = NO;
		[self login];
	} else {
		[dropboxSession release];
		dropboxSession = nil;
		[dropbox release];
		dropbox = nil;
		[dropboxAccountInfo release];
		dropboxAccountInfo = nil;
		loggedIn = NO;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults removeObjectForKey:MGMDropboxEmail];
		[defaults removeObjectForKey:MGMDropboxPath];
		[dropboxSession updateAccessToken:nil accessTokenSecret:nil];
	}
}

- (void)login {
	NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:MGMDropboxEmail];
	NSString *password = [[MGMController sharedController] password];
	if (user!=nil)
		[dropbox loginWithEmail:user password:password];
}

- (void)lockLogin {
	[emailField setEnabled:NO];
	[passwordField setEnabled:NO];
	[loginButton setEnabled:NO];
	[loginButton setTitle:@"Logging In"];
}
- (void)unlockLogin {
	[emailField setEnabled:YES];
	[passwordField setEnabled:YES];
	[loginButton setEnabled:YES];
	[loginButton setTitle:@"Login"];
}
- (IBAction)login:(id)sender {
	if ([[emailField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Email Required"];
		[alert setInformativeText:@"Please enter your email."];
		[alert runModal];
    } else if ([[passwordField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Password Required"];
		[alert setInformativeText:@"Please enter you password."];
		[alert runModal];
    } else {
		userLoggingIn = YES;
		[[MGMController sharedController] setPassword:[passwordField stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject:[emailField stringValue] forKey:MGMDropboxEmail];
		[self lockLogin];
		[self login];
	}
}

- (void)restClient:(DBRestClient *)client loginFailedWithError:(NSError *)error {
	NSLog(@"Dropbox Error: %@", error);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:@"Account Error"];
	[alert setInformativeText:[error localizedDescription]];
	[alert runModal];
	[self unlockLogin];
}
- (void)restClientDidLogin:(DBRestClient *)client {
	NSLog(@"Dropbox: Logged in.");
	loggedIn = YES;
	[dropbox loadAccountInfo];
	if (userLoggingIn) {
		loadingPublic = YES;
		[dropbox loadMetadata:MGMDropboxPublic];
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Login Successful"];
		[alert setInformativeText:@"You have sucessfully logged into your account."];
		[alert runModal];
		[self unlockLogin];
	}
}

- (NSDictionary *)dataForPath:(NSString *)thePath inArray:(NSArray *)theArray {
	for (unsigned long i=0; i<[theArray count]; i++) {
		NSDictionary *thisData = [theArray objectAtIndex:i];
		if ([[thisData objectForKey:MGMDropboxFPath] isEqual:thePath])
			return thisData;
		NSDictionary *data = [self dataForPath:thePath inArray:[thisData objectForKey:MGMDropboxFContents]];
		if (data!=nil)
			return data;
	}
	return nil;
}
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
	NSMutableArray *currentArray = nil;
	if ([[metadata path] isEqual:MGMDropboxPublic]) {
		loadingPublic = NO;
		[publicFolder release];
		publicFolder = [NSMutableArray new];
		currentArray = publicFolder;
	} else {
		currentArray = [[self dataForPath:[metadata path] inArray:publicFolder] objectForKey:MGMDropboxFContents];
	}
	NSArray *metadataContents = [metadata contents];
	for (unsigned long i=0; i<[metadataContents count]; i++) {
		if ([[metadataContents objectAtIndex:i] isDirectory]) {
			DBMetadata *thisMetadata = [metadataContents objectAtIndex:i];
			[dropbox loadMetadata:[thisMetadata path]];
			[currentArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[thisMetadata path], MGMDropboxFPath, [NSMutableArray array], MGMDropboxFContents, nil]];
		}
	}
	[publicOutline reloadData];
}
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(NSDictionary *)item {
	return (item==nil ? [publicFolder count] : [[item objectForKey:MGMDropboxFContents] count]);
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(NSDictionary *)item {
	if ([[tableColumn identifier] isEqual:@"name"]) {
		return [[item objectForKey:MGMDropboxFPath] lastPathComponent];
	} else if ([[tableColumn identifier] isEqual:@"selected"]) {
		return [NSNumber numberWithBool:([[item objectForKey:MGMDropboxFPath] isEqual:[[NSUserDefaults standardUserDefaults] objectForKey:MGMDropboxPath]])];
	}
	return @"";
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(NSDictionary *)item {
	return (item==nil ? ([publicFolder count]>0) : ([[item objectForKey:MGMDropboxFContents] count]>0));
}
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(NSDictionary *)item {
	return (item==nil ? [publicFolder objectAtIndex:index] : [[item objectForKey:MGMDropboxFContents] objectAtIndex:index]);
}
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(NSDictionary *)item {
	if ([object boolValue])
		[[NSUserDefaults standardUserDefaults] setObject:[item objectForKey:MGMDropboxFPath] forKey:MGMDropboxPath];
	else
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:MGMDropboxPath];
	[publicOutline reloadData];
}

- (void)restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info {
	[dropboxAccountInfo release];
	dropboxAccountInfo = [info retain];
}
- (void)restClient:(DBRestClient *)client loadAccountInfoFailedWithError:(NSError *)error {
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:@"Account Error"];
	[alert setInformativeText:@"Unable to get your account ID."];
	[alert runModal];
}

- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMDropboxEmail]==nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:5 userInfo:[NSDictionary dictionaryWithObject:@"Account is not logged in." forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:thePath receivedError:error];
		return;
	}
	
	NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:MGMDropboxPath];
	if (path==nil) path = MGMDropboxPublic;
	filePath = [thePath retain];
	[dropbox uploadFile:theName toPath:path fromPath:thePath];
}
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath {
	NSString *finishPath = [[filePath retain] autorelease];
	[filePath release];
	filePath = nil;
	NSString *url = [NSString stringWithFormat:@"http://dl.dropbox.com/u/%@%@", [dropboxAccountInfo userId], [destPath replace:MGMDropboxPublic with:@""]];
	[[MGMController sharedController] uploadFinished:finishPath url:[NSURL URLWithString:url]];
}
- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
	NSString *finishPath = [[filePath retain] autorelease];
	[filePath release];
	filePath = nil;
	[[MGMController sharedController] upload:finishPath receivedError:error];
}
@end