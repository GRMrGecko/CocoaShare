//
//  MGMTwitpicPlugIn.m
//  CocoaShare
//
//  Created by James on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMTwitpicPlugIn.h"
#import "MGMController.h"
#import <MGMUsers/MGMUsers.h>

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";

NSString * const MGMTwitpicUser = @"MGMTwitpicUser";
NSString * const MGMTwitpicPost = @"MGMTwitpicPost";
NSString * const MGMTwitpicPostMethod = @"POST";
NSString * const MGMTwitpicURLForm = @"application/x-www-form-urlencoded";
NSString * const MGMTwitpicContentType = @"content-type";

const BOOL MGMTwitpicResponseInvisible = YES;

@implementation MGMTwitpicPlugIn
- (void)dealloc {
	[self releaseView];
	[filePath release];
	[fileName release];
	[postWindow release];
	[super dealloc];
}

- (BOOL)isAccountPlugIn {
	return YES;
}
- (NSString *)plugInName {
	return @"twitpic";
}
- (NSView *)plugInView {
	if (view==nil) {
		if (![NSBundle loadNibNamed:@"twitpicAccountPane" owner:self]) {
			NSLog(@"Unable to load twitpic Account Pane");
		} else {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSString *user = [defaults objectForKey:MGMTwitpicUser];
			if (user!=nil)
				[userField setStringValue:user];
			NSString *password = [[MGMController sharedController] password];
			if (password!=nil)
				[passwordField setStringValue:password];
			[postButton setState:([defaults boolForKey:MGMTwitpicPost] ? NSOnState : NSOffState)];
		}
	}
	return view;
}
- (void)releaseView {
	[view release];
	view = nil;
	userField = nil;
	passwordField = nil;
	postButton = nil;
}

- (NSArray *)allowedExtensions {
	return [NSArray arrayWithObjects:@"png", @"jpg", @"jpeg", @"gif", nil];
}

- (void)setCurrentPlugIn:(BOOL)isCurrent {
	if (!isCurrent) {
		[[[MGMController sharedController] connectionManager] cancelAll];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults removeObjectForKey:MGMTwitpicUser];
		[defaults removeObjectForKey:MGMTwitpicPost];
	}
}

- (IBAction)save:(id)sender {
	if ([userField isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"UserName Required"];
		[alert setInformativeText:@"Please enter your Twitter UserName."];
		[alert runModal];
	} else {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:[userField stringValue] forKey:MGMTwitpicUser];
		[defaults setBool:([postButton state]==NSOnState) forKey:MGMTwitpicPost];
		[[MGMController sharedController] setPassword:[passwordField stringValue]];
	}
}

- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName {
	[filePath release];
	filePath = [thePath retain];
	[fileName release];
	fileName = [theName retain];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMTwitpicPost]) {
		if (![NSBundle loadNibNamed:@"twitpicPostWindow" owner:self]) {
			NSLog(@"Unable to load twitpic Post Window");
		} else {
			[postWindow makeKeyAndOrderFront:self];
		}
	} else {
		[self sendFile:filePath withName:fileName post:NO message:nil];
	}
}
- (IBAction)post:(id)sender {
	[self sendFile:filePath withName:fileName post:YES message:[postView string]];
	[postWindow close];
	[postWindow release];
	postWindow = nil;
	postView = nil;
}
- (IBAction)upload:(id)sender {
	[self sendFile:filePath withName:fileName post:NO message:nil];
	[postWindow close];
	[postWindow release];
	postWindow = nil;
	postView = nil;
}
- (void)sendFile:(NSString *)thePath withName:(NSString *)theName post:(BOOL)shouldPost message:(NSString *)theMessage {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMTwitpicUser]==nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:5 userInfo:[NSDictionary dictionaryWithObject:@"Account is not logged in." forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:thePath receivedError:error];
		return;
	}
	
	srandomdev();
	NSString *boundary = [NSString stringWithFormat:@"----Boundary+%d", random()%100000];
	
	NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:(shouldPost ? @"https://twitpic.com/api/uploadAndPost" : @"https://twitpic.com/api/upload")] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120.0];
	[postRequest setHTTPMethod:MGMTwitpicPostMethod];
	[postRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary, nil] forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData *data = [NSMutableData data];
	[data appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[[defaults objectForKey:MGMTwitpicUser] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	
	[data appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[[[MGMController sharedController] password] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	
	if (theMessage!=nil) {
		[data appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[data appendData:[@"Content-Disposition: form-data; name=\"message\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[data appendData:[theMessage dataUsingEncoding:NSUTF8StringEncoding]];
		[data appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	[data appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media\"; filename=\"%@\"\r\n", theName] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[@"Content-Type: application/octet-stream\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[NSData dataWithContentsOfFile:thePath]];
	[data appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[[NSString stringWithFormat:@"--%@--", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postRequest setHTTPBody:data];
	[[[MGMController sharedController] connectionManager] connectionWithRequest:postRequest delegate:self didFailWithError:@selector(upload:didFailWithError:) didFinish:@selector(uploadDidFinish:) invisible:MGMTwitpicResponseInvisible object:nil];
}
- (void)upload:(NSDictionary *)theData didFailWithError:(NSError *)theError {
	NSString *uploadedPath = [[filePath retain] autorelease];
	[filePath release];
	filePath = nil;
	[fileName release];
	fileName = nil;
	[[MGMController sharedController] upload:uploadedPath receivedError:theError];
}
- (void)uploadDidFinish:(NSDictionary *)theData {
	NSError *error = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:[theData objectForKey:MGMConnectionData] options:0 error:&error];
	if (error!=nil) {
		NSString *uploadedPath = [[filePath retain] autorelease];
		[filePath release];
		filePath = nil;
		[fileName release];
		fileName = nil;
		[[MGMController sharedController] upload:uploadedPath receivedError:error];
		return;
	} else {
		if ([[[[document rootElement] attributeForName:@"stat"] stringValue] isEqual:@"fail"]) {
			NSArray *errors = [[document rootElement] elementsForName:@"err"];
			if ([errors count]>0) {
				NSString *uploadedPath = [[filePath retain] autorelease];
				[filePath release];
				filePath = nil;
				[fileName release];
				fileName = nil;
				NSXMLElement *errorE = [errors objectAtIndex:0];
				NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:[[[errorE attributeForName:@"code"] stringValue] intValue] userInfo:[NSDictionary dictionaryWithObject:[[errorE attributeForName:@"msg"] stringValue] forKey:NSLocalizedDescriptionKey]];
				[[MGMController sharedController] upload:uploadedPath receivedError:error];
				return;
			}
		} else {
			NSArray *mediaurls = [[document rootElement] elementsForName:@"mediaurl"];
			if ([mediaurls count]>0) {
				NSString *uploadedPath = [[filePath retain] autorelease];
				[filePath release];
				filePath = nil;
				[fileName release];
				fileName = nil;
				[[MGMController sharedController] uploadFinished:uploadedPath url:[NSURL URLWithString:[[mediaurls objectAtIndex:0] stringValue]]];
				return;
			}
		}
	}
	NSString *uploadedPath = [[filePath retain] autorelease];
	[filePath release];
	filePath = nil;
	[fileName release];
	fileName = nil;
	error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:3 userInfo:[NSDictionary dictionaryWithObject:@"Unknown response" forKey:NSLocalizedDescriptionKey]];
	[[MGMController sharedController] upload:uploadedPath receivedError:error];
}
@end