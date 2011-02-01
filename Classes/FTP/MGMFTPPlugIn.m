//
//  MGMFTPPlugIn.m
//  CocoaShare
//
//  Created by James on 1/25/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMFTPPlugIn.h"
#import "MGMController.h"
#import "MGMAddons.h"

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";

NSString * const MGMFTPHost = @"MGMFTPHost";
NSString * const MGMFTPUser = @"MGMFTPUser";
NSString * const MGMFTPPath = @"MGMFTPPath";
NSString * const MGMFTPURL = @"MGMFTPURL";

@implementation MGMFTPPlugIn
- (void)dealloc {
	[self releaseView];
	[filePath release];
	[fileName release];
	[FTPTask terminate];
	[FTPTask release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[FTPPipe release];
	[FTPInputPipe release];
	[super dealloc];
}

- (BOOL)isAccountPlugIn {
	return YES;
}
- (NSString *)plugInName {
	return @"FTP";
}
- (NSView *)plugInView {
	if (view==nil) {
		if (![NSBundle loadNibNamed:@"FTPAccountPane" owner:self]) {
			NSLog(@"Unable to load FTP Account Pane");
		} else {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSString *host = [defaults objectForKey:MGMFTPHost];
			if (host!=nil)
				[hostField setStringValue:host];
			NSString *user = [defaults objectForKey:MGMFTPUser];
			if (user!=nil)
				[userField setStringValue:user];
			NSString *password = [[MGMController sharedController] password];
			if (password!=nil)
				[passwordField setStringValue:password];
			NSString *path = [defaults objectForKey:MGMFTPPath];
			if (path!=nil)
				[pathField setStringValue:path];
			NSString *url = [defaults objectForKey:MGMFTPURL];
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
		[defaults removeObjectForKey:MGMFTPHost];
		[defaults removeObjectForKey:MGMFTPUser];
		[defaults removeObjectForKey:MGMFTPPath];
		[defaults removeObjectForKey:MGMFTPURL];
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
		[alert setInformativeText:@"Please enter your ftp host."];
		[alert runModal];
	} else if ([[userField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"UserName Required"];
		[alert setInformativeText:@"Please enter your ftp username."];
		[alert runModal];
	} else if ([[passwordField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Password Required"];
		[alert setInformativeText:@"Please enter your ftp password."];
		[alert runModal];
	} else if ([[urlField stringValue] isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"URL Required"];
		[alert setInformativeText:@"Please enter the URL to where the files will be uploaded."];
		[alert runModal];
	} else {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[[MGMController sharedController] setPassword:[passwordField stringValue]];
		[defaults setObject:[hostField stringValue] forKey:MGMFTPHost];
		[defaults setObject:[userField stringValue] forKey:MGMFTPUser];
		[defaults setObject:[pathField stringValue] forKey:MGMFTPPath];
		[defaults setObject:[urlField stringValue] forKey:MGMFTPURL];
		[self lockLogin];
		
		FTPTask = [NSTask new];
		[FTPTask setLaunchPath:@"/usr/bin/ftp"];
		[FTPTask setArguments:[NSArray arrayWithObjects:@"-v", [NSString stringWithFormat:@"ftp://%@:%@@%@", [defaults objectForKey:MGMFTPUser], [[MGMController sharedController] password], [defaults objectForKey:MGMFTPHost]], nil]];
		
		FTPPipe = [NSPipe new];
		FTPInputPipe = [NSPipe new];
		[FTPTask setStandardError:FTPPipe];
		[FTPTask setStandardOutput:FTPPipe];
		[FTPTask setStandardInput:FTPInputPipe];
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(loginTestExit:) name:NSTaskDidTerminateNotification object:FTPTask];
		[notificationCenter addObserver:self selector:@selector(loginTestRead:) name:NSFileHandleReadCompletionNotification object:[FTPPipe fileHandleForReading]];
		[[FTPPipe fileHandleForReading] readInBackgroundAndNotify];
		
		[FTPTask launch];
	}
}
- (void)loginTestExit:(NSNotification *)theNotification {
	NSLog(@"FTP Exited");
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:NSTaskDidTerminateNotification object:FTPTask];
	[FTPTask release];
	FTPTask = nil;
	[notificationCenter removeObserver:self name:NSFileHandleReadCompletionNotification object:[FTPPipe fileHandleForReading]];
	[FTPPipe release];
	FTPPipe = nil;
	[FTPInputPipe release];
	FTPInputPipe = nil;
	
	if (![loginButton isEnabled]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Account Error"];
		[alert setInformativeText:@"Incorrect login info."];
		[alert runModal];
		[self unlockLogin];
	}
}
- (void)loginTestProcessFTPString:(NSString *)theString {
	//NSLog(@"%@", theString);
	NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceCharacterSet];
	NSRange range = [theString rangeOfCharacterFromSet:whiteSpace];
	if (range.location!=NSNotFound) {
		int response = [[theString substringToIndex:range.location] intValue];
		NSString *message = [theString substringFromIndex:range.location+range.length];
		if (response==250) {
			[self unlockLogin];
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:@"Login Successful"];
			[alert setInformativeText:@"You have sucessfully logged into your account."];
			[alert runModal];
			[[FTPInputPipe fileHandleForWriting] writeData:[@"bye\n" dataUsingEncoding:NSUTF8StringEncoding]];
		} else if (response==550) {
			[self unlockLogin];
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:@"Account Error"];
			[alert setInformativeText:@"You have sucessfully logged into your account, but the path you have entered does not exist."];
			[alert runModal];
			[[FTPInputPipe fileHandleForWriting] writeData:[@"bye\n" dataUsingEncoding:NSUTF8StringEncoding]];
		} else if (response==230) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			if ([[defaults objectForKey:MGMFTPPath] isEqual:@""]) {
				[self unlockLogin];
				NSAlert *alert = [[NSAlert new] autorelease];
				[alert setMessageText:@"Login Successful"];
				[alert setInformativeText:@"You have sucessfully logged into your account."];
				[alert runModal];
				[[FTPInputPipe fileHandleForWriting] writeData:[@"bye\n" dataUsingEncoding:NSUTF8StringEncoding]];
			} else {
				[[FTPInputPipe fileHandleForWriting] writeData:[[NSString stringWithFormat:@"cd %@\n", [[defaults objectForKey:MGMFTPPath] escapePath]] dataUsingEncoding:NSUTF8StringEncoding]];
			}
		} else if (response==530) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[self unlockLogin];
			[alert setMessageText:@"Account Error"];
			[alert setInformativeText:message];
			[alert runModal];
		} else if ([message rangeOfString:@"Can't connect or login to host"].location!=NSNotFound && ![loginButton isEnabled]) {
			[self unlockLogin];
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:@"Account Error"];
			[alert setInformativeText:message];
			[alert runModal];
		}
	}
}
- (void)loginTestRead:(NSNotification *)theNotification {
	NSData *data = [[theNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSArray *components = [dataString componentsSeparatedByString:@"\n"];
	NSCharacterSet *newline = [NSCharacterSet newlineCharacterSet];
	for (int i=0; i<[components count]; i++) {
		[self loginTestProcessFTPString:[[components objectAtIndex:i] stringByTrimmingCharactersInSet:newline]];
	}
	[[theNotification object] readInBackgroundAndNotify];
}

- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMFTPHost]==nil || [defaults objectForKey:MGMFTPUser]==nil || [defaults objectForKey:MGMFTPURL]==nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:5 userInfo:[NSDictionary dictionaryWithObject:@"Account is not logged in." forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:thePath receivedError:error];
		return;
	}
	
	[filePath release];
	filePath = [thePath retain];
	[fileName release];
	fileName = [theName retain];
	FTPTask = [NSTask new];
	[FTPTask setLaunchPath:@"/usr/bin/ftp"];
	[FTPTask setCurrentDirectoryPath:[filePath stringByDeletingLastPathComponent]];
	[FTPTask setArguments:[NSArray arrayWithObjects:@"-v", [NSString stringWithFormat:@"ftp://%@:%@@%@", [defaults objectForKey:MGMFTPUser], [[MGMController sharedController] password], [defaults objectForKey:MGMFTPHost]], nil]];
	
	FTPPipe = [NSPipe new];
	FTPInputPipe = [NSPipe new];
	[FTPTask setStandardError:FTPPipe];
	[FTPTask setStandardOutput:FTPPipe];
	[FTPTask setStandardInput:FTPInputPipe];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(uploadExit:) name:NSTaskDidTerminateNotification object:FTPTask];
	[notificationCenter addObserver:self selector:@selector(uploadRead:) name:NSFileHandleReadCompletionNotification object:[FTPPipe fileHandleForReading]];
	[[FTPPipe fileHandleForReading] readInBackgroundAndNotify];
	
	[FTPTask launch];
}
- (void)uploadExit:(NSNotification *)theNotification {
	NSLog(@"FTP Exited");
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:NSTaskDidTerminateNotification object:FTPTask];
	[FTPTask release];
	FTPTask = nil;
	[notificationCenter removeObserver:self name:NSFileHandleReadCompletionNotification object:[FTPPipe fileHandleForReading]];
	[FTPPipe release];
	FTPPipe = nil;
	[FTPInputPipe release];
	FTPInputPipe = nil;
	
	if (theNotification!=nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:@"Incorrect login info" forKey:NSLocalizedDescriptionKey]];
		NSString *finishPath = [[filePath retain] autorelease];
		[filePath release];
		filePath = nil;
		[fileName release];
		fileName = nil;
		[[MGMController sharedController] upload:finishPath receivedError:error];
	}
}
- (void)uploadProcessFTPString:(NSString *)theString {
	//NSLog(@"%@", theString);
	NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceCharacterSet];
	NSRange range = [theString rangeOfCharacterFromSet:whiteSpace];
	if (range.location!=NSNotFound) {
		int response = [[theString substringToIndex:range.location] intValue];
		NSString *message = [theString substringFromIndex:range.location+range.length];
		if (response==250) {
			[[FTPInputPipe fileHandleForWriting] writeData:[[NSString stringWithFormat:@"put %@ %@\n", [[filePath lastPathComponent] escapePath], [fileName escapePath]] dataUsingEncoding:NSUTF8StringEncoding]];
		} else if (response==226) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[[FTPInputPipe fileHandleForWriting] writeData:[@"bye\n" dataUsingEncoding:NSUTF8StringEncoding]];
			[self uploadExit:nil];
			NSString *url = [defaults objectForKey:MGMFTPURL];
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
		} else if (response==550) {
			[[FTPInputPipe fileHandleForWriting] writeData:[@"bye\n" dataUsingEncoding:NSUTF8StringEncoding]];
			[self uploadExit:nil];
			NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:@"The path to upload files to does not exist." forKey:NSLocalizedDescriptionKey]];
			NSString *finishPath = [[filePath retain] autorelease];
			[filePath release];
			filePath = nil;
			[fileName release];
			fileName = nil;
			[[MGMController sharedController] upload:finishPath receivedError:error];
		} else  if (response==421) {
			[[FTPInputPipe fileHandleForWriting] writeData:[@"bye\n" dataUsingEncoding:NSUTF8StringEncoding]];
			[self uploadExit:nil];
			NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
			NSString *finishPath = [[filePath retain] autorelease];
			[filePath release];
			filePath = nil;
			[fileName release];
			fileName = nil;
			[[MGMController sharedController] upload:finishPath receivedError:error];
		} else if (response==230) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			if ([[defaults objectForKey:MGMFTPPath] isEqual:@""]) {
				[[FTPInputPipe fileHandleForWriting] writeData:[[NSString stringWithFormat:@"put %@ %@\n", [[filePath lastPathComponent] escapePath], [fileName escapePath]] dataUsingEncoding:NSUTF8StringEncoding]];
			} else {
				[[FTPInputPipe fileHandleForWriting] writeData:[[NSString stringWithFormat:@"cd %@\n", [[defaults objectForKey:MGMFTPPath] escapePath]] dataUsingEncoding:NSUTF8StringEncoding]];
			}
		} else if ([message rangeOfString:@"Can't connect or login to host"].location!=NSNotFound) {
			NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
			NSString *finishPath = [[filePath retain] autorelease];
			[filePath release];
			filePath = nil;
			[fileName release];
			fileName = nil;
			[[MGMController sharedController] upload:finishPath receivedError:error];
		} else if ([message rangeOfString:@"Can't open"].location!=NSNotFound) {
			[[FTPInputPipe fileHandleForWriting] writeData:[@"bye\n" dataUsingEncoding:NSUTF8StringEncoding]];
			[self uploadExit:nil];
			NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
			NSString *finishPath = [[filePath retain] autorelease];
			[filePath release];
			filePath = nil;
			[fileName release];
			fileName = nil;
			[[MGMController sharedController] upload:finishPath receivedError:error];
		}
	}
}
- (void)uploadRead:(NSNotification *)theNotification {
	NSData *data = [[theNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSArray *components = [dataString componentsSeparatedByString:@"\n"];
	NSCharacterSet *newline = [NSCharacterSet newlineCharacterSet];
	for (int i=0; i<[components count]; i++) {
		[self uploadProcessFTPString:[[components objectAtIndex:i] stringByTrimmingCharactersInSet:newline]];
	}
	[[theNotification object] readInBackgroundAndNotify];
}
@end