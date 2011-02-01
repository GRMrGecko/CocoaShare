#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
//
//  DBRestRequest.m
//  DropboxSDK
//
//  Created by Brian Smith on 4/9/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBRequest.h"
#import "DBError.h"
#import "JSON.h"


static id networkRequestDelegate = nil;

@implementation DBRequest

+ (void)setNetworkRequestDelegate:(id<DBNetworkRequestDelegate>)delegate {
    networkRequestDelegate = delegate;
}

- (id)initWithURLRequest:(NSURLRequest*)aRequest andInformTarget:(id)aTarget selector:(SEL)aSelector {
    if ((self = [super init])) {
        request = [aRequest retain];
        target = aTarget;
        selector = aSelector;
        
        urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [networkRequestDelegate networkRequestStarted];
    }
    return self;
}

- (void) dealloc {
    [urlConnection cancel];
	
    [request release];
    [urlConnection release];
    [fileHandle release];
    [userInfo release];
    [response release];
    [resultFilename release];
    [tempFilename release];
    [resultData release];
    [error release];
    [super dealloc];
}

- (void)setFailureSelector:(SEL)theSelector {
	failureSelector = theSelector;
}
- (SEL)failureSelector {
	return failureSelector;
}
- (void)setDownloadProgressSelector:(SEL)theSelector {
	downloadProgressSelector = theSelector;
}
- (SEL)downloadProgressSelector {
	return downloadProgressSelector;
}
- (void)setUploadProgressSelector:(SEL)theSelector {
	uploadProgressSelector = theSelector;
}
- (SEL)uploadProgressSelector {
	return uploadProgressSelector;
}
- (void)setResultFilename:(NSString *)theName {
	[resultFilename release];
	resultFilename = [theName retain];
}
- (NSString *)resultFilename {
	return resultFilename;
}
- (void)setUserInfo:(NSDictionary *)theInfo {
	[userInfo release];
	userInfo = [theInfo retain];
}
- (NSDictionary *)userInfo {
	return userInfo;
}

- (NSURLRequest *)request {
	return request;
}
- (NSHTTPURLResponse *)response {
	return response;
}
- (int)statusCode {
	return [response statusCode];
}
- (float)downloadProgress {
	return downloadProgress;
}
- (float)uploadProgress {
	return uploadProgress;
}
- (NSData *)resultData {
	return resultData;
}
- (NSString *)resultString {
	return [[[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding] autorelease];
}
- (NSObject *)resultJSON {
	return [[self resultString] JSONValue];
}
- (NSError *)error {
	return error;
}

- (void)cancel {
    [urlConnection cancel];
    target = nil;
    
    if (tempFilename) {
        [fileHandle closeFile];
        NSError* rmError;
		NSFileManager *manager = [NSFileManager defaultManager];
		BOOL result = NO;
		if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)])
			result = [manager removeFileAtPath:tempFilename handler:nil];
		else
			result = [manager removeItemAtPath:tempFilename error:&rmError];
        if (!result) {
            NSLog(@"DBRequest#cancel Error removing temp file: %@", rmError);
        }
    }
    
    [networkRequestDelegate networkRequestStopped];
}

#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)aResponse {
    response = [(NSHTTPURLResponse*)aResponse retain];
    
    if (resultFilename && [self statusCode] == 200) {
        // Create the file here so it's created in case it's zero length
        // File is downloaded into a temporary file and then moved over when completed successfully
        NSString* filename = 
            [NSString stringWithFormat:@"%.0f", 1000*[NSDate timeIntervalSinceReferenceDate]];
        tempFilename = [[NSTemporaryDirectory() stringByAppendingPathComponent:filename] retain];
        
        NSFileManager* fileManager = [[NSFileManager new] autorelease];
        BOOL success = [fileManager createFileAtPath:tempFilename contents:nil attributes:nil];
        if (!success) {
            NSLog(@"DBRequest#connection:didReceiveData: Error creating file at path: %@", 
                    tempFilename);
        }

        fileHandle = [[NSFileHandle fileHandleForWritingAtPath:tempFilename] retain];
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    if (resultFilename && [self statusCode] == 200) {
        @try {
            [fileHandle writeData:data];
        } @catch (NSException* e) {
            // In case we run out of disk space
            [urlConnection cancel];
            [fileHandle closeFile];
			NSFileManager *manager = [NSFileManager defaultManager];
			if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)])
				[manager removeFileAtPath:tempFilename handler:nil];
			else
				[manager removeItemAtPath:tempFilename error:nil];
            error = [[NSError alloc] initWithDomain:DBErrorDomain
                                        code:DBErrorInsufficientDiskSpace userInfo:userInfo];
            
            SEL sel = failureSelector ? failureSelector : selector;
            [target performSelector:sel withObject:self];
            
            [networkRequestDelegate networkRequestStopped];
            
            return;
        }
    } else {
        if (resultData == nil) {
            resultData = [NSMutableData new];
        }
        [resultData appendData:data];
    }
    
    bytesDownloaded += [data length];
    int contentLength = [[[response allHeaderFields] objectForKey:@"Content-Length"] intValue];
    downloadProgress = (float)bytesDownloaded / (float)contentLength;
    if (downloadProgressSelector) {
        [target performSelector:downloadProgressSelector withObject:self];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    [fileHandle closeFile];
    [fileHandle release];
    fileHandle = nil;
    
    if ([self statusCode] != 200) {
        NSMutableDictionary* errorUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
        // To get error userInfo, first try and make sense of the response as JSON, if that
        // fails then send back the string as an error message
        NSString* resultString = [self resultString];
        if ([resultString length] > 0) {
            @try {
                SBJsonParser *jsonParser = [SBJsonParser new];
                NSObject* resultJSON = [jsonParser objectWithString:resultString];
                [jsonParser release];
                
                if ([resultJSON isKindOfClass:[NSDictionary class]]) {
                    [errorUserInfo addEntriesFromDictionary:(NSDictionary*)resultJSON];
                }
            } @catch (NSException* e) {
                [errorUserInfo setObject:resultString forKey:@"errorMessage"];
            }
        }
        error = [[NSError alloc] initWithDomain:@"dropbox.com" code:[self statusCode] userInfo:errorUserInfo];
    } else if (tempFilename) {
        // Move temp file over to desired file
        NSFileManager *manager = [NSFileManager defaultManager];
		if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)])
			[manager removeFileAtPath:resultFilename handler:nil];
		else
			[manager removeItemAtPath:resultFilename error:nil];
        NSError* moveError;
		BOOL result = NO;
		if ([manager respondsToSelector:@selector(movePath:toPath:handler:)])
			result = [manager movePath:tempFilename toPath:resultFilename handler:nil];
		else
			result = [manager moveItemAtPath:tempFilename toPath:resultFilename error:&moveError];
        if (!result) {
            NSLog(@"DBRequest#connectionDidFinishLoading: error moving temp file to desired location: %@",
                [moveError localizedDescription]);
            error = [[NSError alloc] initWithDomain:moveError.domain code:moveError.code userInfo:userInfo];
        }
        
        [tempFilename release];
        tempFilename = nil;
    }
    
    SEL sel = (error && failureSelector) ? failureSelector : selector;
    [target performSelector:sel withObject:self];
    
    [networkRequestDelegate networkRequestStopped];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)anError {
    [fileHandle closeFile];
    error = [[NSError alloc] initWithDomain:anError.domain code:anError.code userInfo:userInfo];
    bytesDownloaded = 0;
    downloadProgress = 0;
    uploadProgress = 0;
    
    if (tempFilename) {
        NSFileManager *manager = [NSFileManager defaultManager];
		NSError* removeError;
		BOOL result = NO;
		if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)])
			result = [manager removeFileAtPath:tempFilename handler:nil];
		else
			result = [manager removeItemAtPath:tempFilename error:&removeError];
        if (!result) {
            NSLog(@"DBRequest#connection:didFailWithError: error removing temporary file: %@", 
                    [removeError localizedDescription]);
        }
        [tempFilename release];
        tempFilename = nil;
    }
    
    SEL sel = failureSelector ? failureSelector : selector;
    [target performSelector:sel withObject:self];

    [networkRequestDelegate networkRequestStopped];
}

- (void)connection:(NSURLConnection*)connection didSendBodyData:(int)bytesWritten 
    totalBytesWritten:(int)totalBytesWritten 
    totalBytesExpectedToWrite:(int)totalBytesExpectedToWrite {
    
    uploadProgress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    if (uploadProgressSelector) {
        [target performSelector:uploadProgressSelector withObject:self];
    }
}

@end
