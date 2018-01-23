//
//  SynJsBridgeWebview.m
//  dspider
//
//  Created by 杜文 on 16/12/30.
//  Copyright © 2016年 杜文. All rights reserved.
//

#import "DWebview.h"

@interface DWebview ()
@property (weak) id webview;
@end

@implementation DWebview
{
    void(^javascriptContextInitedListener)(void);
    //NSString * ua;
}

@synthesize webview;
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        id wv=[[DWKwebview alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:wv];
        webview=wv;
    }
    return self;
}

- (id _Nullable) getXWebview
{
    return webview;
}

- (void)loadRequest:(NSURLRequest *)request
{
    [(DWKwebview *)webview loadRequest:request];
}



- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    [(DWKwebview *)webview loadHTMLString:string baseURL:baseURL];
}

- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL
{
    [(DWKwebview *)webview loadData:data MIMEType:MIMEType characterEncodingName:textEncodingName baseURL:baseURL];
}

-(BOOL)canGoBack
{
    return ((DWKwebview *)webview).canGoBack;
}

-(BOOL)canGoForward
{
    return ((DWKwebview *)webview).canGoForward;
}

-(BOOL)isLoading
{
    return ((DWKwebview *)webview).isLoading;
}

-(void)reload
{
    [(DWKwebview *)webview reload];
}

- (void)stopLoading
{
    [(DWKwebview *)webview stopLoading];
}

-(void)setJavascriptInterfaceObject:(id)jsib
{
    ((DWKwebview *)webview).JavascriptInterfaceObject=jsib;
}

- (void)loadUrl: (NSString *)url
{
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self loadRequest:request];//load
}

- (void)setJavascriptBridgeInitedListener:(void (^)(void))callback
{
    [(DWKwebview *)webview setJavascriptBridgeInitedListener:callback];
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(NSString *))completionHandler
{
    [(DWKwebview *)webview evaluateJavaScript:javaScriptString completionHandler:^(NSString * result, NSError * error){
        if(error){
            NSLog(@"WKwebview exec js error: %@", error);
        }
        if(!result) result=@"";
        if(completionHandler) completionHandler(error ? nil : result);
    }];
}

-(void)callHandler:(NSString *)methodName arguments:(NSArray *)args completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    [(DWKwebview *)webview callHandler:methodName arguments:args completionHandler:completionHandler];
}

- (void)clearCache
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        NSSet *websiteDataTypes= [NSSet setWithArray:@[
                                                       WKWebsiteDataTypeDiskCache,
                                                       //WKWebsiteDataTypeOfflineWebApplication
                                                       WKWebsiteDataTypeMemoryCache,
                                                       //WKWebsiteDataTypeLocal
                                                       WKWebsiteDataTypeCookies,
                                                       //WKWebsiteDataTypeSessionStorage,
                                                       //WKWebsiteDataTypeIndexedDBDatabases,
                                                       //WKWebsiteDataTypeWebSQLDatabases
                                                       ]];
        
        // All kinds of data
        //NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            
        }];
        
    } else {
        // clear cookie first
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            [storage deleteCookie:cookie];
        }
        
        NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary]
                                objectForKey:@"CFBundleIdentifier"];
        NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
        NSString *webKitFolderInCaches = [NSString
                                          stringWithFormat:@"%@/Caches/%@/WebKit",libraryDir,bundleId];
        NSString *webKitFolderInCachesfs = [NSString
                                            stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
        NSError *error;
        /* iOS8.0 WebView Cache file path */
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
        /* iOS7.0 WebView Cache file path */
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCachesfs error:&error];
        NSString *cookiesFolderPath = [libraryDir stringByAppendingString:@"/Cookies"];
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&error];
    }
    
}
@end
