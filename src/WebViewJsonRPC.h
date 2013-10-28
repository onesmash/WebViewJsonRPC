//
//  WebViewJsonRPC.h
//  WebViewJsonRPC
//
//  Created by Xuhui on 13-10-27.
//  Copyright (c) 2013年 Xuhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^JsonRPCCallback)(id);

typedef void (^JsonRPCHandler)(NSDictionary *, JsonRPCCallback);


@interface WebViewJsonRPC : NSObject <UIWebViewDelegate>

+ (NSString *)jsonDictToString:(NSDictionary *)json;
+ (NSDictionary *)stringToJsonDict:(NSString *)str;

- (void)connect:(UIWebView *)webView;
- (void)close;
- (void)registerHandler:(NSString *)name Handler:(JsonRPCHandler)handler;
- (void)unregisterHandler:(NSString *)name;

@end
