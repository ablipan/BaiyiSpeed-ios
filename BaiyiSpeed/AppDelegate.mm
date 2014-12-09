//
//  AppDelegate.m
//  BaiyiSpeed
//
//  Created by Cooriyou on 14-8-26.
//  Copyright (c) 2014年 AILK. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Reachability.h"
#import "ASIHTTPRequest.h"
#import "Tools/MBProgressHUD.h"
#import "JSON.h"

BMKMapManager* _mapManager;
@interface AppDelegate()

@property( nonatomic ,strong) ASIHTTPRequest * request;
@property(nonatomic,strong)MBProgressHUD* HUD;
@property(nonatomic) NSString *update_url;
@end
@implementation AppDelegate

#define UPDATE_APP 100 //应用更新dialog


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // 要使用百度地图，请先启动BaiduMapManager
//	_mapManager = [[BMKMapManager alloc]init];
//	BOOL ret = [_mapManager start:@"wOj3jKXi5EWRjnowzYLyRmiU" generalDelegate:self];
//	if (!ret) {
//		NSLog(@"manager start failed!");
//	}
//    NSLog(@"%@",[AppDelegate getCellularProviderName]);
    [self checkVersion];
    return YES;
}

-(void)checkVersion
{
    // 查询基本信息
    NSURL *url = [NSURL URLWithString:@"http://fir.im/api/v2/app/version/540fb629cf3fdfc26a000113?token=jxhB4y7meAF0ENACYb3Hplqlt2jdRSmAngfvDDhy"];
    self.request = [ASIHTTPRequest requestWithURL:url];
    [self.request setDelegate:self];
    [self.request startAsynchronous];

}

+(NSDictionary* )getCellularProviderName
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc]init];
    CTCarrier*carrier = [netInfo subscriberCellularProvider];
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSLog(@"carrier:%@",carrier);
    NSMutableDictionary *imsi = nil;
    if (carrier!=NULL) {
        NSMutableDictionary *dic=[[NSMutableDictionary alloc] init];
        [dic setObject:[carrier carrierName] forKey:@"Carriername"];
        [dic setObject:[carrier mobileCountryCode] forKey:@"MobileCountryCode"];
//        [dic setObject:[carrier mobileNetworkCode]forKey:@"MobileNetworkCode"];
        [dic setObject:[carrier isoCountryCode] forKey:@"ISOCountryCode"];
        [dic setObject:[carrier allowsVOIP]?@"YES":@"NO" forKey:@"AllowsVOIP"];
        
        NSString * carrierStr = @"unknow";
        NSString * carrierParamKey = @"unknow";
        NSString * carrierName = @"unknow";
        if ([[carrier mobileNetworkCode] isEqualToString:@"01"] ||
            [[carrier mobileNetworkCode] isEqualToString:@"06"]) {
            carrierParamKey = @"cucNum";
            carrierStr = @"CUC";
            carrierName = @"联通";
        } else if ([[carrier mobileNetworkCode] isEqualToString:@"00"] ||
                   [[carrier mobileNetworkCode] isEqualToString:@"02"] ||
                   [[carrier mobileNetworkCode] isEqualToString:@"07"]) {
            carrierParamKey = @"cmcNum";
            carrierStr = @"CMC";
            carrierName = @"移动";
        } else if ([[carrier mobileNetworkCode] isEqualToString:@"03"] ||
                   [[carrier mobileNetworkCode] isEqualToString:@"05"] ||
                   [[carrier mobileNetworkCode] isEqualToString:@"20"]) {
            carrierParamKey = @"ctcNum";
            carrierStr = @"CTC";
            carrierName = @"电信";
        }
        [dic setObject:carrierStr forKey:@"carrierStr"];
        [dic setObject:carrierName forKey:@"carrierName"];
        [dic setObject:carrierParamKey forKey:@"carrierParamKey"];
        imsi = dic;
    }
    if(mainBundle!=nil)
    {
        //设备名称
        [imsi setObject:[[UIDevice currentDevice] systemName] forKey:@"deviceName"];
        //手机系统版本
        [imsi setObject:[[UIDevice currentDevice] systemVersion] forKey:@"phoneVersion"];
    }
    NSString *netType;
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    if ([telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyGPRS"]
        || [telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTTelephonyNetworkInfo.CTRadioAccessTechnologyEdge"]
        || [telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTTelephonyNetworkInfo.CTRadioAccessTechnologyCDMA1x"]
        ) {
        netType = @"2G";
    }else if([telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyGPRS"]
             ||[telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyWCDMA"]
             ||[telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyHSDPA"]
             ||[telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyHSUPA"]
             ||[telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]
             ||[telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]
             ||[telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]
             ||[telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyeHRPD"])
    {
         netType = @"3G";
    }else if([telephonyInfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyLTE"])
    {
        netType = @"4G";
    }else
    {
        netType = @"unknown";
    }
    [imsi setObject:netType forKey:@"netType"];
    return imsi;//cellularProviderName;
}

- (void)onGetNetworkState:(int)iError
{
    if (0 == iError) {
        NSLog(@"联网成功");
    }
    else{
        NSLog(@"onGetNetworkState %d",iError);
    }
    
}

- (void)onGetPermissionState:(int)iError
{
    if (0 == iError) {
        NSLog(@"授权成功");
    }
    else {
        NSLog(@"onGetPermissionState %d",iError);
    }
}


- (void)callTelphone{
    UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"是否需要拨打客服电话" message:@"186-0132-2635" delegate:self cancelButtonTitle:@"呼叫" otherButtonTitles:@"取消", nil];
    alertView.tag = 1001;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 1001) {
        if (buttonIndex == 0) {
            if ([self makeCall:@"18601322635"])
            {
                
            }
            else
            {
                NSString *msg=@"设备不支持电话功能";
                [self showSimpleAlertView:msg];
            }
            
        }
    } else if (alertView.tag == UPDATE_APP) { //更新应用
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.update_url]];
            exit(0);
        }
    }
}

// 打电话功能
- (BOOL) makeCall:(NSString *)phoneNumber
{
    if (phoneNumber==nil ||[phoneNumber isEqualToString:@""])
    {
        return NO;
    }
    BOOL call_ok = false;
    NSString * numberAfterClear = [phoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //NSURL *phoneNumberURL = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@", numberAfterClear]];
    NSURL *phoneNumberURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", numberAfterClear]];
    
    NSLog(@"make call, URL=%@", phoneNumberURL);
    
    call_ok = [[UIApplication sharedApplication] openURL:phoneNumberURL];
    
    return call_ok;
}


- (void)showSimpleAlertView:(NSString*)message
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"提示信息"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    [alert show];
}

+ (UIAlertView *) debugWithDialog:(NSString *)content
{
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"提示" message:content delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
    return alert;
}
+ (void) debugWithToast:(NSString *)content
{
    
}
// 获得基本url信息
+ (NSString *) getBaseUrl{
//    return @"http://124.207.3.10/EmplPortal/sets/speedtest/";
    return @"http://www.101test.com/sets/speedtest/";
}
// 是否wifi
+ (BOOL) isEnableWIFI {
    return ([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable);
}

// 是否3G
+ (BOOL) isEnable3G {
    return ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable);
}

+ (void)exitApplication {
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    UIWindow *window = app.window;
    
    [UIView animateWithDuration:1.0f animations:^{
        window.alpha = 0;
        window.frame = CGRectMake(0, window.bounds.size.width, 0, 0);
    } completion:^(BOOL finished) {
        exit(0);
    }];
    
}


#pragma mark Http请求事件
- (void)requestStarted:(ASIHTTPRequest *)request{
    NSLog(@"%@",@"requestStarted");
    
}

- (void)requestFailed:(ASIHTTPRequest *)request{
    NSLog(@"%@",request.error);
    [_HUD setLabelText:@"请求失败"];
    [_HUD hide:YES afterDelay:1];
}

- (void)requestFinished:(ASIHTTPRequest *)request{
    //    NSLog(@"%@",request.responseString);
    
    if (request.responseStatusCode == 404) {
        NSLog(@"%@",@"404");
        [_HUD setLabelText:@"404你懂得"];
        [_HUD hide:YES afterDelay:1];
    } else {
        NSString * respStr = request.responseString;
        NSDictionary * dict = [respStr JSONValue];
        NSLog(@"RET:\n%@",dict);
        double version = [[dict objectForKey:@"version"] doubleValue];
        double currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey] doubleValue];
        if (version != 0) {
            if ( currentVersion < version) {
                self.update_url = [dict objectForKey:@"update_url"];
                UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"应用更新" message:@"有新的版本啦，请点击更新去下载新版本!" delegate:self cancelButtonTitle:@"更新" otherButtonTitles: nil];
                alert.tag = UPDATE_APP;
                [alert show];
            }
        }
    }
}

@end
