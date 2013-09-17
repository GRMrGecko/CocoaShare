//
//  MGMTinyGrabPlugIn.m
//  CocoaShare
//
//  Created by James on 1/31/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMTinyGrabPlugIn.h"
#import "MGMController.h"
#import "MGMAddons.h"
#import <MGMUsers/MGMUsers.h>

NSString * const MGMTinyGrabPostMethod = @"POST";
NSString * const MGMTinyGrabURLForm = @"application/x-www-form-urlencoded";
NSString * const MGMTinyGrabContentType = @"content-type";

NSString * const MGMTinyGrabAPI = @"http://tinygrab.com/api/v3.php?m=%@";
NSString * const MGMTinyGrabAPIVerify = @"user/verify";
NSString * const MGMTinyGrabAPIUpload = @"grab/upload";

NSString * const MGMTinyGrabAPIRError = @"X-Error-Text";
NSString * const MGMTinyGrabAPIRErrorCode = @"X-Error-Code";
NSString * const MGMTinyGrabAPIREmail = @"X-User-Email";
NSString * const MGMTinyGrabAPIRJoinDate = @"X-User-Joindate";
NSString * const MGMTinyGrabAPIRName = @"X-User-Name";
NSString * const MGMTinyGrabAPIRPaid = @"X-User-Paid";

NSString * const MGMTinyGrabAPIRDate = @"X-Grab-Date";
NSString * const MGMTinyGrabAPIRID = @"X-Grab-Id";
NSString * const MGMTinyGrabAPIRURL = @"X-Grab-Url";

NSString * const MGMTinyGrabEmail = @"MGMTinyGrabEmail";
NSString * const MGMTinyGrabType = @"MGMTinyGrabType";

const BOOL MGMTinyGrabResponseInvisible = YES;

@implementation MGMTinyGrabPlugIn
- (void)dealloc {
	[self releaseView];
	[super dealloc];
}

- (BOOL)isAccountPlugIn {
	return YES;
}
- (NSString *)plugInName {
	return @"TinyGrab";
}
- (NSView *)plugInView {
	if (view==nil) {
		if (![NSBundle loadNibNamed:@"TinyGrabAccountPane" owner:self]) {
			NSLog(@"Unable to load TinyGrab Account Pane");
		} else {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSString *email = [defaults objectForKey:MGMTinyGrabEmail];
			if (email!=nil)
				[emailField setStringValue:email];
			NSString *password = [[MGMController sharedController] password];
			if (password!=nil)
				[passwordField setStringValue:password];
			NSString *type = [defaults objectForKey:MGMTinyGrabType];
			if (type!=nil)
				[typeField setStringValue:[[type capitalizedString] localizedFor:self]];
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
}

- (NSArray *)allowedExtensions {
	return [NSArray arrayWithObjects:@"png", @"jpg", nil];
}

- (void)setCurrentPlugIn:(BOOL)isCurrent {
	if (!isCurrent) {
		[[[MGMController sharedController] connectionManager] cancelAll];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults removeObjectForKey:MGMTinyGrabEmail];
	}
}

- (void)lockLogin {
	[emailField setEnabled:NO];
	[passwordField setEnabled:NO];
	[loginButton setEnabled:NO];
	[loginButton setTitle:[@"Logging In" localizedFor:self]];
}
- (void)unlockLogin {
	[emailField setEnabled:YES];
	[passwordField setEnabled:YES];
	[loginButton setEnabled:YES];
	[loginButton setTitle:[@"Login" localizedFor:self]];
}

- (IBAction)login:(id)sender {
	if ([[emailField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:[@"Email Required" localizedFor:self]];
		[alert setInformativeText:[@"Please enter your email." localizedFor:self]];
		[alert runModal];
	} else {
		[[MGMController sharedController] setPassword:[passwordField stringValue]];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:[emailField stringValue] forKey:MGMTinyGrabEmail];
		[typeField setStringValue:[@"Unknown" localizedFor:self]];
		[self lockLogin];
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:MGMTinyGrabAPI, MGMTinyGrabAPIVerify]]];
		[request setHTTPMethod:MGMTinyGrabPostMethod];
		[request setValue:MGMTinyGrabURLForm forHTTPHeaderField:MGMTinyGrabContentType];
		[request setHTTPBody:[[NSString stringWithFormat:@"email=%@&passwordhash=%@", [[defaults objectForKey:MGMTinyGrabEmail] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[[MGMController sharedController] password] MD5]] dataUsingEncoding:NSUTF8StringEncoding]];
		MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:request delegate:self];
		[handler setFailWithError:@selector(check:didFailWithError:)];
		[handler setFinish:@selector(checkDidFinish:)];
		[handler setInvisible:MGMTinyGrabResponseInvisible];
		[[[MGMController sharedController] connectionManager] addHandler:handler];
	}
}
- (IBAction)registerAccount:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://tinygrab.com/register"]];
}
- (void)check:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	NSLog(@"HTTP Error: %@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:[@"Account Error" localizedFor:self]];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
	[self unlockLogin];
}
- (void)checkDidFinish:(MGMURLBasicHandler *)theHandler {
	NSDictionary *headers = [[theHandler response] allHeaderFields];
	if ([headers objectForKey:MGMTinyGrabAPIRError]!=nil) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:[@"Account Error" localizedFor:self]];
		[alert setInformativeText:[headers objectForKey:MGMTinyGrabAPIRError]];
		[alert runModal];
		[self unlockLogin];
	} else {
		NSString *type = [headers objectForKey:MGMTinyGrabAPIRPaid];
		if (type==nil || [type isEqual:@"free"]) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:[@"Account Error" localizedFor:self]];
			[alert setInformativeText:[@"Only paid users are allowed to use TinyGrab in CocoaShare, sorry." localizedFor:self]];
			[alert runModal];
			[self unlockLogin];
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults removeObjectForKey:MGMTinyGrabEmail];
		} else {
			[typeField setStringValue:[[type capitalizedString] localizedFor:self]];
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject:type forKey:MGMTinyGrabType];
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:[@"Login Successful" localizedFor:self]];
			[alert setInformativeText:[@"You have sucessfully logged into your account." localizedFor:self]];
			[alert runModal];
			[self unlockLogin];
		}
	}
}

- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMTinyGrabEmail]==nil || [defaults objectForKey:MGMTinyGrabType]==nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:5 userInfo:[NSDictionary dictionaryWithObject:[@"Account is not logged in." localizedFor:self] forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:thePath receivedError:error];
		return;
	}
	
	srandomdev();
	NSString *boundary = [NSString stringWithFormat:@"----Boundary+%d", random()%100000];
	
	NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:MGMTinyGrabAPI, MGMTinyGrabAPIUpload]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120.0];
	[postRequest setHTTPMethod:MGMTinyGrabPostMethod];
	[postRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary, nil] forHTTPHeaderField:@"Content-Type"];
	
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	[data setObject:[defaults objectForKey:MGMTinyGrabEmail] forKey:@"email"];
	[data setObject:[[[MGMController sharedController] password] MD5] forKey:@"passwordhash"];
	[data setObject:[NSDictionary dictionaryWithObjectsAndKeys:thePath, MGMMPFPath, theName, MGMMPFName, nil] forKey:@"upload"];
	[postRequest setHTTPBody:[data buildMultiPartBodyWithBoundary:boundary]];
	MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:postRequest delegate:self];
	[handler setFailWithError:@selector(upload:didFailWithError:)];
	[handler setFinish:@selector(uploadDidFinish:)];
	[handler setInvisible:MGMTinyGrabResponseInvisible];
	[handler setObject:thePath];
	[[[MGMController sharedController] connectionManager] addHandler:handler];
}
- (void)upload:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	[[MGMController sharedController] upload:[theHandler object] receivedError:theError];
}
- (void)uploadDidFinish:(MGMURLBasicHandler *)theHandler {
	NSDictionary *headers = [[theHandler response] allHeaderFields];
	if ([headers objectForKey:MGMTinyGrabAPIRError]!=nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:[[headers objectForKey:MGMTinyGrabAPIRErrorCode] intValue] userInfo:[NSDictionary dictionaryWithObject:[headers objectForKey:MGMTinyGrabAPIRError] forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:[theHandler object] receivedError:error];
	} else {
		if ([headers objectForKey:MGMTinyGrabAPIRURL]!=nil) {
			[[MGMController sharedController] uploadFinished:[theHandler object] url:[NSURL URLWithString:[headers objectForKey:MGMTinyGrabAPIRURL]]];
		} else {
			NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:4 userInfo:[NSDictionary dictionaryWithObject:[@"Unable to receive url." localizedFor:self] forKey:NSLocalizedDescriptionKey]];
			[[MGMController sharedController] upload:[theHandler object] receivedError:error];
		}
	}
}

@end