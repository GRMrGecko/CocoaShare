//
//  MGMWebDavPlugIn.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/28/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMWebDavPlugIn.h"
#import "MGMController.h"
#import "MGMWebDav.h"
#import "MGMAddons.h"

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";

NSString * const MGMWebDavURL = @"MGMWebDavURL";
NSString * const MGMWebDavUser = @"MGMWebDavUser";

@implementation MGMWebDavPlugIn
- (void)dealloc {
	[self releaseView];
	[webDav release];
	[filePath release];
	[super dealloc];
}

- (BOOL)isAccountPlugIn {
	return YES;
}
- (NSString *)plugInName {
	return @"WebDav";
}
- (NSView *)plugInView {
	if (view==nil) {
		if (![NSBundle loadNibNamed:@"WebDavAccountPane" owner:self]) {
			NSLog(@"Unable to load WebDav Account Pane");
		} else {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSString *url = [defaults objectForKey:MGMWebDavURL];
			if (url!=nil)
				[urlField setStringValue:url];
			NSString *user = [defaults objectForKey:MGMWebDavUser];
			if (user!=nil)
				[userField setStringValue:user];
			NSString *password = [[MGMController sharedController] password];
			if (password!=nil)
				[passwordField setStringValue:password];
		}
	}
	return view;
}
- (void)releaseView {
	[view release];
	view = nil;
	urlField = nil;
	userField = nil;
	passwordField = nil;
	loginButton = nil;
}

- (void)setCurrentPlugIn:(BOOL)isCurrent {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (isCurrent) {
		webDav = [[MGMWebDav webDavWithDelegate:self] retain];
		userLoggingIn = YES;
		[self login];
	} else {
		[webDav release];
		webDav = nil;
		[defaults removeObjectForKey:MGMWebDavURL];
		[defaults removeObjectForKey:MGMWebDavUser];
	}
}

- (void)lockLogin {
	[urlField setEnabled:NO];
	[userField setEnabled:NO];
	[passwordField setEnabled:NO];
	[loginButton setEnabled:NO];
	[loginButton setTitle:[@"Logging In" localizedFor:self]];
}
- (void)unlockLogin {
	[urlField setEnabled:YES];
	[userField setEnabled:YES];
	[passwordField setEnabled:YES];
	[loginButton setEnabled:YES];
	[loginButton setTitle:[@"Login" localizedFor:self]];
}
- (void)login {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMWebDavURL]!=nil) {
		NSString *user = [defaults objectForKey:MGMWebDavUser];
		NSString *password = [[MGMController sharedController] password];
		[webDav setRootURL:[NSURL URLWithString:[defaults objectForKey:MGMWebDavURL]]];
		if (user!=nil)
			[webDav setUser:user password:password];
		MGMWebDavOptions *options = [MGMWebDavOptions optionsAtURI:nil];
		[webDav addHandler:options];
	}
}
- (IBAction)login:(id)sender {
	if ([urlField isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:[@"URL Required" localizedFor:self]];
		[alert setInformativeText:[@"Please enter the WebDav URL." localizedFor:self]];
		[alert runModal];
	} else {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:[urlField stringValue] forKey:MGMWebDavURL];
		[[MGMController sharedController] setPassword:[passwordField stringValue]];
		[defaults setObject:[userField stringValue] forKey:MGMWebDavUser];
		[self lockLogin];
		userLoggingIn = NO;
		[self login];
	}
}

- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError recevingOptions:(MGMWebDavOptions *)theOptions {
	NSLog(@"WebDav Error: %@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:[@"Account Error" localizedFor:self]];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
	[self unlockLogin];
}
- (void)webDav:(MGMWebDav *)theSender receivedOptions:(MGMWebDavOptions *)theOptions {
	MGMWebDavPropFind *propFind = [MGMWebDavPropFind propfindAtURI:nil];
	[propFind addProperty:MGMWebDavPResourceType];
	[webDav addHandler:propFind];
}
- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError recevingProperties:(MGMWebDavPropFind *)thePropFind {
	NSLog(@"WebDav Error: %@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:[@"Account Error" localizedFor:self]];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
	[self unlockLogin];
}
- (void)webDav:(MGMWebDav *)theSender receivedProperties:(MGMWebDavPropFind *)thePropFind {
	NSArray *contents = [thePropFind contents];
	if ([contents count]>0) {
		if ([[[contents objectAtIndex:0] objectForKey:MGMWebDavPResourceType] isEqual:MGMWebDavPRCollection]) {
			if (!userLoggingIn) {
				NSAlert *alert = [[NSAlert new] autorelease];
				[alert setMessageText:[@"Login Successful" localizedFor:self]];
				[alert setInformativeText:[@"You have successfully logged into your account." localizedFor:self]];
				[alert runModal];
				[self unlockLogin];
			}
			return;
		}
	}
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:[@"Account Error" localizedFor:self]];
	[alert setInformativeText:[@"The URL you have entered does not appear to be a directory." localizedFor:self]];
	[alert runModal];
	[self unlockLogin];
}

- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMWebDavURL]==nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:5 userInfo:[NSDictionary dictionaryWithObject:[@"Account is not logged in." localizedFor:self] forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:thePath receivedError:error];
		return;
	}
	
	[filePath release];
	filePath = [thePath retain];
	MGMWebDavPut *put = [MGMWebDavPut putAtURI:[theName addPercentEscapes]];
	[put setData:[NSData dataWithContentsOfFile:thePath]];
	[webDav addHandler:put];
}
- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError putting:(MGMWebDavPut *)thePut {
	NSString *finishPath = [[filePath retain] autorelease];
	[filePath release];
	filePath = nil;
	[[MGMController sharedController] upload:finishPath receivedError:theError];
}
- (void)webDav:(MGMWebDav *)theSender successfullyPut:(MGMWebDavPut *)thePut {
	NSString *finishPath = [[filePath retain] autorelease];
	[filePath release];
	filePath = nil;
	[[MGMController sharedController] uploadFinished:finishPath url:[[webDav rootURL] appendPathComponent:[thePut URI]]];
}
@end