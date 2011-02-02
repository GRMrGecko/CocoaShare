//
//  MGMAutoUpdateField.m
//  CocoaShare
//
//  Created by Mr. Gecko on 1/17/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMAutoUpdateField.h"

@implementation MGMAutoUpdateField
- (void)keyUp:(NSEvent *)theEvent {
	[self sendAction:[self action] to:[self target]];
}
@end