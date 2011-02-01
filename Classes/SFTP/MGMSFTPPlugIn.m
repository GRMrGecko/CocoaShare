//
//  MGMSFTPPlugIn.m
//  CocoaShare
//
//  Created by James on 1/26/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMSFTPPlugIn.h"
#import "MGMController.h"
#import "MGMAddons.h"

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";

NSString * const MGMSFTPHost = @"MGMSFTPHost";
NSString * const MGMSFTPUser = @"MGMSFTPUser";
NSString * const MGMSFTPPath = @"MGMSFTPPath";
NSString * const MGMSFTPURL = @"MGMSFTPURL";

@implementation MGMSFTPPlugIn
- (void)dealloc {
	[self releaseView];
	[filePath release];
	[fileName release];
	[SFTPTask terminate];
	[SFTPTask release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[SFTPPipe release];
	[SFTPInputPipe release];
	[super dealloc];
}

- (BOOL)isAccountPlugIn {
	return YES;
}
- (NSString *)plugInName {
	return @"SFTP (SSH)";
}
- (NSView *)plugInView {
	if (view==nil) {
		if (![NSBundle loadNibNamed:@"SFTPAccountPane" owner:self]) {
			NSLog(@"Unable to load SFTP Account Pane");
		} else {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSString *host = [defaults objectForKey:MGMSFTPHost];
			if (host!=nil)
				[hostField setStringValue:host];
			NSString *user = [defaults objectForKey:MGMSFTPUser];
			if (user!=nil)
				[userField setStringValue:user];
			NSString *password = [[MGMController sharedController] password];
			if (password!=nil)
				[passwordField setStringValue:password];
			NSString *path = [defaults objectForKey:MGMSFTPPath];
			if (path!=nil)
				[pathField setStringValue:path];
			NSString *url = [defaults objectForKey:MGMSFTPURL];
			if (url!=nil)
				[urlField setStringValue:url];
		}
	}
	return view;
}
- (void)releaseView {
	[view release];
	view = nil;
	hostField = nil;
	userField = nil;
	passwordField = nil;
	pathField = nil;
	urlField = nil;
	loginButton = nil;
}

- (void)setCurrentPlugIn:(BOOL)isCurrent {
	if (!isCurrent) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults removeObjectForKey:MGMSFTPHost];
		[defaults removeObjectForKey:MGMSFTPUser];
		[defaults removeObjectForKey:MGMSFTPPath];
		[defaults removeObjectForKey:MGMSFTPURL];
	}
}

- (void)lockLogin {
	[hostField setEnabled:NO];
	[userField setEnabled:NO];
	[passwordField setEnabled:NO];
	[pathField setEnabled:NO];
	[urlField setEnabled:NO];
	[loginButton setEnabled:NO];
	[loginButton setTitle:@"Logging In"];
}
- (void)unlockLogin {
	[hostField setEnabled:YES];
	[userField setEnabled:YES];
	[passwordField setEnabled:YES];
	[pathField setEnabled:YES];
	[urlField setEnabled:YES];
	[loginButton setEnabled:YES];
	[loginButton setTitle:@"Login"];
}
- (IBAction)login:(id)sender {
	if ([[hostField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Host Required"];
		[alert setInformativeText:@"Please enter your sftp host."];
		[alert runModal];
	} else if ([[userField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"UserName Required"];
		[alert setInformativeText:@"Please enter your sftp username."];
		[alert runModal];
	} else if ([[urlField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"URL Required"];
		[alert setInformativeText:@"Please enter the URL to where the files will be uploaded."];
		[alert runModal];
	} else {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[[MGMController sharedController] setPassword:[passwordField stringValue]];
		[defaults setObject:[hostField stringValue] forKey:MGMSFTPHost];
		[defaults setObject:[userField stringValue] forKey:MGMSFTPUser];
		[defaults setObject:[pathField stringValue] forKey:MGMSFTPPath];
		[defaults setObject:[urlField stringValue] forKey:MGMSFTPURL];
		[self lockLogin];
		
		SFTPTask = [NSTask new];
		[SFTPTask setLaunchPath:@"/usr/bin/ssh"];
		NSString *user = [defaults objectForKey:MGMSFTPUser];
		if (![[[MGMController sharedController] password] isEqual:@""])
			user = [user stringByAppendingFormat:@":%@", [[MGMController sharedController] password]];
		user = [user stringByAppendingFormat:@"@%@", [defaults objectForKey:MGMSFTPHost]];
		[SFTPTask setArguments:[NSArray arrayWithObjects:@"-v", user, nil]];
		
		SFTPPipe = [NSPipe new];
		SFTPInputPipe = [NSPipe new];
		[SFTPTask setStandardError:SFTPPipe];
		[SFTPTask setStandardOutput:SFTPPipe];
		[SFTPTask setStandardInput:SFTPInputPipe];
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(loginTestExit:) name:NSTaskDidTerminateNotification object:SFTPTask];
		[notificationCenter addObserver:self selector:@selector(loginTestRead:) name:NSFileHandleReadCompletionNotification object:[SFTPPipe fileHandleForReading]];
		[[SFTPPipe fileHandleForReading] readInBackgroundAndNotify];
		
		[SFTPTask launch];
	}
}
- (void)loginTestExit:(NSNotification *)theNotification {
	NSLog(@"SFTP Exited");
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:NSTaskDidTerminateNotification object:SFTPTask];
	[SFTPTask release];
	SFTPTask = nil;
	[notificationCenter removeObserver:self name:NSFileHandleReadCompletionNotification object:[SFTPPipe fileHandleForReading]];
	[SFTPPipe release];
	SFTPPipe = nil;
	[SFTPInputPipe release];
	SFTPInputPipe = nil;
	
	if (![loginButton isEnabled]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Account Error"];
		[alert setInformativeText:@"Incorrect login info."];
		[alert runModal];
		[self unlockLogin];
	}
}
- (void)loginTestProcessSFTPString:(NSString *)theString {
	//NSLog(@"%@", theString);
	if ([theString rangeOfString:@"Entering interactive session"].location!=NSNotFound) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([[defaults objectForKey:MGMSFTPPath] isEqual:@""]) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:@"Login Successful"];
			[alert setInformativeText:@"You have sucessfully logged into your account."];
			[alert runModal];
			[self unlockLogin];
		} else {
			[[SFTPInputPipe fileHandleForWriting] writeData:[[NSString stringWithFormat:@"cd %@\n", [[defaults objectForKey:MGMSFTPPath] escapePath]] dataUsingEncoding:NSUTF8StringEncoding]];
			[[SFTPInputPipe fileHandleForWriting] writeData:[@"echo $PWD\n" dataUsingEncoding:NSUTF8StringEncoding]];
		}
	} else if ([theString hasPrefix:@"/"]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([[defaults objectForKey:MGMSFTPPath] hasPrefix:theString]) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:@"Login Successful"];
			[alert setInformativeText:@"You have sucessfully logged into your account."];
			[alert runModal];
			[self unlockLogin];
		} else {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:@"Account Error"];
			[alert setInformativeText:@"You have sucessfully logged into your account, but the path you have entered does not exist."];
			[alert runModal];
			[self unlockLogin];
		}
		[[SFTPInputPipe fileHandleForWriting] writeData:[@"exit\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([theString rangeOfString:@"Permission denied"].location!=NSNotFound) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Account Error"];
		[alert setInformativeText:theString];
		[alert runModal];
		[self unlockLogin];
	} else if ([theString rangeOfString:@"Could not resolve"].location!=NSNotFound) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Account Error"];
		[alert setInformativeText:theString];
		[alert runModal];
		[self unlockLogin];
	}
}
- (void)loginTestRead:(NSNotification *)theNotification {
	NSData *data = [[theNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSArray *components = [dataString componentsSeparatedByString:@"\n"];
	NSCharacterSet *newline = [NSCharacterSet newlineCharacterSet];
	for (int i=0; i<[components count]; i++) {
		[self loginTestProcessSFTPString:[[components objectAtIndex:i] stringByTrimmingCharactersInSet:newline]];
	}
	[[theNotification object] readInBackgroundAndNotify];
}

- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMSFTPHost]==nil || [defaults objectForKey:MGMSFTPUser]==nil || [defaults objectForKey:MGMSFTPURL]==nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:5 userInfo:[NSDictionary dictionaryWithObject:@"Account is not logged in." forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:thePath receivedError:error];
		return;
	}
	
	[filePath release];
	filePath = [thePath retain];
	[fileName release];
	fileName = [theName retain];
	SFTPTask = [NSTask new];
	[SFTPTask setLaunchPath:@"/usr/bin/scp"];
	[SFTPTask setCurrentDirectoryPath:[filePath stringByDeletingLastPathComponent]];
	NSString *user = [defaults objectForKey:MGMSFTPUser];
	if (![[[MGMController sharedController] password] isEqual:@""])
		user = [user stringByAppendingFormat:@":%@", [[MGMController sharedController] password]];
	user = [user stringByAppendingFormat:@"@%@", [defaults objectForKey:MGMSFTPHost]];
	user = [user stringByAppendingFormat:@":%@", ([[defaults objectForKey:MGMSFTPPath] isEqual:@""] ? fileName : [[defaults objectForKey:MGMSFTPPath] stringByAppendingPathComponent:fileName])];
	[SFTPTask setArguments:[NSArray arrayWithObjects:@"-v", [filePath lastPathComponent], user, nil]];
	
	SFTPPipe = [NSPipe new];
	SFTPInputPipe = [NSPipe new];
	[SFTPTask setStandardError:SFTPPipe];
	[SFTPTask setStandardOutput:SFTPPipe];
	[SFTPTask setStandardInput:SFTPInputPipe];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(uploadExit:) name:NSTaskDidTerminateNotification object:SFTPTask];
	[notificationCenter addObserver:self selector:@selector(uploadRead:) name:NSFileHandleReadCompletionNotification object:[SFTPPipe fileHandleForReading]];
	[[SFTPPipe fileHandleForReading] readInBackgroundAndNotify];
	
	[SFTPTask launch];
}
- (void)uploadExit:(NSNotification *)theNotification {
	NSLog(@"SFTP Exited");
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:NSTaskDidTerminateNotification object:SFTPTask];
	[SFTPTask release];
	SFTPTask = nil;
	[notificationCenter removeObserver:self name:NSFileHandleReadCompletionNotification object:[SFTPPipe fileHandleForReading]];
	[SFTPPipe release];
	SFTPPipe = nil;
	[SFTPInputPipe release];
	SFTPInputPipe = nil;
	
	if (theNotification!=nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:@"Incorrect login info" forKey:NSLocalizedDescriptionKey]];
		NSString *finishPath = [[filePath retain] autorelease];
		[filePath release];
		filePath = nil;
		[[MGMController sharedController] upload:finishPath receivedError:error];
	}
}
- (void)uploadProcessSFTPString:(NSString *)theString {
	//NSLog(@"%@", theString);
	if ([theString rangeOfString:@"exit-status"].location!=NSNotFound) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[self uploadExit:nil];
		NSString *url = [defaults objectForKey:MGMSFTPURL];
		if (![url hasSuffix:@"/"])
			url = [url stringByAppendingFormat:@"/%@", fileName];
		else
			url = [url stringByAppendingString:fileName];
		NSString *finishPath = [[filePath retain] autorelease];
		[filePath release];
		filePath = nil;
		[fileName release];
		fileName = nil;
		[[MGMController sharedController] uploadFinished:finishPath url:[NSURL URLWithString:url]];
	} else if ([theString rangeOfString:@"Permission denied"].location!=NSNotFound) {
		[self uploadExit:nil];
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:theString forKey:NSLocalizedDescriptionKey]];
		NSString *finishPath = [[filePath retain] autorelease];
		[filePath release];
		filePath = nil;
		[fileName release];
		fileName = nil;
		[[MGMController sharedController] upload:finishPath receivedError:error];
	} else if ([theString rangeOfString:@"Could not resolve"].location!=NSNotFound) {
		[self uploadExit:nil];
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:theString forKey:NSLocalizedDescriptionKey]];
		NSString *finishPath = [[filePath retain] autorelease];
		[filePath release];
		filePath = nil;
		[fileName release];
		fileName = nil;
		[[MGMController sharedController] upload:finishPath receivedError:error];
	}
}
- (void)uploadRead:(NSNotification *)theNotification {
	NSData *data = [[theNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSArray *components = [dataString componentsSeparatedByString:@"\n"];
	NSCharacterSet *newline = [NSCharacterSet newlineCharacterSet];
	for (int i=0; i<[components count]; i++) {
		[self uploadProcessSFTPString:[[components objectAtIndex:i] stringByTrimmingCharactersInSet:newline]];
	}
	[[theNotification object] readInBackgroundAndNotify];
}
@end