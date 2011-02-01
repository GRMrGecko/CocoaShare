//
//  DBRestRequest.h
//  DropboxSDK
//
//  Created by Brian Smith on 4/9/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//


@protocol DBNetworkRequestDelegate;

/* DBRestRequest will download a URL either into a file that you provied the name to or it will
   create an NSData object with the result. When it has completed downloading the URL, it will
   notify the target with a selector that takes the DBRestRequest as the only parameter. */
@interface DBRequest : NSObject {
    NSURLRequest* request;
    id target;
    SEL selector;
    NSURLConnection* urlConnection;
    NSFileHandle* fileHandle;

    SEL failureSelector;
    SEL downloadProgressSelector;
    SEL uploadProgressSelector;
    NSString* resultFilename;
    NSString* tempFilename;
    NSDictionary* userInfo;

    NSHTTPURLResponse* response;
    int bytesDownloaded;
    float downloadProgress;
    float uploadProgress;
    NSMutableData* resultData;
    NSError* error;
}

/*  Set this to get called when _any_ request starts or stops. This should hook into whatever
    network activity indicator system you have. */
+ (void)setNetworkRequestDelegate:(id<DBNetworkRequestDelegate>)delegate;

/*  This constructor downloads the URL into the resultData object */
- (id)initWithURLRequest:(NSURLRequest*)request andInformTarget:(id)target selector:(SEL)selector;

/*  Cancels the request and prevents it from sending additional messages to the delegate. */
- (void)cancel;

- (void)setFailureSelector:(SEL)theSelector; // To send failure events to a different selector set this
- (SEL)failureSelector;
- (void)setDownloadProgressSelector:(SEL)theSelector; // To receive download progress events set this
- (SEL)downloadProgressSelector;
- (void)setUploadProgressSelector:(SEL)theSelector; // To receive upload progress events set this
- (SEL)uploadProgressSelector;
- (void)setResultFilename:(NSString *)theName; // The file to put the HTTP body in, otherwise body is stored in resultData
- (NSString *)resultFilename;
- (void)setUserInfo:(NSDictionary *)theInfo;
- (NSDictionary *)userInfo;

- (NSURLRequest *)request;
- (NSHTTPURLResponse *)response;
- (int)statusCode;
- (float)downloadProgress;
- (float)uploadProgress;
- (NSData *)resultData;
- (NSString *)resultString;
- (NSObject *)resultJSON;
- (NSError *)error;
@end


@protocol DBNetworkRequestDelegate 

- (void)networkRequestStarted;
- (void)networkRequestStopped;

@end
