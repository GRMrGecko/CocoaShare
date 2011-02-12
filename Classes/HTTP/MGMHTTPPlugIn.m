//
//  MGMHTTPPlugIn.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/18/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMHTTPPlugIn.h"
#import "MGMController.h"
#import "MGMAddons.h"
#import <MGMUsers/MGMUsers.h>

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";

NSString * const MGMHTTPURL = @"MGMHTTPURL";
NSString * const MGMHTTPUSER = @"MGMHTTPUSER";
NSString * const MGMHTTPPostMethod = @"POST";
NSString * const MGMHTTPURLForm = @"application/x-www-form-urlencoded";
NSString * const MGMHTTPContentType = @"content-type";

NSString * const MGMHTTPRSuccessful = @"successful";
NSString * const MGMHTTPRError = @"error";
NSString * const MGMHTTPRLoggedIn = @"loggedIn";
NSString * const MGMHTTPRURL = @"url";

const BOOL MGMHTTPResponseInvisible = YES;

@implementation MGMHTTPPlugIn
- (void)dealloc {
	[self releaseView];
	[super dealloc];
}

- (BOOL)isAccountPlugIn {
	return YES;
}
- (NSString *)plugInName {
	return @"HTTP";
}
- (NSView *)plugInView {
	if (view==nil) {
		if (![NSBundle loadNibNamed:@"HTTPAccountPane" owner:self]) {
			NSLog(@"Unable to load HTTP Account Pane");
		} else {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSString *url = [defaults objectForKey:MGMHTTPURL];
			if (url!=nil)
				[urlField setStringValue:url];
			NSString *user = [defaults objectForKey:MGMHTTPUSER];
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
	if (isCurrent) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults objectForKey:MGMHTTPURL]!=nil) {
			userLoggingIn = YES;
			loginTries = 0;
			[[[MGMController sharedController] connectionManager] connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[defaults objectForKey:MGMHTTPURL]]] delegate:self didFailWithError:@selector(check:didFailWithError:) didFinish:@selector(checkDidFinish:) invisible:MGMHTTPResponseInvisible object:nil];
		}
	} else {
		[[[MGMController sharedController] connectionManager] cancelAll];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults removeObjectForKey:MGMHTTPURL];
		[defaults removeObjectForKey:MGMHTTPUSER];
	}
}

- (void)login {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[defaults objectForKey:MGMHTTPURL]]];
	[request setHTTPMethod:MGMHTTPPostMethod];
	[request setValue:MGMHTTPURLForm forHTTPHeaderField:MGMHTTPContentType];
	[request setHTTPBody:[[NSString stringWithFormat:@"login=1&user=%@&password=%@", [[defaults objectForKey:MGMHTTPUSER] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[[MGMController sharedController] password] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
	[[[MGMController sharedController] connectionManager] connectionWithRequest:request delegate:self didFailWithError:@selector(check:didFailWithError:) didFinish:@selector(checkDidFinish:) invisible:MGMHTTPResponseInvisible object:nil];
}
- (void)check:(NSDictionary *)theData didFailWithError:(NSError *)theError {
	NSLog(@"HTTP Error: %@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:[@"Account Error" localizedFor:self]];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
	[self unlockLogin];
}
- (void)checkDidFinish:(NSDictionary *)theData {
	NSString *error = nil;
	NSDictionary *response = [NSPropertyListSerialization propertyListFromData:[theData objectForKey:MGMConnectionData] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:&error];
	if (error!=nil)
		NSLog(@"HTTP Error: %@", error);
	if (response!=nil) {
		if ([[response objectForKey:MGMHTTPRSuccessful] boolValue]) {
			if ([[response objectForKey:MGMHTTPRLoggedIn] boolValue] && !userLoggingIn) {
				NSAlert *alert = [[NSAlert new] autorelease];
				[alert setMessageText:[@"Login Successful" localizedFor:self]];
				[alert setInformativeText:[@"You have successfully logged into your account." localizedFor:self]];
				[alert runModal];
				[self unlockLogin];
			} else if (![[response objectForKey:MGMHTTPRLoggedIn] boolValue]) {
				NSLog(@"HTTP Error: Unknown response from server.");
			}
		} else {
			if (![[response objectForKey:MGMHTTPRLoggedIn] boolValue]) {
				if (userLoggingIn && loginTries==0) {
					loginTries++;
					[self login];
					return;
				}
				NSAlert *alert = [[NSAlert new] autorelease];
				[alert setMessageText:[@"Account Error" localizedFor:self]];
				[alert setInformativeText:[response objectForKey:MGMHTTPRError]];
				[alert runModal];
				[self unlockLogin];
			} else {
				NSLog(@"HTTP: Logged in.");
			}
		}
	} else {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:[@"Account Error" localizedFor:self]];
		[alert setInformativeText:[NSString stringWithFormat:[@"The URL %@ may not be a CocoaShare compatible URL." localizedFor:self], [[NSUserDefaults standardUserDefaults] objectForKey:MGMHTTPURL]]];
		[alert runModal];
		[self unlockLogin];
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
- (IBAction)login:(id)sender {
	userLoggingIn = NO;
	if ([[urlField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:[@"URL Required" localizedFor:self]];
		[alert setInformativeText:[@"Please enter the URL for the HTTP account." localizedFor:self]];
		[alert runModal];
	} else {
		[[MGMController sharedController] setPassword:[passwordField stringValue]];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:[urlField stringValue] forKey:MGMHTTPURL];
		[defaults setObject:[userField stringValue] forKey:MGMHTTPUSER];
		[self lockLogin];
		[self login];
	}
}

- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMHTTPURL]==nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:5 userInfo:[NSDictionary dictionaryWithObject:[@"Account is not logged in." localizedFor:self] forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:thePath receivedError:error];
		return;
	}
	
	srandomdev();
	NSString *boundary = [NSString stringWithFormat:@"----Boundary+%d", random()%100000];
	
	NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:MGMHTTPURL]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120.0];
	[postRequest setHTTPMethod:MGMHTTPPostMethod];
	[postRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary, nil] forHTTPHeaderField:@"Content-Type"];
	
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	[data setObject:@"file" forKey:@"upload"];
	[data setObject:[NSDictionary dictionaryWithObjectsAndKeys:thePath, MGMMPFPath, theName, MGMMPFName, nil] forKey:@"file"];
	[postRequest setHTTPBody:[data buildMultiPartBodyWithBoundary:boundary]];
	[[[MGMController sharedController] connectionManager] connectionWithRequest:postRequest delegate:self didFailWithError:@selector(upload:didFailWithError:) didFinish:@selector(uploadDidFinish:) invisible:MGMHTTPResponseInvisible object:thePath];
}
- (void)upload:(NSDictionary *)theData didFailWithError:(NSError *)theError {
	[[MGMController sharedController] upload:[theData objectForKey:MGMConnectionObject] receivedError:theError];
}
- (void)uploadDidFinish:(NSDictionary *)theData {
	NSString *error = nil;
	NSDictionary *response = [NSPropertyListSerialization propertyListFromData:[theData objectForKey:MGMConnectionData] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:&error];
	if (error!=nil)
		NSLog(@"HTTP Error: %@", error);
	if (response!=nil) {
		if ([[response objectForKey:MGMHTTPRSuccessful] boolValue]) {
			[[MGMController sharedController] uploadFinished:[theData objectForKey:MGMConnectionObject] url:[NSURL URLWithString:[response objectForKey:MGMHTTPRURL]]];
		} else {
			NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:[response objectForKey:MGMHTTPRError] forKey:NSLocalizedDescriptionKey]];
			[[MGMController sharedController] upload:[theData objectForKey:MGMConnectionObject] receivedError:error];
		}
	} else {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:[@"HTTP Server response is not a CocoaShare compatible response." localizedFor:self] forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:[theData objectForKey:MGMConnectionObject] receivedError:error];
	}
}
@end