//
//  MGMController.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMController.h"
#import "MGMPathSubscriber.h"
#import "MGMLoginItems.h"
#import "MGMAddons.h"
#import "MGMMenuItem.h"
#import "RegexKitLite.h"
#import <MGMUsers/MGMUsers.h>
#import <GeckoReporter/GeckoReporter.h>
#import <Growl/GrowlApplicationBridge.h>
#import <Carbon/Carbon.h>

NSString * const MGMCopyright = @"Copyright (c) 2015 Mr. Gecko's Media (James Coleman). http://mrgeckosmedia.com/  All rights reserved.";
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
NSString * const MGMHInfo = @"info";
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
NSString * const MGMFID = @"id";
NSString * const MGMFPath = @"path";
NSString * const MGMFFilter = @"filter";

NSString * const MGMResizePlist = @"resize.plist";
NSString * const MGMRID = @"id";
NSString * const MGMRWidth = @"width";
NSString * const MGMRHeight = @"height";
NSString * const MGMRScale = @"scale";
NSString * const MGMRFilters = @"filters";
NSString * const MGMRNetworks = @"networks";
NSString * const MGMRIPPrefix = @"IPPrefix";

NSString * const MGMPluginFolder = @"PlugIns";
NSString * const MGMCurrentPlugIn = @"MGMCurrentPlugIn";

NSString * const MGMMUThemesFolder = @"Multi Upload Themes";
NSString * const MGMCurrentMUTheme = @"MGMCurrentMUTheme";

NSString * const MGMKCType = @"application password";
NSString * const MGMKCName = @"CocoaShare";

NSString * const MGMUPath = @"path";
NSString * const MGMUAutomatic = @"automatic";
NSString * const MGMUMultiUpload = @"multiUpload";
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

NSString * const MGMPrimaryInterface = @"PrimaryInterface";
NSString * const MGMAddresses = @"Addresses";

NSString * const MGMIPv4Info = @"State:/Network/Interface/%@/IPv4";
NSString * const MGMIPv6Info = @"State:/Network/Interface/%@/IPv6";
NSString * const MGMIPv4State = @"State:/Network/Global/IPv4";
NSString * const MGMIPv6State = @"State:/Network/Global/IPv6";
NSString * const MGMAirPortInfo = @"State:/Network/Interface/%@/AirPort";

static void systemNotification(SCDynamicStoreRef store, NSArray *changedKeys, void *info) {
	for (int i=0; i<[changedKeys count]; ++i) {
		NSString *key = [changedKeys objectAtIndex:i];
		if ([key isEqual:MGMIPv4State]) {
			NSDictionary *value = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)key);
			[(MGMController *)info ipv4Changed:value];
			[value release];
		} else if ([key isEqual:MGMIPv6State]) {
			NSDictionary *value = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)key);
			[(MGMController *)info ipv6Changed:value];
			[value release];
		} else if ([key hasSuffix:@"AirPort"]) {
			NSDictionary *value = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)key);
			[(MGMController *)info airportChanged:value];
			[value release];
		}
	}
}

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
	autoreleaseDrain = [[NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(drainAutoreleasePool) userInfo:nil repeats:YES] retain];
	
	[GrowlApplicationBridge setGrowlDelegate:nil];
	
	NSString *AirPortBSDName = nil;
	CFArrayRef interfaces = SCNetworkInterfaceCopyAll();
	for (int i=0; i<CFArrayGetCount(interfaces); i++) {
		SCNetworkInterfaceRef interface = CFArrayGetValueAtIndex(interfaces, i);
		if ([(NSString *)SCNetworkInterfaceGetInterfaceType(interface) isEqual:@"IEEE80211"]) {
			AirPortBSDName = (NSString *)SCNetworkInterfaceGetBSDName(interface);
		}
	}
	CFRelease(interfaces);
	
	SCDynamicStoreContext context = {0, self, NULL, NULL, NULL};
	store = SCDynamicStoreCreate(kCFAllocatorDefault, CFBundleGetIdentifier(CFBundleGetMainBundle()), (SCDynamicStoreCallBack)systemNotification, &context);
	if (!store) {
		NSLog(@"Unable to create store for system configuration %s", SCErrorString(SCError()));
	} else {
		NSMutableArray *keys = [NSMutableArray arrayWithObjects:MGMIPv4State, MGMIPv6State, nil];
		if (AirPortBSDName!=nil) {
			[keys addObject:[NSString stringWithFormat:MGMAirPortInfo, AirPortBSDName]];
		}
		if (!SCDynamicStoreSetNotificationKeys(store, (CFArrayRef)keys, NULL)) {
			NSLog(@"faild to set the store for notifications %s", SCErrorString(SCError()));
			CFRelease(store);
			store = NULL;
		} else {
			runLoop = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, store, 0);
			CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
			
			
			NSDictionary *IPv4State = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)MGMIPv4State);
			NSDictionary *IPv4Info = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)[NSString stringWithFormat:MGMIPv4Info, [IPv4State objectForKey:MGMPrimaryInterface]]);
			IPv4Addresses = [[IPv4Info objectForKey:MGMAddresses] retain];
			[IPv4Info release];
			[IPv4State release];
			
			NSDictionary *IPv6State = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)MGMIPv6State);
			NSDictionary *IPv6Info = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)[NSString stringWithFormat:MGMIPv6Info, [IPv6State objectForKey:MGMPrimaryInterface]]);
			IPv6Addresses = [[IPv6Info objectForKey:MGMAddresses] retain];
			[IPv6Info release];
			[IPv6State release];
			
			if (AirPortBSDName!=nil) {
				lastAirPortState = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)[NSString stringWithFormat:MGMAirPortInfo, AirPortBSDName]);
			}
		}
	}
	
	
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
		[[MGMLoginItems items] addThisApplication];
	
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
	
	if ([manager fileExistsAtPath:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMResizePlist]]) {
		NSData *plistData = [NSData dataWithContentsOfFile:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMResizePlist]];
		NSString *error = nil;
		resizeLogic = [[NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListMutableContainersAndLeaves format:NULL errorDescription:&error] retain];
		if (error!=nil) {
			NSLog(@"Error processing resize.plist: %@", error);
		}
	} else {
		resizeLogic = [NSMutableArray new];
		[self saveResizeLogic];
	}
	
	if ([defaults integerForKey:MGMDisplay]>0)
		[self addMenu];
	
	preferences = [MGMPreferences new];
    [preferences addPreferencesPaneClassName:@"MGMGeneralPane"];
    [preferences addPreferencesPaneClassName:@"MGMAccountPane"];
	[preferences addPreferencesPaneClassName:@"MGMAutoUploadPane"];
	[preferences addPreferencesPaneClassName:@"MGMResizePane"];
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
	
	if ([defaults objectForKey:MGMVersion]==nil || [[defaults objectForKey:MGMVersion] doubleValue]<=0.3) {
		for (int i=0; i<[filters count]; i++) {
			if ([[filters objectAtIndex:i] objectForKey:MGMFID]==nil) {
				CFUUIDRef uuid = CFUUIDCreate(NULL);
				NSString *uuidString = [(NSString *)CFUUIDCreateString(NULL, uuid) autorelease];
				CFRelease(uuid);
				NSDictionary *filter = [[filters objectAtIndex:i] mutableCopy];
				[filter setValue:uuidString forKey:MGMFID];
				[filters replaceObjectAtIndex:i withObject:filter];
				[filter release];
			}
		}
		[self saveFilters];
	}
	[defaults setObject:[[MGMSystemInfo info] applicationVersion] forKey:MGMVersion];
	
	[self loadMUThemes];
	[self loadPlugIns];
}
- (void)dealloc {
	[autoreleaseDrain invalidate];
	[autoreleaseDrain release];
	if (store!=NULL) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
		CFRelease(store);
	}
	[IPv4Addresses release];
	[IPv6Addresses release];
	[lastAirPortState release];
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
	[defaults setObject:[NSNumber numberWithInt:1] forKey:MGMLaunchCount];
	
	[defaults setObject:[NSNumber numberWithInt:([[MGMSystemInfo info] isUIElement] ? 2 : 0)] forKey:MGMDisplay];
	[defaults setObject:[NSNumber numberWithBool:[[MGMLoginItems items] thisApplicationExists]] forKey:MGMStartup];
	[defaults setObject:[NSNumber numberWithInt:0] forKey:MGMUploadName];
	[defaults setObject:[NSNumber numberWithInt:5] forKey:MGMHistoryCount];
	[defaults setObject:[NSNumber numberWithInt:5] forKey:MGMUploadLimit];
	
	[defaults setObject:[NSNumber numberWithInt:2] forKey:[NSString stringWithFormat:MGMEDelete, MGMEUploadedAutomatic]];
	
	[defaults setObject:[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:MGMMUThemesFolder] stringByAppendingPathComponent:@"White Background"] forKey:MGMCurrentMUTheme];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)drainAutoreleasePool {
	NSEvent *event = [NSEvent otherEventWithType:NSApplicationDefined location:NSMakePoint(0, 0) modifierFlags:0 timestamp:CFAbsoluteTimeGetCurrent() windowNumber:0 context:nil subtype:0 data1:0 data2:0];
	[[NSApplication sharedApplication] postEvent:event atStart:NO];
}


- (void)ipv4Changed:(NSDictionary *)theInfo {
	NSDictionary *info = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)[NSString stringWithFormat:MGMIPv4Info, [theInfo objectForKey:MGMPrimaryInterface]]);
	[IPv4Addresses autorelease];
	IPv4Addresses = [[info objectForKey:MGMAddresses] retain];
	[info release];
}
- (void)ipv6Changed:(NSDictionary *)theInfo {
	NSDictionary *info = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)[NSString stringWithFormat:MGMIPv6Info, [theInfo objectForKey:MGMPrimaryInterface]]);
	[IPv6Addresses autorelease];
	IPv6Addresses = [[info objectForKey:MGMAddresses] retain];
	[info release];
}

- (void)airportChanged:(NSDictionary *)theInfo {
	[lastAirPortState autorelease];
	lastAirPortState = [theInfo retain];
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


- (void)loadMUThemes {
	NSFileManager *manager = [NSFileManager defaultManager];
	[MUThemes release];
	MUThemes = [NSMutableArray new];
	
	NSArray *checkPaths = [NSArray arrayWithObjects:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:MGMMUThemesFolder], [[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMMUThemesFolder], nil];
	for (int i=0; i<[checkPaths count]; i++) {
		NSArray *MUThemesFolder = [manager contentsOfDirectoryAtPath:[checkPaths objectAtIndex:i]];
		for (int p=0; p<[MUThemesFolder count]; p++) {
			NSString *path = [[[checkPaths objectAtIndex:i] stringByAppendingPathComponent:[MUThemesFolder objectAtIndex:p]] stringByResolvingSymlinksInPath];
			[MUThemes addObject:path];
		}
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *currentMUThemePath = [defaults objectForKey:MGMCurrentMUTheme];
	BOOL foundCurrentMUTheme = NO;
	for (int i=0; i<[MUThemes count]; i++) {
		if ([[MUThemes objectAtIndex:i] isEqual:currentMUThemePath]) {
			currentMUThemeIndex = i;
			foundCurrentMUTheme = YES;
			break;
		}
	}
	if (!foundCurrentMUTheme && [MUThemes count]>0)
		[self setCurrentMUTheme:[MUThemes objectAtIndex:0]];
}
- (NSArray *)MUThemes {
	return MUThemes;
}
- (void)setCurrentMUTheme:(NSString *)theMUTheme {
	int MUThemeIndex = [MUThemes indexOfObject:theMUTheme];
	if (MUThemeIndex>=0) {
		currentMUThemeIndex = MUThemeIndex;
		[[NSUserDefaults standardUserDefaults] setObject:theMUTheme forKey:MGMCurrentMUTheme];
	}
}
- (int)currentMUThemeIndex {
	return currentMUThemeIndex;
}
- (NSString *)currentMUTheme {
	return [MUThemes objectAtIndex:currentMUThemeIndex];
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
        NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
        if ([osxMode isEqualTo:@"Dark"]) {
            [menuItem setImage:[NSImage imageNamed:@"menuiconselected"]];
            [menuItem setAlternateImage:[NSImage imageNamed:@"menuicon"]];
        } else {
            [menuItem setImage:[NSImage imageNamed:@"menuicon"]];
            [menuItem setAlternateImage:[NSImage imageNamed:@"menuiconselected"]];
        }
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
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([osxMode isEqualTo:@"Dark"]) {
        [menuItem setImage:[NSImage imageNamed:@"menuiconselected"]];
    } else {
        [menuItem setImage:[NSImage imageNamed:@"menuicon"]];
    }
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
			[self addPathToUploads:[files objectAtIndex:i] automaticFilter:nil multiUpload:([files count]==1 ? 0 : (i==0 ? 1 : (i==[files count]-1 ? 3 : 2)))];
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
- (void)uploadFinished:(NSString *)thePath url:(NSURL *)theURL info:(id)theInfo {
	[history addObject:[NSDictionary dictionaryWithObjectsAndKeys:[theURL absoluteString], MGMHURL, theInfo, MGMHInfo, [NSDate date], MGMHDate, nil]];
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
			[self addPathToUploads:[[[panel URLs] objectAtIndex:i] path] automaticFilter:nil  multiUpload:([[panel URLs] count]==1 ? 0 : (i==0 ? 1 : (i==[[panel URLs] count]-1 ? 3 : 2)))];
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
		[self addPathToUploads:[theFiles objectAtIndex:i] automaticFilter:nil  multiUpload:([theFiles count]==1 ? 0 : (i==0 ? 1 : (i==[theFiles count]-1 ? 3 : 2)))];
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
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://mrgeckosmedia.com/donate?purpose=cocoashare"]];
}
- (IBAction)quit:(id)sender {
	[[MGMLoginItems items] removeThisApplication];
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
	NSLog(@"Changed: %@", thePath);
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
								if ([[items objectAtIndex:m] isMatchedByRegex:filter]) {
									[self addPathToUploads:fullPath automaticFilter:[[filtersFound objectAtIndex:f] objectForKey:MGMFID]];
								} else if ([item isKindOfClass:[NSString class]] && [item isMatchedByRegex:filter]) {
									[self addPathToUploads:fullPath automaticFilter:[[filtersFound objectAtIndex:f] objectForKey:MGMFID]];
								}
								if (item!=nil)
									CFRelease((CFTypeRef)item);
							}
							if (items!=nil)
								CFRelease((CFArrayRef)items);
							CFRelease(metadata);
						} else {
							NSLog(@"Unable to get metadata of %@", fullPath);
						}
						
						NSDictionary *extendedAttributes = nil;
						if ([manager respondsToSelector:@selector(attributesOfItemAtPath:error:)]) {
							extendedAttributes = [[manager attributesOfItemAtPath:fullPath error:nil] objectForKey:@"NSFileExtendedAttributes"];
						} else {
							extendedAttributes = [[manager fileSystemAttributesAtPath:fullPath] objectForKey:@"NSFileExtendedAttributes"];
						}
						for (int a=0; a<[[extendedAttributes allKeys] count]; a++) {
							if ([[[extendedAttributes allKeys] objectAtIndex:a] isMatchedByRegex:filter]) {
								[self addPathToUploads:fullPath automaticFilter:[[filtersFound objectAtIndex:f] objectForKey:MGMFID]];
							} else if ([[extendedAttributes objectForKey:[[extendedAttributes allKeys] objectAtIndex:a]] isKindOfClass:[NSString class]] && [[extendedAttributes objectForKey:[[extendedAttributes allKeys] objectAtIndex:a]] isMatchedByRegex:filter]) {
								[self addPathToUploads:fullPath automaticFilter:[[filtersFound objectAtIndex:f] objectForKey:MGMFID]];
							}
						}
					} else {
						if ([file isMatchedByRegex:filter]) {
							[self addPathToUploads:fullPath automaticFilter:[[filtersFound objectAtIndex:f] objectForKey:MGMFID]];
						}
					}
				}
			}
		}
	}
}

- (NSMutableArray *)resizeLogic {
	return resizeLogic;
}
- (void)resizeIfNeeded:(NSString *)thePath {
	[self resizeIfNeeded:thePath filterID:nil];
}
- (void)resizeIfNeeded:(NSString *)thePath filterID:(NSString *)theID {
	NSArray *extensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"png", @"tif", @"tiff", @"bmp", nil];
	if (![extensions containsObject:[[thePath pathExtension] lowercaseString]])
		return;
	NSDictionary *lastMatch = nil;
	BOOL matchedOnFilter = NO;
	BOOL matchedOnNetwork = NO;
	BOOL matchedOnPrefix = NO;
	for (int i=0; i<[resizeLogic count]; i++) {
		NSDictionary *logic = [resizeLogic objectAtIndex:i];
		BOOL prefixMatch = NO;
		if (![[logic objectForKey:MGMRIPPrefix] isEqual:@""]) {
			NSString *prefix = [logic objectForKey:MGMRIPPrefix];
			for (int ip=0; ip<[IPv4Addresses count]; ip++) {
				if ([[IPv4Addresses objectAtIndex:ip] hasPrefix:prefix]) {
					prefixMatch = YES;
				}
			}
			for (int ip=0; ip<[IPv6Addresses count]; ip++) {
				if ([[IPv6Addresses objectAtIndex:ip] hasPrefix:prefix]) {
					prefixMatch = YES;
				}
			}
		}
		BOOL networkMatch = (lastAirPortState!=nil && [lastAirPortState objectForKey:@"SSID"]!=nil && [[logic objectForKey:MGMRNetworks] containsObject:[[[NSString alloc] initWithData:[lastAirPortState objectForKey:@"SSID"] encoding:NSUTF8StringEncoding] autorelease]]);
		BOOL filterMatch = (theID!=nil && [[logic objectForKey:MGMRFilters] containsObject:theID]);
		NSLog(@"%d %d %d", prefixMatch, networkMatch, filterMatch);
		if ([[logic objectForKey:MGMRFilters] count]==0 && (networkMatch || prefixMatch)) {//No filters and network or prefix match.
			if (lastMatch!=nil && matchedOnFilter) {//If this is a network match and previous was a filter match, do not match.
				continue;
			}
			if (lastMatch!=nil && matchedOnNetwork && !networkMatch) {//If this isn't a network match, yet the previous was, do not match.
				continue;
			}
		} else if ([[logic objectForKey:MGMRFilters] count]==0) {//No filters and not network or prefix.
			if (lastMatch!=nil && (matchedOnNetwork || matchedOnPrefix || matchedOnFilter)) {//If previous matches on network, prefix, or filter, do not match.
				continue;
			}
		} else if ([[logic objectForKey:MGMRFilters] count]!=0 && !filterMatch) {//Cannot match if filteres exist, but not matched.
			continue;
		} else if (filterMatch) {//If filtere match.
			if (networkMatch || prefixMatch) {//Network or prefix match.
				if (lastMatch!=nil && matchedOnFilter && matchedOnNetwork && !networkMatch) {//Previous matched on network and this isn't a network match, do not match.
					continue;
				}
			} else {//Not network or prefix match.
				if (lastMatch!=nil && matchedOnFilter && (matchedOnNetwork || matchedOnFilter)) {//If was a network match, do not match.
					continue;
				}
			}
		}
		if (([[logic objectForKey:MGMRWidth] intValue]==0 || [[logic objectForKey:MGMRHeight] intValue]==0) && [[logic objectForKey:MGMRScale] intValue]==0) {//Incorrect resize logic.
			continue;
		}
		lastMatch = logic;
		matchedOnFilter = filterMatch;
		matchedOnNetwork = networkMatch;
		matchedOnPrefix = prefixMatch;
	}
	
	if (lastMatch!=nil) {
		int scale = [[lastMatch objectForKey:MGMRScale] intValue];
		if (scale!=0) {
			[self resize:thePath toSize:NSZeroSize scale:1-(((float)scale)/100)];
		} else {
			[self resize:thePath toSize:NSMakeSize([[lastMatch objectForKey:MGMRWidth] floatValue], [[lastMatch objectForKey:MGMRHeight] floatValue]) scale:0.0];
		}
	}
}
- (void)resize:(NSString *)thePath toSize:(NSSize)theSize scale:(float)theScale {
	NSString *extension = [[thePath pathExtension] lowercaseString];
	CFStringRef type = kUTTypeImage;
	if ([extension isEqual:@"jpg"] || [extension isEqual:@"jpeg"]) {
		type = kUTTypeJPEG;
	} else if ([extension isEqual:@"png"]) {
		type = kUTTypePNG;
	} else if ([extension isEqual:@"bmp"]) {
		type = kUTTypeBMP;
	} else if ([extension isEqual:@"tif"] || [extension isEqual:@"tiff"]) {
		type = kUTTypeTIFF;
	} else {
		return;
	}
	
	CFURLRef fileURL = (__bridge CFURLRef)[NSURL fileURLWithPath:[thePath stringByExpandingTildeInPath]];
	CGImageSourceRef source = CGImageSourceCreateWithURL(fileURL, NULL);
	if (source==NULL) {
		NSLog(@"Unable to create image source: %@", thePath);
		return;
	}
	CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	CFRelease(source);
	if (imageRef==NULL) {
		NSLog(@"Unable to create image: %@", thePath);
		return;
	}
	NSSize size = NSMakeSize(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
	
	float scaleFactor = 0.0;
	float scaledWidth = 0.0;
	float scaledHeight = 0.0;
	if (NSEqualSizes(theSize, NSZeroSize)) {
		scaleFactor = theScale;
	} else {
		float widthFactor = theSize.width / size.width;
		float heightFactor = theSize.height / size.height;
		
		if (widthFactor < heightFactor)
			scaleFactor = widthFactor;
		else
			scaleFactor = heightFactor;
	}
	scaledWidth = size.width * scaleFactor;
	scaledHeight = size.height * scaleFactor;
	if (size.width<=scaledWidth && size.height<=scaledHeight) {
		CGImageRelease(imageRef);
		return;//Output larger or equal to input.
	}
	NSLog(@"Resizing: %@", thePath);
	NSLog(@"Width: %f Height: %f", size.width, size.height);
	NSLog(@"Width: %f Height: %f", scaledWidth, scaledHeight);
	
	NSSize newSize = NSMakeSize(scaledWidth, scaledHeight);
	if (!NSEqualSizes(newSize, NSZeroSize)) {
		CGContextRef bitmap = CGBitmapContextCreate(NULL, newSize.width, newSize.height, CGImageGetBitsPerComponent(imageRef), 0, CGImageGetColorSpace(imageRef), (CGBitmapInfo)((type==kUTTypePNG || type==kUTTypeTIFF) ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNoneSkipLast));
		CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
		CGContextDrawImage(bitmap, NSMakeRect(0, 0, newSize.width, newSize.height), imageRef);
		CGImageRef newImage = CGBitmapContextCreateImage(bitmap);
		CGContextRelease(bitmap);
		
		
		CGImageDestinationRef destination = CGImageDestinationCreateWithURL(fileURL, type, 1, NULL);
		if (!destination) {
			NSLog(@"Failed to create CGImageDestination for %@", thePath);
			CGImageRelease(newImage);
			CGImageRelease(imageRef);
			return;
		}
		
		CGImageDestinationAddImage(destination, newImage, nil);
		if (!CGImageDestinationFinalize(destination)) {
			NSLog(@"Failed to write image to %@", thePath);
		}
		
		CFRelease(destination);
		CGImageRelease(newImage);
	}
	CGImageRelease(imageRef);
}
- (void)saveResizeLogic {
	if (saveCount==2)
		return;
	saveCount++;
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[saveLock lock];
	[resizeLogic writeToFile:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMResizePlist] atomically:YES];
	saveCount--;
	[pool drain];
	[saveLock unlock];
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

- (void)addPathToUploads:(NSString *)thePath automaticFilter:(NSString *)theFilter {
	[self addPathToUploads:thePath automaticFilter:theFilter multiUpload:0];
}

/*
 0 - Not a upload queue with multiple uploads.
 1 - First upload in the queue.
 2 - An upload in the queue.
 3 - Last upload in the queue.
 4 - The multi upload page.
 */
- (void)addPathToUploads:(NSString *)thePath automaticFilter:(NSString *)theFilter multiUpload:(int)multiUploadState {
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
		[self resizeIfNeeded:thePath filterID:theFilter];
		
		[uploads addObject:[NSDictionary dictionaryWithObjectsAndKeys:thePath, MGMUPath, [NSNumber numberWithBool:(theFilter!=nil)], MGMUAutomatic, [NSNumber numberWithInt:multiUploadState], MGMUMultiUpload, nil]];
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
		} else if (![currentPlugIn respondsToSelector:@selector(sendFileAtPath:withName:)] && ![currentPlugIn respondsToSelector:@selector(sendFileAtPath:withName:multiUpload:)]) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:[@"Upload Error" localized]];
			[alert setInformativeText:[@"The current PlugIn doesn't support uploading." localized]];
			[alert runModal];
			[uploads removeAllObjects];
			return;
		}
		NSFileManager *manager = [NSFileManager defaultManager];
		NSDictionary *upload = [uploads objectAtIndex:0];
		int multiUpload = [[upload objectForKey:MGMUMultiUpload] intValue];
		if (multiUpload==1) {
			[multiUploadLinks release];
			multiUploadLinks = [NSMutableArray new];
		}
		
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
		if ([currentPlugIn respondsToSelector:@selector(sendFileAtPath:withName:multiUpload:)]) {
			[currentPlugIn sendFileAtPath:[upload objectForKey:MGMUPath] withName:name multiUpload:multiUpload];
		} else {
			[currentPlugIn sendFileAtPath:[upload objectForKey:MGMUPath] withName:name];
		}
	} else {
        NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
        if ([osxMode isEqualTo:@"Dark"]) {
            [menuItem setImage:[NSImage imageNamed:@"menuiconselected"]];
        } else {
            [menuItem setImage:[NSImage imageNamed:@"menuicon"]];
        }
	}
}
- (void)upload:(NSString *)thePath receivedError:(NSError *)theError {
	NSDictionary *upload = [self uploadForPath:thePath];
	if (upload!=nil) {
		NSLog(@"Error: %@", theError);
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
		int multiUpload = [[upload objectForKey:MGMUMultiUpload] intValue];
		[self processEvent:([[upload objectForKey:MGMUAutomatic] boolValue] ? MGMEUploadedAutomatic : MGMEUploaded) path:[upload objectForKey:MGMUPath] url:theURL];
		//No need to bother the clip board when there will end up being a multi upload url.
		if (multiUpload==0 || multiUpload==4) {
			NSPasteboard *pboard = [NSPasteboard generalPasteboard];
			[pboard declareTypes:[NSArray arrayWithObjects:MGMNSStringPboardType, MGMNSPasteboardTypeString, nil] owner:nil];
			[pboard setString:[theURL absoluteString] forType:MGMNSStringPboardType];
			[pboard setString:[theURL absoluteString] forType:MGMNSPasteboardTypeString];
		}
		[self addURLToHistory:theURL];
		
		if (multiUpload>=1 && multiUpload!=4) {
			[multiUploadLinks addObject:theURL];
		}
		if (multiUpload==3) {
			if ([currentPlugIn respondsToSelector:@selector(createMultiUploadPage)]) {
				[currentPlugIn createMultiUploadPage];
			} else {
				NSString *randomizedName = [[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] MD5];
				NSString *htmlPath = [NSString stringWithFormat:@"/tmp/CocoaShare_%@.htm", randomizedName];
				
				NSString *imageHTML = [NSString stringWithContentsOfFile:[[self currentMUTheme] stringByAppendingPathComponent:@"image.html"] encoding:NSUTF8StringEncoding error:nil];
				if (imageHTML==nil) {
					[uploads removeObject:upload];
					[self processNextUpload];
					return;
				}
				NSString *fileHTML = [NSString stringWithContentsOfFile:[[self currentMUTheme] stringByAppendingPathComponent:@"file.html"] encoding:NSUTF8StringEncoding error:nil];
				
				[[NSFileManager defaultManager] createFileAtPath:htmlPath contents:nil attributes:nil];
				NSFileHandle *multiUploadHtml = [NSFileHandle fileHandleForWritingAtPath:htmlPath];
				[multiUploadHtml writeData:[NSData dataWithContentsOfFile:[[self currentMUTheme] stringByAppendingPathComponent:@"header.html"]]];
				NSArray *imageExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"png", @"bmp", @"gif", nil];
				for (int i=0; i<[multiUploadLinks count]; i++) {
					NSURL *link = [multiUploadLinks objectAtIndex:i];
					NSString *linkString = [link absoluteString];
					if ([imageExtensions containsObject:[[link pathExtension] lowercaseString]]) {
						[multiUploadHtml writeData:[[imageHTML replace:@"{url}" with:linkString] dataUsingEncoding:NSUTF8StringEncoding]];
					} else {
						[multiUploadHtml writeData:[[fileHTML replace:@"{url}" with:linkString] dataUsingEncoding:NSUTF8StringEncoding]];
					}
				}
				[multiUploadHtml writeData:[NSData dataWithContentsOfFile:[[self currentMUTheme] stringByAppendingPathComponent:@"footer.html"]]];
				[multiUploadHtml closeFile];
				[self addPathToUploads:htmlPath automaticFilter:nil multiUpload:4];
			}
		}
		if (multiUpload==4) {
			[[NSFileManager defaultManager] removeItemAtPath:[upload objectForKey:MGMUPath]];
		}
		
		[uploads removeObject:upload];
		[self processNextUpload];
	}
}
- (void)multiUploadPageCreated:(NSURL *)theURL {
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	[pboard declareTypes:[NSArray arrayWithObjects:MGMNSStringPboardType, MGMNSPasteboardTypeString, nil] owner:nil];
	[pboard setString:[theURL absoluteString] forType:MGMNSStringPboardType];
	[pboard setString:[theURL absoluteString] forType:MGMNSPasteboardTypeString];
	[self addURLToHistory:theURL];
}
@end