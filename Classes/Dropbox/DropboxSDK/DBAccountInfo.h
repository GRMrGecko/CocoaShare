//
//  DBAccountInfo.h
//  DropboxSDK
//
//  Created by Brian Smith on 5/3/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//


#import "DBQuota.h"

@interface DBAccountInfo : NSObject <NSCoding> {
    NSString* country;
    NSString* displayName;
    DBQuota* quota;
    NSString* userId;
    NSString* referralLink;
}
- (id)initWithDictionary:(NSDictionary*)dict;

- (NSString *)country;
- (NSString *)displayName;
- (DBQuota *)quota;
- (NSString *)userId;
- (NSString *)referralLink;
@end