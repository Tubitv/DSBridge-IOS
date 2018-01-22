//
//  DSWKwebview.m
//  dspider
//
//  Created by 杜文 on 16/12/28.
//  Copyright © 2016年 杜文. All rights reserved.
//

#import "DWKwebview.h"
#import "JSBUtil.h"

@implementation DWKwebview
{
    void (^alertHandler)(void);
    void (^confirmHandler)(BOOL);
    void (^promptHandler)(NSString *);
    int dialogType;
    UITextField *txtName;
    int counter;
    NSMutableDictionary *callbackDict;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration
{
    txtName=nil;
    dialogType=0;
    alertHandler=nil;
    confirmHandler=nil;
    promptHandler=nil;
    counter=0;
    callbackDict=[NSMutableDictionary dictionary];
    NSString * js = [NSString stringWithFormat:@"window[\"%@\"] = window[\"%@\"] || { wk: true };", BRIDGE_NAME, BRIDGE_NAME];
    NSLog(@"initWithFrame %@", js);
    WKUserScript *script = [[WKUserScript alloc] initWithSource:js
                                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                               forMainFrameOnly:YES];
    WKUserScript *scriptDomReady = [[WKUserScript alloc] initWithSource:@";prompt('_dsinited');"
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                        forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:scriptDomReady];
    [configuration.userContentController addUserScript:script];
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        super.UIDelegate=self;
    }
    return self;
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    NSString * prefix=[NSString stringWithFormat:@"%@=", BRIDGE_NAME];
    NSString * cidPrefix=[NSString stringWithFormat:@"%@cid=", BRIDGE_NAME];
    NSLog(@"runJavaScriptTextInputPanelWithPrompt prefix: %@, prompt: %@", prefix, prompt);
    if([prompt hasPrefix:prefix]){
        NSString *method=[prompt substringFromIndex:[prefix length]];
        NSString *result=[JSBUtil call:method :defaultText JavascriptInterfaceObject:_JavascriptInterfaceObject jscontext:webView];
        completionHandler(result);
    /*
    }else if([prompt hasPrefix:cidPrefix]){
        // TODO finish callback execution
        NSString *cid=[prompt substringFromIndex:[cidPrefix length]];
        NSLog(@"cid callback %@", cid);
    */
    }else if([prompt hasPrefix:@"_dsinited"]){
        completionHandler(@"");
        if(javascriptContextInitedListener) javascriptContextInitedListener();
    }else{
        if(self.DSUIDelegate && [self.DSUIDelegate respondsToSelector:
                                 @selector(webView:runJavaScriptTextInputPanelWithPrompt
                                           :defaultText:initiatedByFrame
                                           :completionHandler:)])
        {
            return [self.DSUIDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt
                                  defaultText:defaultText
                             initiatedByFrame:frame
                            completionHandler:completionHandler];
        }else{
            dialogType=3;
            promptHandler=completionHandler;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:prompt message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
            txtName = [alert textFieldAtIndex:0];
            txtName.text=defaultText;
            [alert show];
        }
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(void))completionHandler
{
    if(self.DSUIDelegate &&  [self.DSUIDelegate respondsToSelector:
                               @selector(webView:runJavaScriptAlertPanelWithMessage
                                         :initiatedByFrame:completionHandler:)])
    {
        return [self.DSUIDelegate webView:webView runJavaScriptAlertPanelWithMessage:message
                         initiatedByFrame:frame
                        completionHandler:completionHandler];
    }else{
        dialogType=1;
        alertHandler=completionHandler;
        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:@"Tip"
                                   message:message
                                  delegate:self
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil,nil];
        [alertView show];
    }
}

-(void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    if(self.DSUIDelegate && [self.DSUIDelegate respondsToSelector:
                              @selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)])
    {
        return[self.DSUIDelegate webView:webView runJavaScriptConfirmPanelWithMessage:message
                        initiatedByFrame:frame
                       completionHandler:completionHandler];
    }else{
        dialogType=2;
        confirmHandler=completionHandler;
        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:@"Tip"
                                   message:message
                                  delegate:self
                         cancelButtonTitle:@"Cancel"
                         otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(dialogType==1 && alertHandler){
        alertHandler();
        alertHandler=nil;
    }else if(dialogType==2 && confirmHandler){
        confirmHandler(buttonIndex==1?YES:NO);
        confirmHandler=nil;
    }else if(dialogType==3 && promptHandler && txtName) {
        if(buttonIndex==1){
            promptHandler([txtName text]);
        }else{
            promptHandler(@"");
        }
        promptHandler=nil;
        txtName=nil;
    }
}

- (void)setJavascriptContextInitedListener:(void (^)(void))callback
{
    javascriptContextInitedListener=callback;
}

- (void)loadUrl: (NSString *)url
{
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self loadRequest:request];
}

-(void)callHandler:(NSString *)methodName arguments:(NSArray *)args completionHandler:(void (^)(NSString *  _Nullable))completionHandler
{
    if(!args){
        args=[[NSArray alloc] init];
    }
    // TODO support async callback
    NSString *script=[NSString stringWithFormat:@"window[\"%@\"].invokeHandler && window[\"%@\"].invokeHandler(\"%@\", %@)", BRIDGE_NAME, BRIDGE_NAME, methodName, [JSBUtil objToJsonString:args]];
    NSLog(@"callHandler %@", script);
    [self evaluateJavaScript:script completionHandler:^(id value, NSError * error){
        if(completionHandler) completionHandler(value);
    }];
}

@end


