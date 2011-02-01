//
//  DBQuota.h
//  DropboxSDK
//
//  Created by Brian Smith on 5/3/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//


@interface DBQuota : NSObject <NSCoding> {
    long long normalConsumedBytes;
    long long sharedConsumedBytes;
    long long totalBytes;
}
- (id)initWithDictionary:(NSDictionary*)dict;

- (long long)normalConsumedBytes;
- (long long)sharedConsumedBytes;
- (long long)totalConsumedBytes;
- (long long)totalBytes;
@end
