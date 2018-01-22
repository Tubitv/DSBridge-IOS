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
  void(^handler)(NSString *s,BOOL isComplete);
  int value;
}
@end

@implementation JsApiTest
- (NSString *) testSync:(NSDictionary *) args
{
    return [(NSString *)[args valueForKey:@"msg"] stringByAppendingString:@"[sync call]"];
}

- (void) testAsync:(NSDictionary *) args :(void (^)(NSString * _Nullable result, BOOL complete))completionHandler
{
    // FIXME we could do better, handling the details in lib layer
    NSDictionary *dict=@{ @"result": [(NSString *)[args valueForKey:@"msg"] stringByAppendingString:@"[async call]"] };
    NSError *error;
    NSData *result=[NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    completionHandler([[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding], YES);
}

- (NSString *)testNoArgSync:(NSDictionary *) args
{
    return  @"testNoArgSyn called [sync call]";
}

- (void)testNoArgAsync:(NSDictionary *) args :(void (^)(NSString * _Nullable result, BOOL complete))completionHandler
{
    // FIXME we could do better, handling the details in lib layer
    NSDictionary *dict=@{ @"result": @"testNoArgAsync called [async call]" };
    NSError *error;
    NSData *result=[NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    completionHandler([[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding], YES);
}

- (void)callProgress:(NSDictionary *) args :(void (^)(NSString * _Nullable result, BOOL complete))completionHandler
{
    value = 10;
    handler = completionHandler;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}

-(void)onTimer:t{
    if (value != -1) {
        // FIXME we could do better, handling the details in lib layer
        NSDictionary *dict=@{ @"result": [NSString stringWithFormat:@"%d", value--] };
        NSError *error;
        NSData *result=[NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        handler([[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding], NO);
    } else {
        handler(@"", YES);
        [timer invalidate];
    }
}
@end
