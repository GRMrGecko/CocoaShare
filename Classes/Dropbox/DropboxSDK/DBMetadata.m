//
//  DBMetadata.m
//  DropboxSDK
//
//  Created by Brian Smith on 5/3/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBMetadata.h"

@implementation DBMetadata

+ (NSDateFormatter*)dateFormatter {
	NSMutableDictionary* dictionary = [[NSThread currentThread] threadDictionary];
	static NSString* dateFormatterKey = @"DBMetadataDateFormatter";
	
    NSDateFormatter* dateFormatter = [dictionary objectForKey:dateFormatterKey];
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter new] autorelease];
        // Must set locale to ensure consistent parsing:
        // http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html
		dateFormatter.locale = 
			[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
		dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
        [dictionary setObject:dateFormatter forKey:dateFormatterKey];
    }
    return dateFormatter;
}

- (id)initWithDictionary:(NSDictionary*)dict {
    if ((self = [super init])) {
        thumbnailExists = [[dict objectForKey:@"thumb_exists"] boolValue];
        totalBytes = [[dict objectForKey:@"bytes"] longLongValue];

        if ([dict objectForKey:@"modified"]) {
            lastModifiedDate = 
				[[[DBMetadata dateFormatter] dateFromString:[dict objectForKey:@"modified"]] retain];
        }

        path = [[dict objectForKey:@"path"] retain];
        isDirectory = [[dict objectForKey:@"is_dir"] boolValue];
        
        if ([dict objectForKey:@"contents"]) {
            NSArray* subfileDicts = [dict objectForKey:@"contents"];
            NSMutableArray* mutableContents = 
                [[NSMutableArray alloc] initWithCapacity:[subfileDicts count]];
            for (long long i=0; i<[subfileDicts count]; i++) {
                DBMetadata* subfile = [[DBMetadata alloc] initWithDictionary:[subfileDicts objectAtIndex:i]];
                [mutableContents addObject:subfile];
                [subfile release];
            }
            contents = mutableContents;
        }
        
        hash = [[dict objectForKey:@"hash"] retain];
        humanReadableSize = [[dict objectForKey:@"size"] retain];
        root = [[dict objectForKey:@"root"] retain];
        icon = [[dict objectForKey:@"icon"] retain];
        revision = [[dict objectForKey:@"revision"] longLongValue];
        isDeleted = [[dict objectForKey:@"is_deleted"] boolValue];
    }
    return self;
}

- (void)dealloc {
    [lastModifiedDate release];
    [path release];
    [contents release];
    [hash release];
    [humanReadableSize release];
    [root release];
    [icon release];
    [super dealloc];
}

- (BOOL)thumbnailExists {
	return thumbnailExists;
}
- (long long)totalBytes {
	return totalBytes;
}
- (NSDate *)lastModifiedDate {
	return lastModifiedDate;
}
- (NSString *)path {
	return path;
}
- (BOOL)isDirectory {
	return isDirectory;
}
- (NSArray *)contents {
	return contents;
}
- (NSString *)hash {
	return hash;
}
- (NSString *)humanReadableSize {
	return humanReadableSize;
}
- (NSString *)root {
	return root;
}
- (NSString *)icon {
	return icon;
}
- (long long)revision {
	return revision;
}
- (BOOL)isDeleted {
	return isDeleted;
}


#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super init])) {
        thumbnailExists = [coder decodeBoolForKey:@"thumbnailExists"];
        totalBytes = [coder decodeInt64ForKey:@"totalBytes"];
        lastModifiedDate = [[coder decodeObjectForKey:@"lastModifiedDate"] retain];
        path = [[coder decodeObjectForKey:@"path"] retain];
        isDirectory = [coder decodeBoolForKey:@"isDirectory"];
        contents = [[coder decodeObjectForKey:@"contents"] retain];
        hash = [[coder decodeObjectForKey:@"hash"] retain];
        humanReadableSize = [[coder decodeObjectForKey:@"humanReadableSize"] retain];
        root = [[coder decodeObjectForKey:@"root"] retain];
        icon = [[coder decodeObjectForKey:@"icon"] retain];
        revision = [coder decodeInt64ForKey:@"revision"];
        isDeleted = [coder decodeBoolForKey:@"isDeleted"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeBool:thumbnailExists forKey:@"thumbnailExists"];
    [coder encodeInt64:totalBytes forKey:@"totalBytes"];
    [coder encodeObject:lastModifiedDate forKey:@"lastModifiedDate"];
    [coder encodeObject:path forKey:@"path"];
    [coder encodeBool:isDirectory forKey:@"isDirectory"];
    [coder encodeObject:contents forKey:@"contents"];
    [coder encodeObject:hash forKey:@"hash"];
    [coder encodeObject:humanReadableSize forKey:@"humanReadableSize"];
    [coder encodeObject:root forKey:@"root"];
    [coder encodeObject:icon forKey:@"icon"];
    [coder encodeInt64:revision forKey:@"revision"];
    [coder encodeBool:isDeleted forKey:@"isDeleted"];
}


@end
