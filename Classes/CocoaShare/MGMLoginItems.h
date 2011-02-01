//
//  MGMLoginItems.h
//  Exhaust
//
//  Created by Mr. Gecko on 8/7/10.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

@interface MGMLoginItems : NSObject {
	NSMutableDictionary *loginItems;
}
+ (id)items;
- (NSArray *)paths;
- (BOOL)selfExists;
- (BOOL)addSelf;
- (BOOL)removeSelf;
- (BOOL)exists:(NSString *)thePath;
- (BOOL)add:(NSString *)thePath;
- (BOOL)add:(NSString *)thePath hide:(BOOL)shouldHide;
- (BOOL)remove:(NSString *)thePath;
- (void)_save;
@end