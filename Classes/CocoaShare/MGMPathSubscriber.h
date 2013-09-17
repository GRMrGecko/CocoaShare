//
//  MGMPathSubscriber.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/event.h>

extern NSString * const MGMPathSubscriptionChangedNotification;

typedef enum {
	MGMFODelete = NOTE_DELETE,
	MGMFOWrite = NOTE_WRITE,
	MGMFOExtend = NOTE_EXTEND,
	MGMFOAttribute = NOTE_ATTRIB,
	MGMFOLink = NOTE_LINK,
	MGMFORename = NOTE_RENAME,
	MGMFORevoke = NOTE_REVOKE
} MGMPathSubscriptionFileOptions;

@protocol MGMPathSubscriberDelegate <NSObject>
- (void)subscribedPathChanged:(NSString *)thePath;
@end

@interface MGMPathSubscriber : NSObject {
	id<MGMPathSubscriberDelegate> delegate;
	NSMutableDictionary *subscriptions;
	FNSubscriptionUPP subscriptionUPP;
	CFRunLoopRef runLoop;
	NSMutableArray *notificationsSending;
	
	int queueDescriptor;
    BOOL fileWatchLoop;
}
+ (id)sharedPathSubscriber;

- (id<MGMPathSubscriberDelegate>)delegate;
- (void)setDelegate:(id)theDelegate;

- (void)addPath:(NSString *)thePath;
- (void)addPath:(NSString *)thePath fileOptions:(u_int)theOptions;
- (void)removePath:(NSString *)thePath;
- (void)removeAllPaths;

- (NSArray *)subscribedPaths;
@end