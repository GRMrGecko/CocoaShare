//
//  MGMPathSubscriber.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMPathSubscriber.h"

@interface MGMPathSubscriber (MGMPrivate)
- (void)subscriptionChanged:(FNSubscriptionRef)theSubscription;
- (void)subscriptionFSChanged:(ConstFSEventStreamRef)theSubscription;
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
		if (eventFlags[i] & (kFSEventStreamEventFlagItemCreated | kFSEventStreamEventFlagItemRemoved | kFSEventStreamEventFlagItemRenamed)) {
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
	}
	return self;
}
- (void)dealloc {
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
	NSValue *value = [subscriptions objectForKey:thePath];
	if (value!=nil)
		return;
	FSEventStreamContext context = {0, self, NULL, NULL, NULL};
	if ([self OSMajorVersion]==10 && [self OSMinorVersion]>=5) {
		FSEventStreamRef stream = FSEventStreamCreate(NULL, &MGMPathSubscriptionFSChange, &context, (CFArrayRef)[NSArray arrayWithObject:thePath], kFSEventStreamEventIdSinceNow, 0.5, kFSEventStreamCreateFlagNone);
		if (stream==NULL) {
	 		NSLog(@"MGMPathSubscription: Unable to subscribe to %@", thePath);
	 		return;
		}
		FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
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
}
- (void)removePath:(NSString *)thePath {
	NSValue *value = [subscriptions objectForKey:thePath];
	if (value!=nil) {
		if ([self OSMajorVersion]==10 && [self OSMinorVersion]>=5) {
			FSEventStreamRef stream = [value pointerValue];
			FSEventStreamStop(stream);
			FSEventStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
			FSEventStreamInvalidate(stream);
			FSEventStreamRelease(stream);
			[subscriptions removeObjectForKey:thePath];
		} else {
			FNUnsubscribe([value pointerValue]);
			[subscriptions removeObjectForKey:thePath];
		}
	}
}
- (void)removeAllPaths {
	NSArray *keys = [subscriptions allKeys];
	for (int i=0; i<[keys count]; i++) {
		FNUnsubscribe([[subscriptions objectForKey:[keys objectAtIndex:i]] pointerValue]);
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
- (void)sendNotificationForPath:(NSString *)thePath {
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMSubscribedPathChangedNotification object:thePath];
	if ([delegate respondsToSelector:@selector(subscribedPathChanged:)]) [delegate subscribedPathChanged:thePath];
	[notificationsSending removeObject:thePath];
}
@end