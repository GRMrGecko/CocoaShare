//
//  DBMetadata.h
//  DropboxSDK
//
//  Created by Brian Smith on 5/3/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//


@interface DBMetadata : NSObject <NSCoding> {
    BOOL thumbnailExists;
    long long totalBytes;
    NSDate* lastModifiedDate;
    NSString* path;
    BOOL isDirectory;
    NSArray* contents;
    NSString* hash;
    NSString* humanReadableSize;
    NSString* root;
    NSString* icon;
    long long revision;
    BOOL isDeleted;
}
- (id)initWithDictionary:(NSDictionary*)dict;

- (BOOL)thumbnailExists;
- (long long)totalBytes;
- (NSDate *)lastModifiedDate;
- (NSString *)path;
- (BOOL)isDirectory;
- (NSArray *)contents;
- (NSString *)hash;
- (NSString *)humanReadableSize;
- (NSString *)root;
- (NSString *)icon;
- (long long)revision;
- (BOOL)isDeleted;
@end
