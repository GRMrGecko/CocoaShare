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
- (void)sendNotificationForPath:(NSString *)thePath;
@end

static MGMPathSubscriber *MGMSharedPathSubscriber;
NSString * const MGMSubscribedPathChangedNotification = @"MGMSubscribedPathChangedNotification";

void MGMPathSubscriptionChange(FNMessage theMessage, OptionBits theFlags, void *thePathSubscription, FNSubscriptionRef theSubscription) {
    if (theMessage==kFNDirectoryModifiedMessage)
        [(MGMPathSubscriber *)thePathSubscription subscriptionChanged:theSubscription];
	else
		NSLog(@"MGMPathSubscription: Received unkown message: %d", theMessage);
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

- (void)addPath:(NSString *)thePath {
	NSValue *value = [subscriptions objectForKey:thePath];
	if (value!=nil)
		return;
	FNSubscriptionRef subscription = NULL;
	OSStatus error = FNSubscribeByPath((UInt8 *)[thePath fileSystemRepresentation], subscriptionUPP, self, kFNNotifyInBackground, &subscription);
	if (error!=noErr) {
		NSLog(@"MGMPathSubscription: Unable to subscribe to %@ due to the error %d", thePath, error);
		return;
	}
	[subscriptions setObject:[NSValue valueWithPointer:subscription] forKey:thePath];
}
- (void)removePath:(NSString *)thePath {
	NSValue *value = [subscriptions objectForKey:thePath];
	if (value!=nil) {
		FNUnsubscribe([value pointerValue]);
		[subscriptions removeObjectForKey:thePath];
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
- (void)sendNotificationForPath:(NSString *)thePath {
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMSubscribedPathChangedNotification object:thePath];
	if ([delegate respondsToSelector:@selector(subscribedPathChanged:)]) [delegate subscribedPathChanged:thePath];
	[notificationsSending removeObject:thePath];
}
@end