//
//  CocoaShareAppDelegate.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>
#import "MGMPlugInProtocol.h"
#import "MGMLocalized.h"
#import <SystemConfiguration/SystemConfiguration.h>

extern NSString * const MGMDisplay;
extern NSString * const MGMStartup;
extern NSString * const MGMUploadName;
extern NSString * const MGMHistoryCount;
extern NSString * const MGMGrowlErrors;
extern NSString * const MGMUploadLimit;

extern NSString * const MGMHURL;
extern NSString * const MGMHInfo;
extern NSString * const MGMHDate;

extern NSString * const MGMESound;
extern NSString * const MGMEPath;
extern NSString * const MGMEDelete;
extern NSString * const MGMEGrowl;
extern const int MGMEUploadingAutomatic;
extern const int MGMEUploadedAutomatic;
extern const int MGMEUploading;
extern const int MGMEUploaded;
extern NSString * const MGMEventNotification;
extern NSString * const MGMEvent;
extern NSString * const MGMEventPath;
extern NSString * const MGMEventURL;

extern NSString * const MGMFID;
extern NSString * const MGMFPath;
extern NSString * const MGMFFilter;

extern NSString * const MGMRID;
extern NSString * const MGMRWidth;
extern NSString * const MGMRHeight;
extern NSString * const MGMRScale;
extern NSString * const MGMRFilters;
extern NSString * const MGMRNetworks;
extern NSString * const MGMRIPPrefix;

@class MGMURLConnectionManager, MGMPreferences, MGMAbout, MGMMenuItem, MGMPathSubscriber;

@interface MGMController : NSObject
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
<NSSoundDelegate>
#endif
{
	NSTimer *autoreleaseDrain;
	
	CFRunLoopSourceRef runLoop;
	SCDynamicStoreRef store;
	NSDictionary *lastAirPortState;
	NSArray *IPv4Addresses;
	NSArray *IPv6Addresses;
	
	MGMURLConnectionManager *connectionManager;
	MGMPreferences *preferences;
	MGMAbout *about;
	
	ProcessSerialNumber frontProcess;
	unsigned int windowCount;
	
	IBOutlet NSMenu *mainMenu;
	IBOutlet NSMenuItem *disableFilters;
	MGMMenuItem *menuItem;
	NSStatusItem *statusItem;
	NSMutableArray *history;
	
	NSMutableArray *filters;
	NSLock *saveLock;
	int saveCount;
	MGMPathSubscriber *filterWatcher;
	BOOL filtersEnabled;
	
	NSMutableArray *resizeLogic;
	
	NSMutableArray *accountPlugIns;
	NSMutableArray *plugIns;
	id<MGMPlugInProtocol> currentPlugIn;
	int currentPlugInIndex;
	
	NSMutableArray *MUThemes;
	int currentMUThemeIndex;
	
	NSMutableArray *multiUploadLinks;
	NSMutableArray *uploads;
}
+ (id)sharedController;

- (void)registerDefaults;

- (void)ipv4Changed:(NSDictionary *)theInfo;
- (void)ipv6Changed:(NSDictionary *)theInfo;

- (void)airportChanged:(NSDictionary *)theInfo;

- (MGMURLConnectionManager *)connectionManager;
- (MGMPreferences *)preferences;

- (void)loadPlugIns;
- (NSArray *)accountPlugIns;
- (NSArray *)plugIns;
- (void)setCurrentPlugIn:(id)thePlugIn;
- (id<MGMPlugInProtocol>)currentPlugIn;
- (int)currentPlugInIndex;

- (void)loadMUThemes;
- (NSArray *)MUThemes;
- (void)setCurrentMUTheme:(NSString *)theMUTheme;
- (int)currentMUThemeIndex;
- (NSString *)currentMUTheme;

- (void)setFrontProcess:(ProcessSerialNumber *)theProcess;
- (void)becomeFront:(NSWindow *)theWindow;
- (void)resignFront;

- (void)addMenu;
- (void)removeMenu;
- (void)setDockHidden:(BOOL)isHidden;

- (NSMutableArray *)history;
- (void)updateMenu;
- (void)addURLToHistory:(NSURL *)theURL;

- (IBAction)uploadFile:(id)sender;

- (IBAction)disableFilters:(id)sender;
- (IBAction)about:(id)sender;
- (IBAction)preferences:(id)sender;
- (IBAction)donate:(id)sender;
- (IBAction)quit:(id)sender;

- (NSMutableArray *)filters;
- (void)saveFilters;
- (MGMPathSubscriber *)filterWatcher;
- (NSArray *)filtersForPath:(NSString *)thePath;
- (void)updateFilterWatcher;
- (void)subscribedPathChanged:(NSString *)thePath;

- (NSMutableArray *)resizeLogic;
- (void)resizeIfNeeded:(NSString *)thePath;
- (void)resizeIfNeeded:(NSString *)thePath filterID:(NSString *)theID;
- (void)resize:(NSString *)thePath toSize:(NSSize)theSize scale:(float)theScale;
- (void)saveResizeLogic;

- (void)removePassword;
- (void)setPassword:(NSString *)thePassword;
- (NSString *)password;

- (void)processEvent:(int)theEvent path:(NSString *)thePath;
- (void)processEvent:(int)theEvent path:(NSString *)thePath url:(NSURL *)theURL;

- (NSMutableArray *)uploads;
- (NSDictionary *)uploadForPath:(NSString *)thePath;
- (void)addPathToUploads:(NSString *)thePath automaticFilter:(NSString *)theFilter;
- (void)addPathToUploads:(NSString *)thePath automaticFilter:(NSString *)theFilter multiUpload:(int)multiUploadState;
- (void)processNextUpload;
- (void)upload:(NSString *)thePath receivedError:(NSError *)theError;
- (void)uploadFinished:(NSString *)thePath url:(NSURL *)theURL;
- (void)uploadFinished:(NSString *)thePath url:(NSURL *)theURL info:(id)theInfo;
- (void)multiUploadPageCreated:(NSURL *)theURL;
@end