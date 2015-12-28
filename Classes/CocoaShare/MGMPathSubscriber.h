//
//  MGMPathSubscriber.h
//  Conmote
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2013 Mr. Gecko's Media (James Coleman). http://mrgeckosmedia.com/
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose
//  with or without fee is hereby granted, provided that the above copyright notice
//  and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//  REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT,
//  OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
//  DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
//  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
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