//
//  Util.m
//  Created by 杜文 on 16/12/27.
//  Copyright © 2016年 杜文. All rights reserved.
//

#import "JSBUtil.h"
#import "DWebview.h"
#import <objc/runtime.h>

@implementation JSBUtil
+ (NSString *)objToJsonString:(id)dict
{
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (!jsonData) {
        return @"{}";
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

UInt64 g_ds_last_call_time = 0;
NSString *g_ds_js_cache=@"";
bool g_ds_have_pending=false;

+(NSString *)call:(NSString*) method :(NSString*) args JavascriptInterfaceObject:(id) JavascriptInterfaceObject jscontext:(id) jscontext
{
    NSString *methodOne = [JSBUtil methodByNameArg:1 selName:method class:[JavascriptInterfaceObject class]];
    NSString *methodTwo = [JSBUtil methodByNameArg:2 selName:method class:[JavascriptInterfaceObject class]];
    NSLog(@"call methodOne: %@, methodTwo: %@", methodOne, methodTwo);
    SEL sel=NSSelectorFromString(methodOne);
    SEL selasync=NSSelectorFromString(methodTwo);
    NSString *error=[NSString stringWithFormat:@"Error! \n Method %@ is not invoked, since there is not a implementation for it", method];
    NSString *result=@"";
    if(!JavascriptInterfaceObject){
        NSLog(@"Js bridge method called, but there is no JavascriptInterfaceObject, please set JavascriptInterfaceObject first!");
    }else{
        NSMutableDictionary *json=[JSBUtil jsonStringToObject:args];
        NSString *cb;
        do{
            if(json && (cb=[json valueForKey:@"_callbackId"])){
                [json removeObjectForKey:@"_callbackId"];
                if([JavascriptInterfaceObject respondsToSelector:selasync]){
                    // FIXME currently, `value` should be a json string.
                    // a better way is, make it a serializable object, and stringify it inside of `completionHandler`, our developers should be glad to see it
                    void (^completionHandler)(NSString *, BOOL) = ^(NSString * value, BOOL complete){
                        if(value == nil){
                            value=@"";
                        }
                        // FIXME special process for no return value, we could make it more OC
                        if([value isEqual: @""]){
                            value=[JSBUtil objToJsonString:@{ @"result" : @"" }];
                        }
                        NSString *js=[NSString stringWithFormat:@"%@.invokeCallback && %@.invokeCallback(%@, %@, %@)", BRIDGE_NAME, BRIDGE_NAME, cb, value, complete ? @"true" : @"false"];
                        NSLog(@"call js: %@", js);
                        if([jscontext isKindOfClass:JSContext.class]){
                            [jscontext evaluateScript:js];
                        }else if([jscontext isKindOfClass:WKWebView.class]){
                            @synchronized(jscontext)
                            {
                                UInt64 t=[[NSDate date] timeIntervalSince1970]*1000;
                                g_ds_js_cache=[g_ds_js_cache stringByAppendingString:js];
                                if(t-g_ds_last_call_time<50){
                                    if(!g_ds_have_pending){
                                        [self evalJavascript:(WKWebView *)jscontext :50];
                                        g_ds_have_pending=true;
                                    }
                                }else{
                                    [self evalJavascript:(WKWebView *)jscontext  :0];
                                }
                            }
                        }
                    };
                    SuppressPerformSelectorLeakWarning(
                                                       [JavascriptInterfaceObject performSelector:selasync withObject:json withObject:completionHandler];
                                                       );
                    //when performSelector is performing a selector that return value type is void,
                    //the return value of performSelector always seem to be the first argument of the selector in real device(simulator is nil).
                    //So,you should declare the return type of all api as NSString explicitly.
                    if(result==(id)json){
                        result=@"";
                    }
                    
                    break;
                }
            }else if([JavascriptInterfaceObject respondsToSelector:sel]){
                SuppressPerformSelectorLeakWarning(
                                                   result=[JavascriptInterfaceObject performSelector:sel withObject:json];
                                                   );
                break;
            }
            NSString*js=[error stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
            js=[NSString stringWithFormat:@"window.alert(decodeURIComponent(\"%@\"));", js];
            if([jscontext isKindOfClass:JSContext.class]){
                [jscontext evaluateScript:js];
            }else if([jscontext isKindOfClass:WKWebView.class]){
                [(WKWebView *)jscontext evaluateJavaScript:js completionHandler:nil];
            }
            NSLog(@"%@", error);
        }while (0);
    }
    if(result == nil||![result isKindOfClass:[NSString class]]){
        result=@"";
    }
    return result;
}

//get this class all method
+(NSArray *)allMethodFromClass:(Class)class
{
    NSMutableArray *arr = [NSMutableArray array];
    u_int count;
    Method *methods = class_copyMethodList(class, &count);
    for (int i=0; i<count; i++) {
        SEL name1 = method_getName(methods[i]);
        const char *selName= sel_getName(name1);
        NSString *strName = [NSString stringWithCString:selName encoding:NSUTF8StringEncoding];
        //NSLog(@"%@",strName);
        [arr addObject:strName];
    }
    return arr;
}

//return method name for xxx: or xxx:handle:
+(NSString *)methodByNameArg:(NSInteger)argNum selName:(NSString *)selName class:(Class)class
{
    NSString *result = nil;
    NSArray *arr = [JSBUtil allMethodFromClass:class];
    for (int i=0; i<arr.count; i++) {
        NSString *method = arr[i];
        NSArray *tmpArr = [method componentsSeparatedByString:@":"];
        if ([method hasPrefix:selName]&&tmpArr.count==(argNum+1)) {
            result = method;
            return result;
        }
    }
    
    return result;
}


+ (void)evalJavascript:(WKWebView *)jscontext :(int) delay{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        //NSLog(@"\%@\n",g_ds_js_cache);
        @synchronized(jscontext){
            if([g_ds_js_cache length]!=0){
                [(WKWebView *)jscontext evaluateJavaScript :g_ds_js_cache completionHandler:nil];
                g_ds_have_pending=false;
                g_ds_js_cache=@"";
                g_ds_last_call_time=[[NSDate date] timeIntervalSince1970]*1000;
            }
        }
    });
}


+ (id)jsonStringToObject:(NSString *)jsonString
{
    if(jsonString == nil){
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err){
        NSLog(@"json decoding fail：%@", err);
        return nil;
    }
    return dic;
}

@end
