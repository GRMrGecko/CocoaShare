//
//  MGMMobileMePlugIn.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/29/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMMobileMePlugIn.h"
#import "MGMController.h"
#import "MGMWebDav.h"
#import "MGMAddons.h"

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";

NSString * const MGMMobileMeUser = @"MGMMobileMeUser";
NSString * const MGMMobileMePath = @"MGMMobileMePath";

NSString * const MGMMobileMePublic = @"/Public/";
NSString * const MGMMobileMeFPath = @"path";
NSString * const MGMMobileMeFContents = @"contents";

@implementation MGMMobileMePlugIn
- (void)dealloc {
	[self releaseView];
	[publicFolder release];
	[webDav release];
	[filePath release];
	[super dealloc];
}

- (BOOL)isAccountPlugIn {
	return YES;
}
- (NSString *)plugInName {
	return @"MobileMe";
}
- (NSView *)plugInView {
	if (view==nil) {
		if (![NSBundle loadNibNamed:@"MobileMeAccountPane" owner:self]) {
			NSLog(@"Unable to load MobileMe Account Pane");
		} else {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSString *user = [defaults objectForKey:MGMMobileMeUser];
			if (user!=nil)
				[userField setStringValue:user];
			NSString *password = [[MGMController sharedController] password];
			if (password!=nil)
				[passwordField setStringValue:password];
			if (loggedIn) {
				loadingPublic = YES;
				MGMWebDavPropFind *propFind = [MGMWebDavPropFind propfindAtURI:MGMMobileMePublic];
				[propFind addProperty:MGMWebDavPResourceType];
				[propFind setDepth:1];
				[webDav addHandler:propFind];
			}
		}
	}
	return view;
}
- (void)releaseView {
	[view release];
	view = nil;
	userField = nil;
	passwordField = nil;
	loginButton = nil;
	publicOutline = nil;
	[publicFolder release];
	publicFolder = nil;
}

- (void)setCurrentPlugIn:(BOOL)isCurrent {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (isCurrent) {
		webDav = [[MGMWebDav webDavWithDelegate:self] retain];
		userLoggingIn = YES;
		[self login];
	} else {
		[webDav release];
		loggedIn = NO;
		[defaults removeObjectForKey:MGMMobileMeUser];
		[defaults removeObjectForKey:MGMMobileMePath];
	}
}

- (void)lockLogin {
	[userField setEnabled:NO];
	[passwordField setEnabled:NO];
	[loginButton setEnabled:NO];
	[loginButton setTitle:[@"Logging In" localizedFor:self]];
}
- (void)unlockLogin {
	[userField setEnabled:YES];
	[passwordField setEnabled:YES];
	[loginButton setEnabled:YES];
	[loginButton setTitle:[@"Login" localizedFor:self]];
}
- (void)login {
	NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:MGMMobileMeUser];
	NSString *password = [[MGMController sharedController] password];
	if (user!=nil) {
		[webDav setRootURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://idisk.mac.com/%@/", user]]];
		[webDav setUser:user password:password];
		MGMWebDavOptions *options = [MGMWebDavOptions optionsAtURI:nil];
		[webDav addHandler:options];
	}
}
- (IBAction)login:(id)sender {
	if ([userField isEqual:@""]) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:[@"UserName Required" localizedFor:self]];
		[alert setInformativeText:[@"Please enter your username." localizedFor:self]];
		[alert runModal];
	} else {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[[MGMController sharedController] setPassword:[passwordField stringValue]];
		NSString *user = [[userField stringValue] lowercaseString];
		NSRange range = [user rangeOfString:@"@"];
		if (range.location!=NSNotFound)
			user = [user substringToIndex:range.location];
		[defaults setObject:user forKey:MGMMobileMeUser];
		[self lockLogin];
		userLoggingIn = NO;
		[webDav cancelAll];
		[self login];
	}
}

- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError recevingOptions:(MGMWebDavOptions *)theOptions {
	NSLog(@"MobileMe Error: %@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:[@"Account Error" localizedFor:self]];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
	[self unlockLogin];
}
- (void)webDav:(MGMWebDav *)theSender receivedOptions:(MGMWebDavOptions *)theOptions {
	loadingPublic = NO;
	MGMWebDavPropFind *propFind = [MGMWebDavPropFind propfindAtURI:nil];
	[propFind addProperty:MGMWebDavPResourceType];
	[webDav addHandler:propFind];
}
- (void)webDav:(MGMWebDav *)theSender error:(NSError *)theError recevingProperties:(MGMWebDavPropFind *)thePropFind {
	NSLog(@"MobileMe Error: %@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:[@"Account Error" localizedFor:self]];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
	[self unlockLogin];
}

- (NSDictionary *)dataForPath:(NSString *)thePath inArray:(NSArray *)theArray {
	for (unsigned long i=0; i<[theArray count]; i++) {
		NSDictionary *thisData = [theArray objectAtIndex:i];
		if ([[thisData objectForKey:MGMMobileMeFPath] isEqual:thePath])
			return thisData;
		NSDictionary *data = [self dataForPath:thePath inArray:[thisData objectForKey:MGMMobileMeFContents]];
		if (data!=nil)
			return data;
	}
	return nil;
}
- (void)webDav:(MGMWebDav *)theSender receivedProperties:(MGMWebDavPropFind *)thePropFind {
	NSArray *contents = [thePropFind contents];
	if (loadingPublic && [contents count]>0) {
		NSMutableArray *currentArray = nil;
		if ([[[contents objectAtIndex:0] objectForKey:MGMWebDavPURI] isEqual:MGMMobileMePublic]) {
			loadingPublic = NO;
			[publicFolder release];
			publicFolder = [NSMutableArray new];
			currentArray = publicFolder;
		} else {
			currentArray = [[self dataForPath:[[contents objectAtIndex:0] objectForKey:MGMWebDavPURI] inArray:publicFolder] objectForKey:MGMMobileMeFContents];
		}
		for (unsigned long i=1; i<[contents count]; i++) {
			NSDictionary *content = [contents objectAtIndex:i];
			if ([[content objectForKey:MGMWebDavPResourceType] isEqual:MGMWebDavPRCollection]) {
				[currentArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[content objectForKey:MGMWebDavPURI], MGMMobileMeFPath, [NSMutableArray array], MGMMobileMeFContents, nil]];
			}
		}
		[publicOutline reloadData];
	} else {
		if ([contents count]>0) {
			if ([[[contents objectAtIndex:0] objectForKey:MGMWebDavPResourceType] isEqual:MGMWebDavPRCollection]) {
				loggedIn = YES;
				if (!userLoggingIn) {
					loadingPublic = YES;
					MGMWebDavPropFind *propFind = [MGMWebDavPropFind propfindAtURI:MGMMobileMePublic];
					[propFind addProperty:MGMWebDavPResourceType];
					[propFind setDepth:1];
					[webDav addHandler:propFind];
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
}
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(NSDictionary *)item {
	return (item==nil ? [publicFolder count] : [[item objectForKey:MGMMobileMeFContents] count]);
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(NSDictionary *)item {
	if ([[tableColumn identifier] isEqual:@"name"]) {
		return [[item objectForKey:MGMMobileMeFPath] lastPathComponent];
	} else if ([[tableColumn identifier] isEqual:@"selected"]) {
		return [NSNumber numberWithBool:([[item objectForKey:MGMMobileMeFPath] isEqual:[[NSUserDefaults standardUserDefaults] objectForKey:MGMMobileMePath]])];
	}
	return @"";
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(NSDictionary *)item {
	return (item==nil ? ([publicFolder count]>0) : ([[item objectForKey:MGMMobileMeFContents] count]>0));
}
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(NSDictionary *)item {
	return (item==nil ? [publicFolder objectAtIndex:index] : [[item objectForKey:MGMMobileMeFContents] objectAtIndex:index]);
}
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(NSDictionary *)item {
	if ([object boolValue])
		[[NSUserDefaults standardUserDefaults] setObject:[item objectForKey:MGMMobileMeFPath] forKey:MGMMobileMePath];
	else
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:MGMMobileMePath];
	[publicOutline reloadData];
}

- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMMobileMeUser]==nil) {
		NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:5 userInfo:[NSDictionary dictionaryWithObject:[@"Account is not logged in." localizedFor:self] forKey:NSLocalizedDescriptionKey]];
		[[MGMController sharedController] upload:thePath receivedError:error];
		return;
	}
	
	[filePath release];
	filePath = [thePath retain];
	NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:MGMMobileMePath];
	if (path==nil) path = MGMMobileMePublic;
	MGMWebDavPut *put = [MGMWebDavPut putAtURI:[path stringByAppendingPathComponent:theName]];
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
	NSString *url = [NSString stringWithFormat:@"https://public.me.com/ix/%@/%@", [[NSUserDefaults standardUserDefaults] objectForKey:MGMMobileMeUser], [[thePut URI] replace:MGMMobileMePublic with:@""]];
	[[MGMController sharedController] uploadFinished:finishPath url:[NSURL URLWithString:url]];
}
@end