//
//  JsApiTest.m
//  dspider
//
//  Created by 杜文 on 16/12/30.
//  Copyright © 2016年 杜文. All rights reserved.
//

#import "JsApiTest.h"

@interface JsApiTest(){
  NSTimer * timer ;
  void(^handler)(NSDictionary *s, BOOL isComplete);
  int value;
}
@end

@implementation JsApiTest
- (NSDictionary *) testSync:(NSDictionary *) args
{
    return @{ @"result": [(NSString *)[args valueForKey:@"msg"] stringByAppendingString:@"[sync call]"] };
}

- (void) testAsync:(NSDictionary *) args :(void (^)(NSDictionary * _Nullable result, BOOL complete))completionHandler
{
    completionHandler(@{ @"result": [(NSString *)[args valueForKey:@"msg"] stringByAppendingString:@"[async call]"] }, YES);
}

- (NSDictionary *)testNoArgSync:(NSDictionary *) args
{
    return @{ @"result": @"testNoArgSyn called [sync call]" };
}

- (void)testNoArgAsync:(NSDictionary *) args :(void (^)(NSDictionary * _Nullable result, BOOL complete))completionHandler
{
    completionHandler(@{ @"result": @"testNoArgAsync called [async call]" }, YES);
}

- (void)callProgress:(NSDictionary *) args :(void (^)(NSDictionary * _Nullable result, BOOL complete))completionHandler
{
    value = 10;
    handler = completionHandler;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}

-(void)onTimer:t{
    if (value != -1) {
        handler(@{ @"result": [NSString stringWithFormat:@"%d", value--] }, NO);
    } else {
        handler(@{}, YES);
        [timer invalidate];
    }
}
@end
