//
//  MGMController.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMController.h"
#import "MGMFileManager.h"
#import "MGMPathSubscriber.h"
#import "MGMLoginItems.h"
#import "MGMMenuItem.h"
#import "RegexKitLite.h"
#import <MGMUsers/MGMUsers.h>
#import <GeckoReporter/GeckoReporter.h>
#import <Growl/GrowlApplicationBridge.h>
#import <Carbon/Carbon.h>

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";
NSString * const MGMVersion = @"MGMVersion";
NSString * const MGMLaunchCount = @"MGMLaunchCount";

NSString * const MGMDisplay = @"MGMDisplay";
NSString * const MGMStartup = @"MGMStartup";
NSString * const MGMUploadName = @"MGMUploadName";
NSString * const MGMHistoryCount = @"MGMHistoryCount";
NSString * const MGMGrowlErrors = @"MGMGrowlErrors";
NSString * const MGMUploadLimit = @"MGMUploadLimit";

NSString * const MGMHistoryPlist = @"history.plist";
NSString * const MGMHURL = @"url";
NSString * const MGMHDate = @"date";

NSString * const MGMESound = @"MGME%dSound";
NSString * const MGMEPath = @"MGME%dPath";
NSString * const MGMEDelete = @"MGME%dDelete";
NSString * const MGMEGrowl = @"MGME%dGrowl";
const int MGMEUploadingAutomatic = 0;
const int MGMEUploadedAutomatic = 1;
const int MGMEUploading = 2;
const int MGMEUploaded = 3;
NSString * const MGMEventNotification = @"MGMEventNotification";
NSString * const MGMEvent = @"event";
NSString * const MGMEventPath = @"path";
NSString * const MGMEventURL = @"URL";

NSString * const MGMFiltersPlist = @"filters.plist";
NSString * const MGMFPath = @"path";
NSString * const MGMFFilter = @"filter";

NSString * const MGMPluginFolder = @"PlugIns";
NSString * const MGMCurrentPlugIn = @"MGMCurrentPlugIn";

NSString * const MGMKCType = @"application password";
NSString * const MGMKCName = @"CocoaShare";

NSString * const MGMUPath = @"path";
NSString * const MGMUAutomatic = @"automatic";
NSString * const MGMNSStringPboardType = @"NSStringPboardType";
NSString * const MGMNSPasteboardTypeString = @"public.utf8-plain-text";

OSStatus frontAppChanged(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	ProcessSerialNumber thisProcess;
	GetCurrentProcess(&thisProcess);
	ProcessSerialNumber newProcess;
	GetFrontProcess(&newProcess);
	Boolean same;
	SameProcess(&newProcess, &thisProcess, &same);
	if (!same)
		[(MGMController *)userData setFrontProcess:&newProcess];
    return (CallNextEventHandler(nextHandler, theEvent));
}

static MGMController *MGMSharedController;

@implementation MGMController
+ (id)sharedController {
	if (MGMSharedController==nil) {
		MGMSharedController = [MGMController new];
	}
	return MGMSharedController;
}
- (id)init {
	if (MGMSharedController!=nil) {
		if ((self = [super init]))
			[self release];
		self = MGMSharedController;
	} else if ((self = [super init])) {
		MGMSharedController = self;
	}
	return self;
}
- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setup) name:MGMGRDoneNotification object:nil];
	[MGMReporter sharedReporter];
}
- (void)setup {
	[GrowlApplicationBridge setGrowlDelegate:nil];
	
	connectionManager = [[MGMURLConnectionManager managerWithCookieStorage:[MGMUser cookieStorage]] retain];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[self registerDefaults];
	if ([defaults integerForKey:MGMLaunchCount]!=5) {
		[defaults setInteger:[defaults integerForKey:MGMLaunchCount]+1 forKey:MGMLaunchCount];
		if ([defaults integerForKey:MGMLaunchCount]==5) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:[@"Donations" localized]];
			[alert setInformativeText:[@"Thank you for using CocoaShare. CocoaShare is donation supported software. If you like using it, please consider giving a donation to help with development." localized]];
			[alert addButtonWithTitle:[@"Yes" localized]];
			[alert addButtonWithTitle:[@"No" localized]];
			int result = [alert runModal];
			if (result==1000)
				[self donate:self];
		}
	}
	
	if ([defaults boolForKey:MGMStartup])
		[[MGMLoginItems items] addSelf];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMHistoryPlist]]) {
		history = [[NSMutableArray arrayWithContentsOfFile:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMHistoryPlist]] retain];
		[self updateMenu];
	} else {
		history = [NSMutableArray new];
		[history writeToFile:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMHistoryPlist] atomically:YES];
		[self updateMenu];
	}
	
	saveLock = [NSLock new];
	filterWatcher = [MGMPathSubscriber sharedPathSubscriber];
	[filterWatcher setDelegate:self];
	if ([manager fileExistsAtPath:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMFiltersPlist]]) {
		filters = [[NSMutableArray arrayWithContentsOfFile:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMFiltersPlist]] retain];
		[self updateFilterWatcher];
	} else {
		filters = [NSMutableArray new];
		[self saveFilters];
	}
	filtersEnabled = YES;
	
	if ([defaults integerForKey:MGMDisplay]>0)
		[self addMenu];
	
	preferences = [MGMPreferences new];
    [preferences addPreferencesPaneClassName:@"MGMGeneralPane"];
    [preferences addPreferencesPaneClassName:@"MGMAccountPane"];
    [preferences addPreferencesPaneClassName:@"MGMAutoUploadPane"];
    [preferences addPreferencesPaneClassName:@"MGMEventsPane"];
	
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassApplication;
	eventType.eventKind = kEventAppFrontSwitched;
	EventHandlerUPP handlerUPP = NewEventHandlerUPP(frontAppChanged);
	InstallApplicationEventHandler(handlerUPP, 1, &eventType, self, NULL);
	
	if ([defaults integerForKey:MGMLaunchCount]==2)
		[preferences showPreferences];
	
	about = [MGMAbout new];
	
	uploads = [NSMutableArray new];
	
	[self loadPlugIns];
}
- (void)dealloc {
	[connectionManager release];
	[preferences release];
	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
	[statusItem release];
	[menuItem release];
	[history release];
	[filters release];
	[saveLock release];
	[filterWatcher release];
	[accountPlugIns release];
	[plugIns release];
	[uploads release];
	[super dealloc];
}

- (void)registerDefaults {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults setObject:[[MGMSystemInfo info] applicationVersion] forKey:MGMVersion];
	[defaults setObject:[NSNumber numberWithInt:1] forKey:MGMLaunchCount];
	
	[defaults setObject:[NSNumber numberWithInt:([[MGMSystemInfo info] isUIElement] ? 2 : 0)] forKey:MGMDisplay];
	[defaults setObject:[NSNumber numberWithBool:[[MGMLoginItems items] selfExists]] forKey:MGMStartup];
	[defaults setObject:[NSNumber numberWithInt:0] forKey:MGMUploadName];
	[defaults setObject:[NSNumber numberWithInt:5] forKey:MGMHistoryCount];
	[defaults setObject:[NSNumber numberWithInt:5] forKey:MGMUploadLimit];
	
	[defaults setObject:[NSNumber numberWithInt:2] forKey:[NSString stringWithFormat:MGMEDelete, MGMEUploadedAutomatic]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (MGMURLConnectionManager *)connectionManager {
	return connectionManager;
}
- (MGMPreferences *)preferences {
	return preferences;
}

- (void)loadPlugIns {
	NSFileManager *manager = [NSFileManager defaultManager];
	[accountPlugIns release];
	accountPlugIns = [NSMutableArray new];
	[plugIns release];
	plugIns = [NSMutableArray new];
	
	NSArray *checkPaths = [NSArray arrayWithObjects:[[NSBundle mainBundle] builtInPlugInsPath], [[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMPluginFolder], nil];
	for (int i=0; i<[checkPaths count]; i++) {
		NSArray *plugInsFolder = [manager contentsOfDirectoryAtPath:[checkPaths objectAtIndex:i]];
		for (int p=0; p<[plugInsFolder count]; p++) {
			NSString *path = [[[checkPaths objectAtIndex:i] stringByAppendingPathComponent:[plugInsFolder objectAtIndex:p]] stringByResolvingSymlinksInPath];
			NSBundle *bundle = [NSBundle bundleWithPath:path];
			if (bundle!=nil) {
				Class plugInClass = [bundle principalClass];
				id<MGMPlugInProtocol> plugIn = [[[plugInClass alloc] init] autorelease];
				if (plugIn!=nil && [plugIn respondsToSelector:@selector(isAccountPlugIn)] && [plugIn isAccountPlugIn])
					[accountPlugIns addObject:plugIn];
				else if (plugIn!=nil)
					[plugIns addObject:plugIn];
			}
		}
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *currentPlugInName = [defaults objectForKey:MGMCurrentPlugIn];
	BOOL foundCurrentPlugIn = NO;
	for (int i=0; i<[accountPlugIns count]; i++) {
		if ([NSStringFromClass([[accountPlugIns objectAtIndex:i] class]) isEqual:currentPlugInName]) {
			currentPlugIn = [accountPlugIns objectAtIndex:i];
			currentPlugInIndex = i;
			if ([currentPlugIn respondsToSelector:@selector(setCurrentPlugIn:)]) [currentPlugIn setCurrentPlugIn:YES];
			foundCurrentPlugIn = YES;
			break;
		}
	}
	if (!foundCurrentPlugIn && [accountPlugIns count]>0)
		[self setCurrentPlugIn:[accountPlugIns objectAtIndex:0]];
}
- (NSArray *)accountPlugIns {
	return accountPlugIns;
}
- (NSArray *)plugIns {
	return plugIns;
}
- (void)setCurrentPlugIn:(id)thePlugIn {
	int plugInIndex = [accountPlugIns indexOfObject:thePlugIn];
	if (plugInIndex>=0) {
		[self removePassword];
		if ([currentPlugIn respondsToSelector:@selector(setCurrentPlugIn:)]) [currentPlugIn setCurrentPlugIn:NO];
		currentPlugIn = thePlugIn;
		currentPlugInIndex = plugInIndex;
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromClass([currentPlugIn class]) forKey:MGMCurrentPlugIn];
		if ([currentPlugIn respondsToSelector:@selector(setCurrentPlugIn:)]) [currentPlugIn setCurrentPlugIn:YES];
	}
}
- (id<MGMPlugInProtocol>)currentPlugIn {
	return currentPlugIn;
}
- (int)currentPlugInIndex {
	return currentPlugInIndex;
}

- (void)setFrontProcess:(ProcessSerialNumber *)theProcess {
	frontProcess = *theProcess;
	/*CFStringRef name;
	CopyProcessName(theProcess, &name);
	if (name!=NULL) {
		NSLog(@"%@ became front", (NSString *)name);
		CFRelease(name);
	}*/
}
- (void)becomeFront:(NSWindow *)theWindow {
	if (theWindow!=nil) {
		windowCount++;
		if ([[MGMSystemInfo info] isUIElement])
			[theWindow setLevel:NSFloatingWindowLevel];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frontWindowClosed:) name:NSWindowWillCloseNotification object:theWindow];
	}
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}
- (void)resignFront {
	SetFrontProcess(&frontProcess);
}
- (void)frontWindowClosed:(NSNotification *)theNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:[theNotification name] object:[theNotification object]];
	windowCount--;
	if (windowCount==0)
		[self resignFront];
}

- (void)addMenu {
	if (statusItem==nil) {
		menuItem = [[MGMMenuItem alloc] initWithFrame:NSZeroRect];
		[menuItem setDelegate:self];
		[menuItem setImage:[NSImage imageNamed:@"menuicon"]];
		[menuItem setAlternateImage:[NSImage imageNamed:@"menuiconselected"]];
		[menuItem setToolTip:@"CocoaShare"];
		statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
		[statusItem setView:menuItem];
	}
}
- (void)removeMenu {
	if (statusItem!=nil) {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
		[statusItem release];
		statusItem = nil;
		[menuItem release];
		menuItem = nil;
	}
}
- (void)setDockHidden:(BOOL)isHidden {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *path = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"];
	if ([manager isWritableFileAtPath:path]) {
		NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
		[infoDict setObject:[NSNumber numberWithBool:isHidden] forKey:@"LSUIElement"];
		[infoDict writeToFile:path atomically:NO];
		NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
		[manager setAttributes:attributes ofItemAtPath:[bundle bundlePath]];
		
		if (isHidden) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:[@"Restart Required" localized]];
			[alert setInformativeText:[@"Inorder to hide the dock, you must restart CocoaShare. Do you want to restart CocoaShare now?" localized]];
			[alert addButtonWithTitle:[@"Yes" localized]];
			[alert addButtonWithTitle:[@"No" localized]];
			int result = [alert runModal];
			if (result==1000) {
				//Took from Sparkle.
				NSString *pathToRelaunch = [[NSBundle mainBundle] bundlePath];
				NSString *relaunchPath = [[[NSBundle bundleWithIdentifier:@"org.andymatuschak.Sparkle"] resourcePath] stringByAppendingPathComponent:@"relaunch"];
				[NSTask launchedTaskWithLaunchPath:relaunchPath arguments:[NSArray arrayWithObjects:pathToRelaunch, [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]], nil]];
				[[NSApplication sharedApplication] terminate:self];
			}
		}
	} else {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:[@"Unable to change dock" localized]];
		[alert setInformativeText:[NSString stringWithFormat:[@"CocoaShare is unable to %@ the dock due to permissions. To fix this issue, right click on CocoaShare and choose Get Info to make CocoaShare writable." localized], (isHidden ? [@"hide" localized] : [@"unhide" localized])]];
		[alert runModal];
	}
	if (!isHidden) {
		ProcessSerialNumber psn = {0, kCurrentProcess};
		TransformProcessType(&psn, kProcessTransformToForegroundApplication);
		[self resignFront];
		[self performSelector:@selector(becomeFront:) withObject:[preferences preferencesWindow] afterDelay:0.0];
	}
}

- (void)menuClicked:(id)sender {
	[statusItem popUpStatusItemMenu:mainMenu];
}
- (void)menuDraggingEntered:(id)sender {
	[menuItem setImage:[NSImage imageNamed:@"menuicondrag"]];
}
- (void)menuDraggingExited:(id)sender {
	[menuItem setImage:[NSImage imageNamed:@"menuicon"]];
}
- (void)menu:(id)sender droppedFiles:(NSArray *)files {
	NSFileManager *manager = [NSFileManager defaultManager];
	for (int i=0; i<[files count]; i++) {
		BOOL directory = NO;
		if ([manager fileExistsAtPath:[files objectAtIndex:i] isDirectory:&directory]) {
			if (directory) {
				NSAlert *alert = [[NSAlert new] autorelease];
				[alert setMessageText:[@"Upload Error" localized]];
				[alert setInformativeText:[@"Uploading of directories is impossible." localized]];
				[alert runModal];
				continue;
			}
			[self addPathToUploads:[files objectAtIndex:i] isAutomatic:NO];
		}
	}
}

- (NSMutableArray *)history {
	return history;
}
- (void)updateMenu {
	int splitterIndex = 0;
	for (int i=0; i<[mainMenu numberOfItems]; i++) {
		if ([[mainMenu itemAtIndex:i] isSeparatorItem]) {
			splitterIndex = i;
			break;
		}
		[mainMenu removeItemAtIndex:i];
		i--;
	}
	if ([history count]>0) {
		for (int i=0; i<[history count]; i++) {
			NSDictionary *historyItem = [history objectAtIndex:i];
			NSMenuItem *item = [[NSMenuItem new] autorelease];
			NSDateFormatter *formatter = [[NSDateFormatter new] autorelease];
			[formatter setDateFormat:[@"MMMM d, yyyy h:mm:ss a" localized]];
			NSString *date = [formatter stringFromDate:[historyItem objectForKey:MGMHDate]];
			if (date!=nil)
				[item setTitle:date];
			else
				[item setTitle:[NSString stringWithFormat:@"%@", [historyItem objectForKey:MGMHDate]]];
			[item setRepresentedObject:[historyItem objectForKey:MGMHURL]];
			[item setTarget:self];
			[item setAction:@selector(copyHistoryItem:)];
			[mainMenu insertItem:item atIndex:splitterIndex];
		}
	} else {
		NSMenuItem *item = [[NSMenuItem new] autorelease];
		[item setTitle:[@"No Upload History" localized]];
		[item setEnabled:NO];
		[mainMenu insertItem:item atIndex:splitterIndex];
	}
}
- (IBAction)copyHistoryItem:(id)sender {
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	[pboard declareTypes:[NSArray arrayWithObjects:MGMNSStringPboardType, MGMNSPasteboardTypeString, nil] owner:nil];
	[pboard setString:[sender representedObject] forType:MGMNSStringPboardType];
	[pboard setString:[sender representedObject] forType:MGMNSPasteboardTypeString];
}
- (void)addURLToHistory:(NSURL *)theURL {
	[history addObject:[NSDictionary dictionaryWithObjectsAndKeys:[theURL absoluteString], MGMHURL, [NSDate date], MGMHDate, nil]];
	int maxHistoryItems = [[NSUserDefaults standardUserDefaults] integerForKey:MGMHistoryCount];
	int itemsToDelete = [history count]-maxHistoryItems;
	if (itemsToDelete>0) {
		for (int i=0; i<itemsToDelete; i++) {
			[history removeObjectAtIndex:0];
		}
	}
	[history writeToFile:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMHistoryPlist] atomically:YES];
	[self updateMenu];
}

- (IBAction)uploadFile:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:YES];
	[panel setTitle:[@"Choose File(s)" localized]];
	[panel setPrompt:[@"Choose" localized]];
	[self becomeFront:nil];
	int returnCode = [panel runModal];
	if (returnCode==NSOKButton) {
		for (int i=0; i<[[panel URLs] count]; i++) {
			[self addPathToUploads:[[[panel URLs] objectAtIndex:i] path] isAutomatic:NO];
		}
	}
	[self resignFront];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	if (!flag)
		[self preferences:self];
	return YES;
}
- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)theFiles {
	for (int i=0; i<[theFiles count]; i++) {
		[self addPathToUploads:[theFiles objectAtIndex:i] isAutomatic:NO];
	}
}

- (IBAction)disableFilters:(id)sender {
	filtersEnabled = !filtersEnabled;
	[disableFilters setTitle:(filtersEnabled ? [@"Disable Auto Upload" localized] : [@"Enable Auto Upload" localized])];
}
- (IBAction)about:(id)sender {
	[about show];
	[self becomeFront:[about window]];
}
- (IBAction)preferences:(id)sender {
	[preferences showPreferences];
	[self becomeFront:[preferences preferencesWindow]];
}
- (IBAction)donate:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=U9LTDN57NPZ44"]];
}
- (IBAction)quit:(id)sender {
	[[MGMLoginItems items] removeSelf];
	[[NSApplication sharedApplication] terminate:self];
}

- (NSMutableArray *)filters {
	return filters;
}
- (void)saveFilters {
	if (saveCount==2)
		return;
	saveCount++;
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[saveLock lock];
	[filters writeToFile:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMFiltersPlist] atomically:YES];
	[self updateFilterWatcher];
	saveCount--;
	[pool drain];
	[saveLock unlock];
}
- (MGMPathSubscriber *)filterWatcher {
	return filterWatcher;
}
- (NSArray *)filtersForPath:(NSString *)thePath {
	NSMutableArray *filtersFound = [NSMutableArray array];
	for (int i=0; i<[filters count]; i++) {
		NSString *path = [[[filters objectAtIndex:i] objectForKey:MGMFPath] stringByExpandingTildeInPath];
		if ([path isEqual:thePath])
			[filtersFound addObject:[filters objectAtIndex:i]];
	}
	return filtersFound;
}
- (void)updateFilterWatcher {
	[filterWatcher removeAllPaths];
	for (int i=0; i<[filters count]; i++) {
		NSDictionary *filter = [filters objectAtIndex:i];
		if (![[filter objectForKey:MGMFFilter] isEqual:@""]) {
			NSString *path = [[filter objectForKey:MGMFPath] stringByExpandingTildeInPath];
			if (![path isEqual:@""])
				[filterWatcher addPath:path];
		}
	}
}
- (void)subscribedPathChanged:(NSString *)thePath {
	if (filtersEnabled) {
		NSFileManager *manager = [NSFileManager defaultManager];
		int uploadLimit = [[NSUserDefaults standardUserDefaults] integerForKey:MGMUploadLimit];
		NSDate *dateLimit = [NSDate dateWithTimeIntervalSinceNow:-uploadLimit];
		NSArray *filtersFound = [self filtersForPath:thePath];
		NSArray *files = [manager contentsOfDirectoryAtPath:thePath];
		for (int i=0; i<[files count]; i++) {
			NSString *file = [files objectAtIndex:i];
			NSString *fullPath = [thePath stringByAppendingPathComponent:file];
			NSDictionary *attributes = [manager attributesOfItemAtPath:fullPath];
			if (uploadLimit!=0 && [[attributes objectForKey:NSFileCreationDate] earlierDate:dateLimit]!=dateLimit)
				continue;
			BOOL directory = NO;
			if ([manager fileExistsAtPath:fullPath isDirectory:&directory] && !directory) {
				for (int f=0; f<[filtersFound count]; f++) {
					NSString *filter = [[filtersFound objectAtIndex:f] objectForKey:MGMFFilter];
					if ([filter hasPrefix:@"MD:"]) {
						if ([filter hasPrefix:@"MD: "])
							filter = [filter substringFromIndex:4];
						else
							filter = [filter substringFromIndex:3];
						
						MDItemRef metadata = MDItemCreate(kCFAllocatorDefault, (CFStringRef)fullPath);
						if (metadata!=NULL) {
							NSArray *items = (NSArray *)MDItemCopyAttributeNames(metadata);
							for (int m=0; m<[items count]; m++) {
								id item = (id)MDItemCopyAttribute(metadata, (CFStringRef)[items objectAtIndex:m]);
								if ([[items objectAtIndex:m] isMatchedByRegex:filter])
									[self addPathToUploads:fullPath isAutomatic:YES];
								else if ([item isKindOfClass:[NSString class]] && [item isMatchedByRegex:filter])
									[self addPathToUploads:fullPath isAutomatic:YES];
								if (item!=nil)
									CFRelease((CFTypeRef)item);
							}
							if (items!=nil)
								CFRelease((CFArrayRef)items);
							CFRelease(metadata);
						} else {
							NSLog(@"Unable to get metadata of %@", fullPath);
						}
					} else {
						if ([file isMatchedByRegex:filter])
							[self addPathToUploads:fullPath isAutomatic:YES];
					}
				}
			}
		}
	}
}

- (void)removePassword {
	NSArray *items = [MGMKeychain items:MGMKCType withName:MGMKCName service:MGMKCName account:MGMKCName];
	if ([items count]>0)
		[[items objectAtIndex:0] remove];
}
- (void)setPassword:(NSString *)thePassword {
	NSArray *items = [MGMKeychain items:MGMKCType withName:MGMKCName service:MGMKCName account:MGMKCName];
	if ([items count]>0) {
		[[items objectAtIndex:0] setString:thePassword];
	} else {
		[MGMKeychain addItem:MGMKCType withName:MGMKCName service:MGMKCName account:MGMKCName password:thePassword];	
	}
}
- (NSString *)password {
	NSArray *items = [MGMKeychain items:MGMKCType withName:MGMKCName service:MGMKCName account:MGMKCName];
	if ([items count]>0)
		return [[items objectAtIndex:0] string];
	return nil;
}

- (void)processEvent:(int)theEvent path:(NSString *)thePath {
	[self processEvent:theEvent path:thePath url:nil];
}
- (void)processEvent:(int)theEvent path:(NSString *)thePath url:(NSURL *)theURL {
	NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
	[eventInfo setObject:[NSNumber numberWithInt:theEvent] forKey:MGMEvent];
	[eventInfo setObject:thePath forKey:MGMEventPath];
	if (theURL!=nil)
		[eventInfo setObject:theURL forKey:MGMEventURL];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMEventNotification object:self userInfo:eventInfo];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSFileManager *manager = [NSFileManager defaultManager];
	
	NSString *soundPath = [defaults objectForKey:[NSString stringWithFormat:MGMESound, theEvent]];
	if (soundPath!=nil && [manager fileExistsAtPath:soundPath]) {
		NSSound *sound = [[NSSound alloc] initWithContentsOfFile:soundPath byReference:YES];
		[sound setDelegate:self];
		[sound play];
	}
	
	NSString *path = [[defaults objectForKey:[NSString stringWithFormat:MGMEPath, theEvent]]  stringByExpandingTildeInPath];
	if ([manager fileExistsAtPath:path])
		[manager moveItemAtPath:thePath toPath:path];
	
	int deleteFile = [[defaults objectForKey:[NSString stringWithFormat:MGMEDelete, theEvent]] intValue];
	if (deleteFile!=0 && [manager fileExistsAtPath:thePath]) {
		if (deleteFile==1) {
			[manager removeItemAtPath:thePath];
		} else if (deleteFile==2) {
			NSString *trash = [@"~/.Trash" stringByExpandingTildeInPath];
			NSInteger tag;
			[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[thePath stringByDeletingLastPathComponent] destination:trash files:[NSArray arrayWithObject:[thePath lastPathComponent]] tag:&tag];
			if (tag!=0)
				NSLog(@"Error Deleting: %ld", (long)tag);
		}
	}
	
	BOOL growl = [[defaults objectForKey:[NSString stringWithFormat:MGMEGrowl, theEvent]] boolValue];
	if (growl) {
		NSString *title = nil;
		NSString *description = nil;
		NSString *notificationName = nil;
		if (theEvent==MGMEUploading) {
			title = [@"Uploading File" localized];
			description = [NSString stringWithFormat:[@"Uploading %@" localized], [[thePath lastPathComponent] stringByDeletingPathExtension]];
			notificationName = @"UploadingFile";
		} else if (theEvent==MGMEUploadingAutomatic) {
			title = [@"Automatically Uploading File" localized];
			description = [NSString stringWithFormat:[@"Uploading %@" localized], [[thePath lastPathComponent] stringByDeletingPathExtension]];
			notificationName = @"UploadingFileAutomatically";
		} else if (theEvent==MGMEUploaded) {
			title = [@"Uploaded File" localized];
			description = [NSString stringWithFormat:[@"Uploaded %@ to %@" localized], [[thePath lastPathComponent] stringByDeletingPathExtension], theURL];
			notificationName = @"UploadedFile";
		} else if (theEvent==MGMEUploadedAutomatic) {
			title = [@"Automatically Uploaded File" localized];
			description = [NSString stringWithFormat:[@"Uploaded %@ to %@" localized], [[thePath lastPathComponent] stringByDeletingPathExtension], theURL];
			notificationName = @"UploadedFileAutomatically";
		}
		[GrowlApplicationBridge notifyWithTitle:title description:description notificationName:notificationName iconData:[[[NSApplication sharedApplication] applicationIconImage] TIFFRepresentation] priority:0 isSticky:NO clickContext:nil];
	}
}
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying {
	if (finishedPlaying)
		[sound release];
}

- (NSMutableArray *)uploads {
	return uploads;
}
- (NSDictionary *)uploadForPath:(NSString *)thePath {
	for (int i=0; i<[uploads count]; i++) {
		if ([[[uploads objectAtIndex:i] objectForKey:MGMUPath] isEqual:thePath])
			return [uploads objectAtIndex:i];
	}
	return nil;
}
- (void)addPathToUploads:(NSString *)thePath isAutomatic:(BOOL)isAutomatic {
	if ([self uploadForPath:thePath]==nil) {
		if ([currentPlugIn respondsToSelector:@selector(allowedExtensions)]) {
			if (![[currentPlugIn allowedExtensions] containsObject:[[thePath pathExtension] lowercaseString]]) {
				NSAlert *alert = [[NSAlert new] autorelease];
				[alert setMessageText:[@"Upload Error" localized]];
				[alert setInformativeText:[@"The current PlugIn does not support this file format." localized]];
				[alert runModal];
				return;
			}
		}
		[uploads addObject:[NSDictionary dictionaryWithObjectsAndKeys:thePath, MGMUPath, [NSNumber numberWithBool:isAutomatic], MGMUAutomatic, nil]];
		if ([uploads count]==1)
			[self processNextUpload];
	}
}
- (void)processNextUpload {
	if ([uploads count]>0) {
		if (currentPlugIn==nil) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:[@"Upload Error" localized]];
			[alert setInformativeText:[@"No PlugIns found. You must have at least 1 PlugIn to upload a file." localized]];
			[alert runModal];
			[uploads removeAllObjects];
			return;
		} else if (![currentPlugIn respondsToSelector:@selector(sendFileAtPath:withName:)]) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:[@"Upload Error" localized]];
			[alert setInformativeText:[@"The current PlugIn doesn't support uploading." localized]];
			[alert runModal];
			[uploads removeAllObjects];
			return;
		}
		NSFileManager *manager = [NSFileManager defaultManager];
		NSDictionary *upload = [uploads objectAtIndex:0];
		if (![manager fileExistsAtPath:[upload objectForKey:MGMUPath]]) {
			[uploads removeObject:upload];
			[self processNextUpload];
			return;
		}
		[menuItem setImage:[NSImage imageNamed:@"menuiconupload"]];
		[self processEvent:([[upload objectForKey:MGMUAutomatic] boolValue] ? MGMEUploadingAutomatic : MGMEUploading) path:[upload objectForKey:MGMUPath]];
		int uploadNameType = [[[NSUserDefaults standardUserDefaults] objectForKey:MGMUploadName] intValue];
		NSString *randomizedName = [[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] MD5];
		NSString *name = [[upload objectForKey:MGMUPath] lastPathComponent];
		if ((uploadNameType==0 && [[upload objectForKey:MGMUAutomatic] boolValue]) || uploadNameType==1)
			name = [randomizedName stringByAppendingPathExtension:[name pathExtension]];
		[currentPlugIn sendFileAtPath:[upload objectForKey:MGMUPath] withName:name];
	} else {
		[menuItem setImage:[NSImage imageNamed:@"menuicon"]];
	}
}
- (void)upload:(NSString *)thePath receivedError:(NSError *)theError {
	NSDictionary *upload = [self uploadForPath:thePath];
	if (upload!=nil) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMGrowlErrors]) {
			[GrowlApplicationBridge notifyWithTitle:[@"Unable to upload" localized] description:[NSString stringWithFormat:@"%@: %@", [[upload objectForKey:MGMUPath] lastPathComponent], [theError localizedDescription]] notificationName:@"UploadError" iconData:[[[NSApplication sharedApplication] applicationIconImage] TIFFRepresentation] priority:1 isSticky:NO clickContext:nil];
		} else {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:[@"Upload Error" localized]];
			[alert setInformativeText:[NSString stringWithFormat:[@"Unable to upload %@: %@" localized], [[upload objectForKey:MGMUPath] lastPathComponent], [theError localizedDescription]]];
			[alert runModal];
		}
		[uploads removeObject:upload];
		[self processNextUpload];
	}
}
- (void)uploadFinished:(NSString *)thePath url:(NSURL *)theURL {
	NSDictionary *upload = [self uploadForPath:thePath];
	if (upload!=nil) {
		[self processEvent:([[upload objectForKey:MGMUAutomatic] boolValue] ? MGMEUploadedAutomatic : MGMEUploaded) path:[upload objectForKey:MGMUPath] url:theURL];
		NSPasteboard *pboard = [NSPasteboard generalPasteboard];
		[pboard declareTypes:[NSArray arrayWithObjects:MGMNSStringPboardType, MGMNSPasteboardTypeString, nil] owner:nil];
		[pboard setString:[theURL absoluteString] forType:MGMNSStringPboardType];
		[pboard setString:[theURL absoluteString] forType:MGMNSPasteboardTypeString];
		[self addURLToHistory:theURL];
		[uploads removeObject:upload];
		[self processNextUpload];
	}
}
@end