//
//  TestAreaBorderViewController.m
//  WoDataProject
//
//  Created by 郑光龙 on 2018/8/21.
//  Copyright © 2018年 fosung. All rights reserved.
//

#import "TestAreaBorderViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface TestAreaBorderViewController ()<UIWebViewDelegate>
@property(nonatomic, strong)UIWebView *webView;
@property(nonatomic, strong)JSContext *jsContext;
@end

@implementation TestAreaBorderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.webView];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"echartsmap" withExtension:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad");

    self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];

    [self createJSFuncitonMapselectchanged];

    [self updateMapData];

    CGFloat contentWidth = webView.scrollView.contentSize.width;
    if (contentWidth > kScreenW) {
        contentWidth = (contentWidth - kScreenW)/2;
        [webView.scrollView setContentOffset:CGPointMake(contentWidth, 0) animated:NO];
    }
//    webView.contentScaleFactor = 1.0;
    
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *ex){
        context.exception = ex;
        NSLog(@"异常信息%@",ex);
    };
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    NSLog(@"error=%@", error);
    
}

- (void)createJSFuncitonMapselectchanged {
    //    注入方法到js 给JS调用OC
    typeof(self) __weak wself = self;
    self.jsContext[@"mapselectchanged"] = ^() {
        NSLog(@"mapselectchanged");
        NSArray *args = [JSContext currentArguments];
        NSMutableArray *paramArray = [[NSMutableArray alloc] init];
        for (JSValue *jsVal in args) {
            NSLog(@"%@", jsVal.toString);
            [paramArray addObject:[jsVal.toString copy]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            TestAreaBorderViewController *testVC = [[TestAreaBorderViewController alloc] init];
            testVC.mapName = paramArray[0];
            testVC.mapCode = paramArray[1];
            
            NSString *mapData = [wself getAreaJsonDataWithAreaCode:testVC.mapCode];
            if (mapData) {
                [wself.navigationController pushViewController:testVC animated:NO];
            }
        });
    };
}

- (void)updateMapData {
//  函数updateMapOption与loadMap的调用顺序不能变，在JS中先初始化option 然后把option设置给map
    NSString *mapData = [self getAreaJsonDataWithAreaCode:self.mapCode];
    JSValue *updateMapOption = self.jsContext[@"updateMapOption"];
    NSError *error;
    NSDictionary *mapDataDict = [NSJSONSerialization JSONObjectWithData:[mapData dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    NSArray *features = mapDataDict[@"features"];
    NSMutableArray *showData = [[NSMutableArray alloc] init];
    NSMutableArray *markPointData = [[NSMutableArray alloc] init];
    [features enumerateObjectsUsingBlock:^(NSDictionary *featureDict, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *properties = featureDict[@"properties"];
        NSString *name = properties[@"name"];
        NSMutableDictionary *showDataDict = [[NSMutableDictionary alloc] init];
        
        [showDataDict setObject:name ?: @"" forKey:@"name"];
        [showDataDict setObject:[NSNumber numberWithLong:(random()%1000)] forKey:@"value"];
        [showData addObject:showDataDict];
        
        NSArray *cp =  properties[@"cp"];
        NSMutableDictionary *markPointDataDict = [[NSMutableDictionary alloc] init];
        [markPointDataDict setObject:name ?: @"" forKey:@"name"];
        [markPointDataDict setObject:cp ?: @"" forKey:@"coord"];
        [markPointDataDict setObject:@"pin" forKey:@"symbol"];
        [markPointDataDict setObject:@"123\n122" forKey:@"value"];
        [markPointData addObject:markPointDataDict];
    }];
    [updateMapOption callWithArguments:@[self.mapName, showData, markPointData]];
    JSValue *loadMap = self.jsContext[@"loadMap"];
    [loadMap callWithArguments:@[self.mapName, mapData]];
}

- (NSString *)getAreaJsonDataWithAreaCode:(NSString *)code {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"china-main-city/%@.json",code] ofType:nil];
        NSError *error;
    NSString *jsonStr = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    return jsonStr;
}

- (UIWebView *)webView {
    if (!_webView) {
        _webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, kScreenW, kScreenW)];
        _webView.delegate = self;
//        _webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _webView.scalesPageToFit = YES;
        _webView.multipleTouchEnabled = YES;
        _webView.userInteractionEnabled = YES;
        _webView.scrollView.scrollEnabled = YES;
        _webView.contentMode = UIViewContentModeCenter;
        
    }
    return _webView;
}
@end
