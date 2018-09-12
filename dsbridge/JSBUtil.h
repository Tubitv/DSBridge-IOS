//
//  Util.h
//  dspider
//
//  Created by 杜文 on 16/12/27.
//  Copyright © 2016年 杜文. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWebview.h"

static NSString * _Nonnull BRIDGE_NAME=@"_dsbridge";

#define SuppressPerformSelectorLeakWarning(Stuff) \
{ \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
}

@interface JSBUtil : NSObject
+ (NSString * _Nullable)objToJsonString:(id  _Nonnull)dict;
+ (id  _Nullable)jsonStringToObject:(NSString * _Nonnull)jsonString;
+ (NSDictionary * _Nullable)call:(NSString* _Nonnull) method :(NSString* _Nonnull) args  JavascriptInterfaceObject:(id _Nonnull) JavascriptInterfaceObject jscontext:(id _Nonnull) jscontext;

@end
