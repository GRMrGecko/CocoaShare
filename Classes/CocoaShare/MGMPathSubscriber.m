//
//  MGMPathSubscriber.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMPathSubscriber.h"

@interface MGMPathSubscriberFile : NSObject {
	NSString *path;
	int fileDescriptor;
	u_int options;
}
- (id)initWithPath:(NSString*)thePath options:(u_int)theOptions;
- (NSString *)path;
- (int)fileDescriptor;
- (u_int)options;
- (BOOL)reopen;
@end

@implementation MGMPathSubscriberFile
- (id)initWithPath:(NSString*)thePath options:(u_int)theOptions {
	if ((self = [super init])) {
		path = [thePath copy];
		options = theOptions;
		fileDescriptor = open([path fileSystemRepresentation], O_EVTONLY, 0);
		if (fileDescriptor<0) {
			[self release];
			self = nil;
		}
	}
	return self;
}
- (void)dealloc {
	[path release];
	if (fileDescriptor>=0)
		close(fileDescriptor);
	[super dealloc];
}
- (NSString *)path {
	return path;
}
- (int)fileDescriptor {
	return fileDescriptor;
}
- (u_int)options {
	return options;
}

- (BOOL)reopen {
	if (fileDescriptor>=0)
		close(fileDescriptor);
	fileDescriptor = open([path fileSystemRepresentation], O_EVTONLY, 0);
	if (fileDescriptor<0)
		return NO;
	return YES;
}
@end

@interface MGMPathSubscriber (MGMPrivate)
- (void)subscriptionChanged:(FNSubscriptionRef)theSubscription;
- (void)subscriptionFSChanged:(ConstFSEventStreamRef)theSubscription;
- (void)subscriptionFileChanged:(MGMPathSubscriberFile *)theFile;
- (void)sendNotificationForPath:(NSString *)thePath;
@end

static MGMPathSubscriber *MGMSharedPathSubscriber;
NSString * const MGMSubscribedPathChangedNotification = @"MGMSubscribedPathChangedNotification";

void MGMPathSubscriptionChange(FNMessage theMessage, OptionBits theFlags, void *thePathSubscription, FNSubscriptionRef theSubscription) {
	if (theMessage==kFNDirectoryModifiedMessage)
		[(MGMPathSubscriber *)thePathSubscription subscriptionChanged:theSubscription];
	else
		NSLog(@"MGMPathSubscription: Received Unknown message: %u", theMessage);
}

void MGMPathSubscriptionFSChange(ConstFSEventStreamRef streamRef, void *thePathSubscription, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
	for (size_t i=0; i<numEvents; i++) {
		if (eventFlags[i] & (0x00000100 /*kFSEventStreamEventFlagItemCreated*/ | 0x00000200 /*kFSEventStreamEventFlagItemRemoved*/ | 0x00000800 /*kFSEventStreamEventFlagItemRenamed*/)) {
			[(MGMPathSubscriber *)thePathSubscription subscriptionFSChanged:streamRef];
			break;
		}
	}
}

@implementation MGMPathSubscriber
+ (id)sharedPathSubscriber {
	if (MGMSharedPathSubscriber==nil)
		MGMSharedPathSubscriber = [MGMPathSubscriber new];
	return MGMSharedPathSubscriber;
}
- (id)init {
	if ((self = [super init])) {
		subscriptions = [NSMutableDictionary new];
		subscriptionUPP = NewFNSubscriptionUPP(MGMPathSubscriptionChange);
		notificationsSending = [NSMutableArray new];
		runLoop = CFRunLoopGetCurrent();
		
		queueDescriptor = kqueue();
		fileWatchLoop = NO;
	}
	return self;
}
- (void)dealloc {
	if (!fileWatchLoop && queueDescriptor>=0)
		close(queueDescriptor);
	fileWatchLoop = NO;
	[self removeAllPaths];
	DisposeFNSubscriptionUPP(subscriptionUPP);
	[subscriptions release];
	[notificationsSending release];
	[super dealloc];
}

- (id<MGMPathSubscriberDelegate>)delegate {
	return delegate;
}
- (void)setDelegate:(id)theDelegate {
	delegate = theDelegate;
}

- (int)OSMajorVersion {
	SInt32 majorVersion;
	if (Gestalt(gestaltSystemVersionMajor, &majorVersion)==noErr) {
		return (int)majorVersion;
	}
	return -1;
}
- (int)OSMinorVersion {
	SInt32 minorVersion;
	if (Gestalt(gestaltSystemVersionMinor, &minorVersion)==noErr) {
		return (int)minorVersion;
	}
	return -1;
}

- (void)addPath:(NSString *)thePath {
	[self addPath:thePath fileOptions:MGMFODelete | MGMFOWrite | MGMFOExtend | MGMFOAttribute | MGMFOLink | MGMFORename | MGMFORevoke];
}
- (void)addPath:(NSString *)thePath fileOptions:(u_int)theOptions {
	NSValue *value = [subscriptions objectForKey:thePath];
	if (value!=nil)
		return;
	
	BOOL directory = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&directory];
	if (!exists) {
		NSLog(@"MGMPathSubscription: Unable to subscribe to %@ as it does not exist", thePath);
		return;
	}
	if (directory) {
		if ([self OSMajorVersion]==10 && [self OSMinorVersion]>=5) {
			FSEventStreamContext context = {0, self, NULL, NULL, NULL};
			FSEventStreamRef stream = FSEventStreamCreate(NULL, &MGMPathSubscriptionFSChange, &context, (CFArrayRef)[NSArray arrayWithObject:thePath], kFSEventStreamEventIdSinceNow, 0.5, kFSEventStreamCreateFlagNone);
			if (stream==NULL) {
				NSLog(@"MGMPathSubscription: Unable to subscribe to %@", thePath);
				return;
			}
			FSEventStreamScheduleWithRunLoop(stream, runLoop, kCFRunLoopDefaultMode);
			FSEventStreamStart(stream);
			[subscriptions setObject:[NSValue valueWithPointer:stream] forKey:thePath];
		} else {
			FNSubscriptionRef subscription = NULL;
			OSStatus error = FNSubscribeByPath((UInt8 *)[thePath fileSystemRepresentation], subscriptionUPP, self, kFNNotifyInBackground, &subscription);
			if (error!=noErr) {
				NSLog(@"MGMPathSubscription: Unable to subscribe to %@ due to the error %ld", thePath, (long)error);
				return;
			}
			[subscriptions setObject:[NSValue valueWithPointer:subscription] forKey:thePath];
		}
	} else {
		MGMPathSubscriberFile *file = [[[MGMPathSubscriberFile alloc] initWithPath:thePath options:theOptions] autorelease];
		
		if (file==nil) {
			NSLog(@"MGMPathSubscription: Unable to subscribe to %@ due to an error", thePath);
			return;
		}
		
		struct timespec nullts = { 0, 0 };
		struct kevent event;
		EV_SET(&event, [file fileDescriptor], EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, theOptions, 0, file);
		
		[subscriptions setObject:file forKey:thePath];
		kevent(queueDescriptor, &event, 1, NULL, 0, &nullts);
		
		if (!fileWatchLoop) {
			fileWatchLoop = YES;
			[NSThread detachNewThreadSelector:@selector(fileWatchThread) toTarget:self withObject:nil];
		}
	}
}
- (void)removePath:(NSString *)thePath {
	NSValue *value = [subscriptions objectForKey:thePath];
	if (value!=nil) {
		if ([value isKindOfClass:[NSValue class]]) {
			if ([self OSMajorVersion]==10 && [self OSMinorVersion]>=5) {
				FSEventStreamRef stream = [value pointerValue];
				FSEventStreamStop(stream);
				FSEventStreamUnscheduleFromRunLoop(stream, runLoop, kCFRunLoopDefaultMode);
				FSEventStreamInvalidate(stream);
				FSEventStreamRelease(stream);
				[subscriptions removeObjectForKey:thePath];
			} else {
				FNUnsubscribe([value pointerValue]);
				[subscriptions removeObjectForKey:thePath];
			}
		} else {
			[subscriptions removeObjectForKey:thePath];
		}
	}
}
- (void)removeAllPaths {
	NSArray *keys = [subscriptions allKeys];
	for (int i=0; i<[keys count]; i++) {
		NSValue *value = [subscriptions objectForKey:[keys objectAtIndex:i]];
		if ([value isKindOfClass:[NSValue class]]) {
			if ([self OSMajorVersion]==10 && [self OSMinorVersion]>=5) {
				FSEventStreamRef stream = [value pointerValue];
				FSEventStreamStop(stream);
				FSEventStreamUnscheduleFromRunLoop(stream, runLoop, kCFRunLoopDefaultMode);
				FSEventStreamInvalidate(stream);
				FSEventStreamRelease(stream);
			} else {
				FNUnsubscribe([value pointerValue]);
			}
		}
	}
	[subscriptions removeAllObjects];
}

- (NSArray *)subscribedPaths {
	return [subscriptions allKeys];
}

- (void)subscriptionChanged:(FNSubscriptionRef)theSubscription {
	NSArray *keys = [subscriptions allKeysForObject:[NSValue valueWithPointer:theSubscription]];
	if ([keys count]>=1) {
		NSString *path = [keys objectAtIndex:0];
		if (![notificationsSending containsObject:path]) {
			[notificationsSending addObject:path];
			[self performSelector:@selector(sendNotificationForPath:) withObject:path afterDelay:0.5];
		}
	}
}
- (void)subscriptionFSChanged:(ConstFSEventStreamRef)theSubscription {
	NSArray *keys = [subscriptions allKeysForObject:[NSValue valueWithPointer:theSubscription]];
	if ([keys count]>=1) {
		NSString *path = [keys objectAtIndex:0];
		if (![notificationsSending containsObject:path]) {
			[notificationsSending addObject:path];
			[self performSelector:@selector(sendNotificationForPath:) withObject:path afterDelay:0.5];
		}
	}
}
- (void)subscriptionFileChanged:(MGMPathSubscriberFile *)theFile {
	NSArray *keys = [subscriptions allKeysForObject:theFile];
	if ([keys count]>=1) {
		NSString *path = [keys objectAtIndex:0];
		if (![notificationsSending containsObject:path]) {
			[notificationsSending addObject:path];
			[self performSelector:@selector(sendNotificationForPath:) withObject:path afterDelay:0.5];
		}
	}
}

- (void)sendNotificationForPath:(NSString *)thePath {
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMSubscribedPathChangedNotification object:thePath];
	if ([delegate respondsToSelector:@selector(subscribedPathChanged:)]) [delegate subscribedPathChanged:thePath];
	[notificationsSending removeObject:thePath];
}

- (void)fileWatchThread {
	int status;
	struct kevent event;
	struct timespec timeout = {1, 0};
	int queueFD = queueDescriptor;
	
	while (fileWatchLoop) {
		@try {
			status = kevent(queueFD, NULL, 0, &event, 1, &timeout);
			if (status>0) {
				MGMPathSubscriberFile *file = [(id)event.udata retain];
				if (event.filter==EVFILT_VNODE && event.fflags && file!=nil) {
					if ((event.fflags & NOTE_RENAME)==NOTE_RENAME) {
						[self performSelectorOnMainThread:@selector(subscriptionFileChanged:) withObject:file waitUntilDone:NO];
					}
					if ((event.fflags & NOTE_WRITE)==NOTE_WRITE) {
						[self performSelectorOnMainThread:@selector(subscriptionFileChanged:) withObject:file waitUntilDone:NO];
					}
					if ((event.fflags & NOTE_DELETE)==NOTE_DELETE) {
						[self performSelectorOnMainThread:@selector(subscriptionFileChanged:) withObject:file waitUntilDone:NO];
						
						if ([file reopen]) {
							struct timespec nullts = { 0, 0 };
							struct kevent event;
							EV_SET(&event, [file fileDescriptor], EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, [file options], 0, file);
							
							kevent(queueDescriptor, &event, 1, NULL, 0, &nullts);
						} else {
							[self removePath:[file path]];
						}
					}
					if ((event.fflags & NOTE_ATTRIB)==NOTE_ATTRIB) {
						[self performSelectorOnMainThread:@selector(subscriptionFileChanged:) withObject:file waitUntilDone:NO];
					}
					if ((event.fflags & NOTE_EXTEND)==NOTE_EXTEND) {
						[self performSelectorOnMainThread:@selector(subscriptionFileChanged:) withObject:file waitUntilDone:NO];
					}
					if ((event.fflags & NOTE_LINK)==NOTE_LINK) {
						[self performSelectorOnMainThread:@selector(subscriptionFileChanged:) withObject:file waitUntilDone:NO];
					}
					if ((event.fflags & NOTE_REVOKE)==NOTE_REVOKE) {
						[self performSelectorOnMainThread:@selector(subscriptionFileChanged:) withObject:file waitUntilDone:NO];
					}
				}
				[file release];
			}
		} @catch (NSException *exception) {
			NSLog(@"MGMPathSubscription: Error in fileWatchThread: %@", exception);
		}
	}
	
	if (close(queueFD)==-1)
		NSLog(@"MGMPathSubscription: fileWatchThread couldn't close queue descriptor %d", errno);
	queueDescriptor = -1;
}
@end