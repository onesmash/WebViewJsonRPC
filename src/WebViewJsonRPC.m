//
//  WebViewJsonRPC.m
//  WebViewJsonRPC
//
//  Created by Xuhui on 13-10-27.
//  Copyright (c) 2013年 Xuhui. All rights reserved.
//

#import "WebViewJsonRPC.h"

#define JsonRPCScheme @"jsonrpc"
#define JsonRPCVer @"2.0"
#define MethodTag @"method"
#define ParamsTag @"params"
#define IDTag @"id"
#define ResultTag @"result"
#define ErrorTag @"error"
#define ErrorCodeTag @"code"
#define ErrorMessageTag @"message"
#define ErrorDataTag @"data"

#define MethodNotFoundCode @"-32601"
#define MethodNotFoundMessage @"The method does not exist / is not available"

#define JsFileName @"WebViewJsonRPC.js"

#define JsCloseRPC @";if(window.jsbridge) {window.jsbridge.close()};"

#define MethodNotFoundError [NSDictionary dictionaryWithObjectsAndKeys:MethodNotFoundCode, ErrorCodeTag, MethodNotFoundMessage, ErrorMessageTag, nil]

@interface WebViewJsonRPC ()

@property (assign, nonatomic) UIWebView *webView;
@property (assign, nonatomic) id<UIWebViewDelegate> originDelegate;
@property (retain, nonatomic) NSMutableDictionary *handlers;

- (void)error:(NSDictionary *)error ID:(NSNumber *)rpcID;
- (void)respone:(id)res ID:(NSNumber *)rpcID;
- (void)callHandler:(NSString *)name Params:(NSDictionary *)params ID:(NSNumber *)ID Callback:(JsonRPCCallback)cb;

+ (BOOL)valid:(NSDictionary *)dict;

@end

@implementation WebViewJsonRPC

- (id)init {
    self = [super init];
    if(self != nil) {
        _handlers = [[NSMutableDictionary alloc] init];
        _webView = nil;
        _originDelegate = nil;
        
    }
    return self;
}

- (void)dealloc {
    [self close];
    [_handlers release];
    [super dealloc];
}

- (void)connect:(UIWebView *)webView {
    if(self.webView != nil) {
        [self close];
    }
    self.webView = webView;
    self.originDelegate = webView.delegate;
    self.webView.delegate = self;
    
}

- (void)close {
    [self.webView stringByEvaluatingJavaScriptFromString:JsCloseRPC];
    self.webView.delegate = self.originDelegate;
    self.originDelegate = nil;
    self.webView = nil;
    [self.handlers removeAllObjects];
}

- (void)registerHandler:(NSString *)name Handler:(JsonRPCHandler)handler {
    [self.handlers setObject:[[handler copy] autorelease] forKey:name];
}

- (void)unregisterHandler:(NSString *)name {
    [self.handlers removeObjectForKey:name];
}

- (void)callHandler:(NSString *)name Params:(NSDictionary *)params ID:(NSNumber *)ID Callback:(JsonRPCCallback)cb {
    JsonRPCHandler handler = [self.handlers objectForKey:name];
    if(!handler) {
        if(ID != nil) [self error:MethodNotFoundError ID:ID];
        return;
    }
    handler(params, cb);
}

- (void)error:(NSDictionary *)error ID:(NSNumber *)rpcID {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:JsonRPCVer, JsonRPCScheme, error, ErrorTag, rpcID, IDTag, nil];
    NSString *tmp = [WebViewJsonRPC jsonDictToString:dict];
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@";window.jsbridge.onMessage(%@);",  tmp]];
}

- (void)respone:(id)res ID:(NSNumber *)rpcID {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:JsonRPCVer, JsonRPCScheme, res, ResultTag, rpcID, IDTag, nil];
    NSString *tmp = [WebViewJsonRPC jsonDictToString:dict];
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@";window.jsbridge.onMessage(%@);",  tmp]];
}

+ (NSString *)jsonDictToString:(NSDictionary *)json {
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

+ (NSDictionary *)stringToJsonDict:(NSString *)str {
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

+ (BOOL)valid:(NSDictionary *)dict {
    
    NSString *jsonRPCVer = [dict objectForKey:JsonRPCScheme];
    if(jsonRPCVer != nil && [jsonRPCVer isEqualToString:JsonRPCVer])
        return YES;
    else
        return NO;
}

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if(webView != self.webView) return;
    if([self.originDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.originDelegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if(webView != self.webView) return;
    NSString *path = [[NSBundle mainBundle] pathForResource:JsFileName ofType:@"txt"];
    NSString *js = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [webView stringByEvaluatingJavaScriptFromString:js];
    if([self.originDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.originDelegate webViewDidFinishLoad:webView];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if(webView != self.webView) return YES;
    BOOL res = NO;
    NSURL *url = [request URL];
    NSString *scheme = [[url scheme] lowercaseString];
    if([scheme isEqualToString:JsonRPCScheme]) {
        NSDictionary *json = [WebViewJsonRPC stringToJsonDict:[url host]];
        if([WebViewJsonRPC valid:json]) {
            NSString *method = [json objectForKey:MethodTag];
            NSDictionary *params = [json objectForKey:ParamsTag];
            NSNumber *ID = [json objectForKey:IDTag];
            [self callHandler:method Params:params ID:(NSNumber *)ID Callback:^(id result) {
                if(ID != nil && result != nil) {
                    [self respone:result ID:ID];
                }

            }];
        }
        if([self.originDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
            res |= [self.originDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        }
        return res;
    }
    
    if([self.originDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        res |= [self.originDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    } else {
        res = YES;
    }
    
    return res;
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if(webView != self.webView) return;
    if([self.originDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.originDelegate webView:webView didFailLoadWithError:error];
    }
}

@end
