//
//  AppDelegate.h
//  BaiyiSpeed
//
//  Created by Cooriyou on 14-8-26.
//  Copyright (c) 2014年 AILK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, BMKGeneralDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString *downloadUrl;
@property (strong, nonatomic) NSString *uploadUrl;
@property (strong, nonatomic) NSString *comments;
@property (nonatomic)NSInteger formulaNum;
@property (nonatomic)NSInteger signalTester;
@property (strong, nonatomic) NSArray *addressList;
@property (nonatomic)NSInteger addressId;
@property (nonatomic)NSInteger seatNumber;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSString *college;

@property(nonatomic) NSInteger signal;
@property(nonatomic) NSInteger speed;

@property(nonatomic) BOOL hasAlerted;

- (void)callTelphone;
+ (NSDictionary* )getCellularProviderName;

+ (UIAlertView *)  debugWithDialog:(NSString *)content; //用作调试时输出文本...
+ (void) debugWithToast:(NSString *)content; //用作调试时输出文本...
+ (NSString *) getBaseUrl;
+ (void)exitApplication;
// 是否wifi
+ (BOOL) isEnableWIFI;
// 是否3G
+ (BOOL) isEnable3G;
@end
