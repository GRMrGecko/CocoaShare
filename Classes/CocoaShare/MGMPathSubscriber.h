//
//  MGMPathSubscriber.h
//  CocoaShare
//
//  Created by Mr. Gecko on 1/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Foundation/Foundation.h>

extern NSString * const MGMPathSubscriptionChangedNotification;

@protocol MGMPathSubscriberDelegate <NSObject>
- (void)subscribedPathChanged:(NSString *)thePath;
@end

@interface MGMPathSubscriber : NSObject {
	id<MGMPathSubscriberDelegate> delegate;
	NSMutableDictionary *subscriptions;
	FNSubscriptionUPP subscriptionUPP;
	NSMutableArray *notificationsSending;
}
+ (id)sharedPathSubscriber;

- (id<MGMPathSubscriberDelegate>)delegate;
- (void)setDelegate:(id)theDelegate;

- (void)addPath:(NSString *)thePath;
- (void)removePath:(NSString *)thePath;
- (void)removeAllPaths;

- (NSArray *)subscribedPaths;
@end