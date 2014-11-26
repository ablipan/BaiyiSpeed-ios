//
//  TestViewController.m
//  BaiyiSpeed
//
//  Created by Cooriyou on 14-8-29.
//  Copyright (c) 2014年 AILK. All rights reserved.
//

#import "TestViewController.h"
#import "AFURLConnectionByteSpeedMeasure.h"
#import "AFURLConnectionOperation+AFURLConnectionByteSpeedMeasure.h"
#import "AFHTTPRequestOperation.h"
#include <dlfcn.h>
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "AppDelegate.h"
#import "Tools/MBProgressHUD.h"
#import "JSON.h"

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UIView *vContent; //
@property (weak,nonatomic) IBOutlet UILabel *comments;  // 提示信息
@property (weak, nonatomic) IBOutlet UIButton *btnBeginTest; //开始测速按钮
@property (weak, nonatomic) IBOutlet UIButton *endTest; // 关闭测速

//@property (weak, nonatomic) IBOutlet UIButton *btnNextTest;
//@property (weak, nonatomic) IBOutlet UILabel *lbSignalStrength;
//@property (weak, nonatomic) IBOutlet UILabel *lbWide;

@property( nonatomic ,strong) ASIHTTPRequest * request;

@property(nonatomic,strong)MBProgressHUD* HUD;
@property(atomic, strong) NSArray * downOpeartions;

@property (nonatomic) double total;
@property (nonatomic) NSInteger count;
@property (nonatomic) NSInteger Signal;
@property (nonatomic,strong)NSMutableArray* retList;

@property (nonatomic) NSInteger nowPoint;


@property(nonatomic, strong) NSMutableArray * operationSpeedList;
@property(nonatomic, strong) NSMutableArray * operationSpeedList2;
@property(nonatomic, strong) NSMutableArray * operationSpeedList3;
@property(nonatomic, strong) NSMutableArray * operationSpeedList4;

@property(nonatomic) BOOL isTesting; //是否正在测速
//@property(nonatomic) BOOL testIsDone; //测速已完成；防止重复提交测速结果

@property(nonatomic) double beginTime; //测速开始时间
@property(nonatomic) double endTime; //测速结束时间

#define SUBMIT_RESULT 100 //提交测速结果标识
#define SUBMIT_LOG 101 //提交日志标识

@property(nonatomic)NSMutableData *logData; //上传日志信息...

@end

@implementation TestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_HUD hide:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 禁用 iOS7 返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    _nowPoint = 0;
    self.retList = [NSMutableArray array];
    if ([[[UIDevice currentDevice]systemVersion]floatValue] < 7.0){
        _vContent.frame = CGRectMake(_vContent.frame.origin.x , _vContent.frame.origin.y - 72, _vContent.frame.size.width,  _vContent.frame.size.height) ;
       
    }
    NSLog(@"信号强度:%i", getSignalStrength());
    _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_HUD];
    [self.endTest setHidden:YES]; // 隐藏完成测速按钮
    
    
    // 替换自带的返回按钮
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 20, 44);
    
    [backBtn setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(doBack:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = backItem;
}

-(void)doBack:(id)sender
{
    if(!self.isTesting)
    {
        [self.navigationController popViewControllerAnimated:YES];

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 开始测速
- (IBAction)doTest:(id)sender{
    if (!self.isTesting) {
        self.isTesting = YES;
        [self downloadTest2];
    }
}

// 测速完成
- (void) testDone
{
    if (self.isTesting) {
        self.isTesting = NO;
        NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_nowPoint],@"point",[NSNumber numberWithInt:_Signal],@"signal",[NSNumber numberWithInt:_total],@"speed", nil];
        [self.retList addObject:dic];
        [self uploadResult];
    }
}


// 关闭
- (IBAction)doTestClose:(id)sender{
    [self.navigationController popViewControllerAnimated:NO];
}

// 上传测速结果
- (void)uploadResult{
    if (_retList.count > 0 ) {
        NSInteger signal_t = 0;
        NSInteger speed_t = 0;
        for (NSDictionary *dic in _retList) {
            signal_t += [(NSNumber *)[dic objectForKey:@"signal"]intValue];
            speed_t += [(NSNumber *)[dic objectForKey:@"speed"]intValue];
        }
        AppDelegate *app = [[UIApplication sharedApplication]delegate];
        app.signal = (signal_t/(NSInteger)[_retList count]);
        app.speed = (speed_t/[_retList count]);
        
        NSDictionary * cellularInfoDict = [AppDelegate getCellularProviderName];
//        NSString * networkCode = [cellularInfoDict objectForKey:@"MobileNetworkCode"];
        NSString * deviceName = [cellularInfoDict objectForKey:@"deviceName"];
        NSString * phoneVersion = [cellularInfoDict objectForKey:@"phoneVersion"];
        NSString * netType = [cellularInfoDict objectForKey:@"netType"];
        NSString * networkParaStr = [cellularInfoDict objectForKey:@"carrierParamKey"];
        NSString * carrierStr = [cellularInfoDict objectForKey:@"carrierStr"];
        NSURL *url = [NSURL URLWithString:[[AppDelegate getBaseUrl]stringByAppendingString:@"uploadResult"]];
        
        // \"signalStrength\": %d\
        
        NSMutableString * info = nil;
        info = [NSMutableString stringWithFormat:@"{\
                \"addressId\": %d,\
                \"%@\": %d\
                }",
                app.addressId,
                networkParaStr,
                app.speed
                ];
        NSDictionary * infoDict = [info JSONValue];
        NSMutableData *tempJsonData = nil;
        if ([NSJSONSerialization isValidJSONObject:infoDict])
        {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict options:NSJSONWritingPrettyPrinted error: &error];
            tempJsonData = [NSMutableData dataWithData:jsonData];
            
            NSLog(@"%@",[[NSString alloc]initWithData:tempJsonData encoding:NSUTF8StringEncoding]);
        }
        
        self.request = [ASIHTTPRequest requestWithURL:url];
        [self.request setDelegate:self];
        [self.request addRequestHeader:@"Content-Type" value:@"application/json; encoding=utf-8"];
        [self.request addRequestHeader:@"Accept" value:@"application/json"];
        [self.request setRequestMethod:@"POST"];
        [self.request setTag:SUBMIT_RESULT];
        [self.request setPostBody:tempJsonData];
        [self.request startAsynchronous];
        _HUD.labelText = @"正在提交测速结果...";
        [_HUD show:YES];
        
        // 测速日志json准备...
        
        self.endTime = [[NSDate date] timeIntervalSince1970]*1000;
        NSMutableString * log = nil;
        log = [NSMutableString stringWithFormat:@"[{\
               \"addressId\": %d,\
               \"phone_nbr\": -1,\
               \"phone_type\": \"%@\",\
               \"carrier\": \"%@\",\
               \"net_type\": \"%@\",\
               \"signal_strength\": %d,\
               \"download\": %d,\
               \"upload\": -1,\
               \"begin_time\": %f,\
               \"end_time\": %f\
               }]",
               app.addressId,
               [deviceName stringByAppendingString:phoneVersion],
               carrierStr,
               netType,
               app.signal,
               app.speed,
               self.beginTime,
               self.endTime
               ];
        NSDictionary * logDict = [log JSONValue];
//        NSMutableData * logJsonData = nil;
        if ([NSJSONSerialization isValidJSONObject:logDict])
        {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:logDict options:NSJSONWritingPrettyPrinted error: &error];
            self.logData = [NSMutableData dataWithData:jsonData];
            NSLog(@"%@",[[NSString alloc]initWithData:self.logData encoding:NSUTF8StringEncoding]);
        }
    }
}

-(void) uploadLog
{
    NSURL *url = [NSURL URLWithString:[[AppDelegate getBaseUrl]stringByAppendingString:@"uploadLogs"]];
    self.request = [ASIHTTPRequest requestWithURL:url];
    [self.request setDelegate:self];
    [self.request addRequestHeader:@"Content-Type" value:@"application/json; encoding=utf-8"];
    [self.request addRequestHeader:@"Accept" value:@"application/json"];
    [self.request setRequestMethod:@"POST"];
    [self.request setTag:SUBMIT_LOG];
    [self.request setPostBody:self.logData];
    [self.request startAsynchronous];
}

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
    
    if (request.tag == 1001) {
        if (request.responseStatusCode == 404) {
            NSLog(@"%@",@"404");
            [_HUD setLabelText:@"404你懂得"];
        } else {
            //request.timeOutSeconds
        }
    }
    if (request.responseStatusCode == 404) {
        NSLog(@"%@",@"404");
        [_HUD setLabelText:@"404你懂得"];
    } else {
        if (request.tag == SUBMIT_RESULT) {
            NSString * respStr = request.responseString;
            NSDictionary * dict = [respStr JSONValue];
            NSLog(@"RET:\n%@",dict);
            NSNumber * code = [dict objectForKey:@"code"];
            if ([code intValue] == 0) {
                NSDictionary* data = [dict objectForKey:@"data"];
                NSNumber * errorcode = [data objectForKey:@"errorCode"];
                NSNumber *num = [data objectForKey:@"num"];
                if ([errorcode intValue] == 0) {  // success
                    [_HUD setLabelText:@"测速结果提交成功"];
                    NSString * carrierStr = [[AppDelegate getCellularProviderName] objectForKey:@"carrierStr"];
                    NSString * carrierName = [[AppDelegate getCellularProviderName] objectForKey:@"carrierName"];
                    AppDelegate *app = [[UIApplication sharedApplication]delegate];
                    if (num.intValue != 0) {
                        [self.comments setText:[NSString stringWithFormat: @"测速完成! %@带宽为 %d KB/s，考场可考试人数为 %d 人",carrierName,app.speed,num.intValue]];
                    }else
                    {
//                        测速完成! 移动带宽为 200 KB/s，欲知考场可考试人数，请用联通手机完成测试。
                        if ([carrierStr isEqualToString:@"CMC"]) {
                            [self.comments setText:[NSString stringWithFormat: @"测速完成! %@带宽为 %d KB/s，欲知考场可考试人数，请用 %@ 手机完成测试。",carrierName,app.speed,@"联通"]];
                        }else if([carrierStr isEqualToString:@"CUC"])
                        {
                          [self.comments setText:[NSString stringWithFormat: @"测速完成! %@带宽为 %d KB/s，欲知考场可考试人数，请用 %@ 手机完成测试。",carrierName,app.speed,@"移动"]];
                        }else if([carrierStr isEqualToString:@"CTC"])
                        {
                          [self.comments setText:[NSString stringWithFormat: @"测速完成! %@带宽为 %d KB/s，欲知考场可考试人数，请用 %@ 手机完成测试。",carrierName,app.speed,@"移动和联通"]];
                        }else{
                            [self.comments setText:[NSString stringWithFormat: @"测速完成! %@带宽为 %d KB/s，由于运营商类型未知，未保存测速结果！",carrierName,app.speed]];
                        }
                    }
                    [self.endTest setHidden:NO]; // 显式关闭按钮
                    [self.btnBeginTest setHidden:YES]; // 隐藏开始测速按钮
                    [self uploadLog];
                    //                [self performSegueWithIdentifier:@"pushResult" sender:self.btnNextTest];
                }else{
                    [_HUD setLabelText:[NSString stringWithFormat:@"测速结果提交失败，code = %d",[errorcode intValue]]];
                }
            }else{
                [_HUD setLabelText:@"测速结果提交失败"];
            }
            [_HUD hide:YES afterDelay:1];
        }else if(request.tag == SUBMIT_LOG)
        {
            
        }
    }
}

#pragma mark - Test Action

// 获取信号强度
int getSignalStrength()
{
	void *libHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
	int (*CTGetSignalStrength)();
	CTGetSignalStrength = dlsym(libHandle, "CTGetSignalStrength");
	if( CTGetSignalStrength == NULL) NSLog(@"Could not find CTGetSignalStrength");
	int result = CTGetSignalStrength();
	dlclose(libHandle);
	return result;
}

// 上传速度测速
- (void)uploadTest{
    
    /* 1、上传请求创建 */
    NSError * err = nil;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:@"http://cesu.qscm.net/speedtestsvr/testupload.php" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"bin"];
        NSError * error = nil;
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:imagePath] name:@"file" fileName:@"filename.pdf" mimeType:@"image/png" error:&error];
        NSLog(@"%@",error);
    } error:&err];
    NSLog(@"%@",err);
    
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    __weak  AFHTTPRequestOperation *operationSet = operation;

    operation.uploadSpeedMeasure.active = YES;
    
    /* 2、上传完成后Block回调 */
    [operation setCompletionBlock:^(void){
        NSLog(@"%@",@"OKOK!");
    }];
    
    /* 3、上传进行时Block回调 */
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpected){
//        double speedInBytesPerSecond = operation.uploadSpeedMeasure.speed;
        NSString *humanReadableSpeed = operationSet.uploadSpeedMeasure.humanReadableSpeed;
        
//        NSTimeInterval remainingTimeInSeconds = [operation.uploadSpeedMeasure remainingTimeOfTotalSize:totalBytesExpected numberOfCompletedBytes:totalBytesWritten];
        NSString *humanReadableRemaingTime = [operationSet.uploadSpeedMeasure humanReadableRemainingTimeOfTotalSize:totalBytesExpected numberOfCompletedBytes:totalBytesWritten];
        
        NSLog(@"UP humanReadableSpeed:%@, humanReadableRemaingTime:%@", humanReadableSpeed, humanReadableRemaingTime);
    }];
    [operation start];
    
}

-(NSMutableArray *) bubble_sort:(NSMutableArray *) arr_source {
    if([arr_source count] <= 1) {
        return arr_source;
    }
    int i;
    int j;
    int length = [arr_source count];
    NSNumber * l_1;
    NSNumber * l_2;
    
    NSMutableArray *tmp_source = [[NSMutableArray alloc] init];
    
    for(j = 0; j < length; j++) {
        for(i = 1; i < length - j; i++) {
            l_1 = [arr_source objectAtIndex:i-1] ;
            l_2 = [arr_source objectAtIndex:i] ;
            if(l_1.doubleValue < l_2.doubleValue) {
                [tmp_source addObject:l_1];
                [tmp_source addObject:l_2];
            } else {
                [tmp_source addObject:l_2];
                [tmp_source addObject:l_1];
            }
        }
    }
    
    return tmp_source;
}

- (double)speedGetOf:(NSMutableArray *)arr{
    double realSpeed = 0;
    
//    if (arr.count < 50) {
//        return 1;
//    }

    NSMutableArray *sortedArray = [NSMutableArray arrayWithArray:arr];
    
//    [sortedArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//        //这里的代码可以参照上面compare:默认的排序方法，也可以把自定义的方法写在这里，给对象排序
//        NSComparisonResult result = [obj1 compare:obj2];
//        return result;
//    }];
    NSSortDescriptor *mySorter = [[NSSortDescriptor alloc] initWithKey:@"doubleValue" ascending:NO];
    [sortedArray sortUsingDescriptors:[NSArray arrayWithObject:mySorter]];
    //sortedArray = [self bubble_sort:sortedArray];
    
    NSLog(@"%@", sortedArray);
    
    long count = sortedArray.count;
    
    long beginIndex = count * 0.3;
    long endIndex = count * 0.7;
    
    NSMutableArray * lastArr = [NSMutableArray arrayWithCapacity:0];
    for (long i = beginIndex; i < endIndex; i ++) {
        [lastArr addObject:[sortedArray objectAtIndex:i]];
    }
    NSLog(@"%@", lastArr);
    
    double allSpeeds = 0;
    for (NSNumber * str in lastArr) {
        allSpeeds += [str doubleValue];
    }
    
    realSpeed = allSpeeds / lastArr.count;
    NSLog(@"allSpeeds:%f,lastArr.count:%i",allSpeeds, (int)lastArr.count);
    if (lastArr.count == 0) {
        NSLog(@"the arr:%@",arr);
        return 0;
    }
    return realSpeed;
}

- (void)downloadTest2{
    _HUD.labelText = @"测速预计需要3分钟, 请稍等...";
    self.beginTime = [[NSDate date] timeIntervalSince1970]*1000;
//    [self.comments setText:@"测速预计需要3分钟, 请稍等..."];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [_HUD show:YES];
    __block double line1Speed = 0;
    __block double line1Count = 0;
    __block double line2Speed = 0;
    __block double line2Count = 0;
    __block double line3Speed = 0;
    __block double line3Count = 0;
    __block double line4Speed = 0;
    __block double line4Count = 0;
    self.operationSpeedList = [NSMutableArray arrayWithCapacity:0];
    __weak NSMutableArray * opSpeedList = self.operationSpeedList;
    self.operationSpeedList2 = [NSMutableArray arrayWithCapacity:0];
    __weak NSMutableArray * opSpeedList2 = self.operationSpeedList2;
    self.operationSpeedList3 = [NSMutableArray arrayWithCapacity:0];
    __weak NSMutableArray * opSpeedList3 = self.operationSpeedList3;
    self.operationSpeedList4 = [NSMutableArray arrayWithCapacity:0];
    __weak NSMutableArray * opSpeedList4 = self.operationSpeedList4;
    __weak id accessSelf = self;
    __block double line5Speed = 0;
    __block double line5Count = 0;
    __block double line6Speed = 0;
    __block double line6Count = 0;
    __block double line7Speed = 0;
    __block double line7Count = 0;
    __block double line8Speed = 0;
    __block double line8Count = 0;
    __block double line9Speed = 0;
    __block double line9Count = 0;
    __block double line10Speed = 0;
    __block double line10Count = 0;
    __block int endCount = 0;
    
    /* 1、下载请求创建 */
    AppDelegate *app = (AppDelegate* )[[UIApplication sharedApplication]delegate];
    NSString* url = app.downloadUrl;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFHTTPRequestOperation *operation1 = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    __weak  AFHTTPRequestOperation *operationSet = operation1;
    operation1.downloadSpeedMeasure.active = YES;
    
    /* 3、下载进行时Block回调 */
    [operation1 setCompletionBlock:^(void){
        NSLog(@"%@",@"Download finish [1]!");
        @synchronized(self){
            endCount++;
            if (endCount == 1) {
                line10Count = line10Count == 0 ? 1:line10Count;
                line9Count = line9Count == 0 ? 1:line9Count;
                line8Count = line8Count == 0 ? 1:line8Count;
                line7Count = line7Count == 0 ? 1:line7Count;
                line6Count = line6Count == 0 ? 1:line6Count;
                line5Count = line5Count == 0 ? 1:line5Count;
                line4Count = line4Count == 0 ? 1:line4Count;
                line3Count = line3Count == 0 ? 1:line3Count;
                line2Count = line2Count == 0 ? 1:line2Count;
                line1Count = line1Count == 0 ? 1:line1Count;
                for (AFHTTPRequestOperation * op in self.downOpeartions) {
                    if (op != operationSet) {

                        [op cancel];
                    }
                }
                self.downOpeartions = nil;
                double speed ;//= (line1Speed / line1Count * 1) + (line2Speed / line2Count * 1) + (line3Speed / line3Count * 1) + (line4Speed / line4Count * 1) ;// + (line5Speed / line5Count * 1) + (line6Speed / line6Count * 1) + (line7Speed / line7Count * 1)  + (line8Speed / line8Count * 1) + (line9Speed / line9Count * 1) + (line10Speed / line10Count * 1);
                speed = [accessSelf speedGetOf:opSpeedList] + [accessSelf speedGetOf:opSpeedList2] + [self speedGetOf:opSpeedList3] +[self speedGetOf:opSpeedList4];
                _total = speed;
                _count = 1;
                int n =getSignalStrength();
                _Signal = n/2 -104;
                _HUD.labelText = @"测速完成";
                [self testDone];
            }
        }
        
    }];

    /* 2、下载进行时Block回调 */
    [operation1 setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"Download begin [1]");
        NSString *humanReadableSpeed = operationSet.downloadSpeedMeasure.humanReadableSpeed;
        NSString *humanReadableRemaingTime = [operationSet.downloadSpeedMeasure humanReadableRemainingTimeOfTotalSize:totalBytesExpectedToRead numberOfCompletedBytes:totalBytesRead];
        
        NSLog(@"DOWN Speed:%@, RemaingTime:%@", humanReadableSpeed, humanReadableRemaingTime);
        if ([humanReadableSpeed intValue] != 0) {
            
            double curSpeed = [humanReadableSpeed doubleValue];
            if ([humanReadableSpeed rangeOfString:@"MB"].length > 0) {
                curSpeed = curSpeed * 1024;
            } else if([humanReadableSpeed rangeOfString:@"GB"].length > 0) {
                curSpeed = curSpeed * 1024 * 1024;
            }
            if (![operationSet isCancelled]) {
                [opSpeedList addObject:[NSNumber numberWithDouble:curSpeed]];
                line1Speed += curSpeed;
                line1Count ++;
            }
        }
        
    }];
    
    //[operation1 start];
    
    
   ////////   Line 2 ///////
    
    
    AFHTTPRequestOperation *operation2 = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    __weak  AFHTTPRequestOperation *operationSet2 = operation2;
    operation2.downloadSpeedMeasure.active = YES;
    [operation2 setCompletionBlock:^(void){
        NSLog(@"%@",@"Download finish [2]!");
        @synchronized(self){
            endCount++;
            if (endCount == 1) {
                line10Count = line10Count == 0 ? 1:line10Count;
                line9Count = line9Count == 0 ? 1:line9Count;
                line8Count = line8Count == 0 ? 1:line8Count;
                line7Count = line7Count == 0 ? 1:line7Count;
                line6Count = line6Count == 0 ? 1:line6Count;
                line5Count = line5Count == 0 ? 1:line5Count;
                line4Count = line4Count == 0 ? 1:line4Count;
                line3Count = line3Count == 0 ? 1:line3Count;
                line2Count = line2Count == 0 ? 1:line2Count;
                line1Count = line1Count == 0 ? 1:line1Count;
                for (AFHTTPRequestOperation * op in self.downOpeartions) {
                    if (op != operationSet2) {

                        [op cancel];
                    }
                }
                self.downOpeartions = nil;
                double speed = 0 ;//= (line1Speed / line1Count * 1) + (line2Speed / line2Count * 1);// + (line3Speed / line3Count * 1) + (line4Speed / line4Count * 1) ;// + (line5Speed / line5Count * 1) + (line6Speed / line6Count * 1) + (line7Speed / line7Count * 1)  + (line8Speed / line8Count * 1) + (line9Speed / line9Count * 1) + (line10Speed / line10Count * 1);
                speed = [accessSelf speedGetOf:opSpeedList] + [accessSelf speedGetOf:opSpeedList2] + [self speedGetOf:opSpeedList3] +[self speedGetOf:opSpeedList4];
                _total = speed;
                _count = 1;
                int n =getSignalStrength();
                _Signal = n/2 -104;
                _HUD.labelText = @"测速完成";
                [self testDone];
            }
        }
        
    }];
    [operation2 setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"Download begin [2]");
        NSString *humanReadableSpeed = operationSet2.downloadSpeedMeasure.humanReadableSpeed;
        NSString *humanReadableRemaingTime = [operationSet2.downloadSpeedMeasure humanReadableRemainingTimeOfTotalSize:totalBytesExpectedToRead numberOfCompletedBytes:totalBytesRead];
        
        NSLog(@"DOWN humanReadableSpeed:%@, humanReadableRemaingTime:%@", humanReadableSpeed, humanReadableRemaingTime);
        if ([humanReadableSpeed intValue] != 0) {
            
            double curSpeed = [humanReadableSpeed doubleValue];
            if ([humanReadableSpeed rangeOfString:@"MB"].length > 0) {
                curSpeed = curSpeed * 1024;
            } else if([humanReadableSpeed rangeOfString:@"GB"].length > 0) {
                curSpeed = curSpeed * 1024 * 1024;
            }
            if (![operationSet2 isCancelled]) {
                [opSpeedList2 addObject:[NSNumber numberWithDouble:curSpeed]];
                line2Speed += curSpeed;
                line2Count ++;
            }
        }
        
    }];

//    [operation2 start];
    
    
    ////////   Line 3 ///////
    AFHTTPRequestOperation *operation3 = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    __weak  AFHTTPRequestOperation *operationSet3 = operation3;
    operation3.downloadSpeedMeasure.active = YES;
    [operation3 setCompletionBlock:^(void){
        NSLog(@"%@",@"Download finish [3]!");
        @synchronized(self){
            endCount++;
            if (endCount == 1) {
                line10Count = line10Count == 0 ? 1:line10Count;
                line9Count = line9Count == 0 ? 1:line9Count;
                line8Count = line8Count == 0 ? 1:line8Count;
                line7Count = line7Count == 0 ? 1:line7Count;
                line6Count = line6Count == 0 ? 1:line6Count;
                line5Count = line5Count == 0 ? 1:line5Count;
                line4Count = line4Count == 0 ? 1:line4Count;
                line3Count = line3Count == 0 ? 1:line3Count;
                line2Count = line2Count == 0 ? 1:line2Count;
                line1Count = line1Count == 0 ? 1:line1Count;
                for (AFHTTPRequestOperation * op in self.downOpeartions) {
                    if (op != operationSet3) {

                        [op cancel];
                    }
                }
                self.downOpeartions = nil;
                double speed = 0 ;// (line1Speed / line1Count * 1) + (line2Speed / line2Count * 1) + (line3Speed / line3Count * 1) + (line4Speed / line4Count * 1)  ;//+ (line5Speed / line5Count * 1) + (line6Speed / line6Count * 1) + (line7Speed / line7Count * 1)  + (line8Speed / line8Count * 1) + (line9Speed / line9Count * 1) + (line10Speed / line10Count * 1);
                speed = [accessSelf speedGetOf:opSpeedList] + [accessSelf speedGetOf:opSpeedList2] + [accessSelf speedGetOf:opSpeedList3] +[accessSelf speedGetOf:opSpeedList4];
                
                _total = speed;
                _count = 1;
                int n =getSignalStrength();
                _Signal = n/2 -104;
                _HUD.labelText = @"测速完成";
                [self testDone];
            }
        }
        
    }];
    [operation3 setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"Download begin [3]");
        NSString *humanReadableSpeed = operationSet3.downloadSpeedMeasure.humanReadableSpeed;
        NSString *humanReadableRemaingTime = [operationSet3.downloadSpeedMeasure humanReadableRemainingTimeOfTotalSize:totalBytesExpectedToRead numberOfCompletedBytes:totalBytesRead];
        
        NSLog(@"DOWN humanReadableSpeed:%@, humanReadableRemaingTime:%@", humanReadableSpeed, humanReadableRemaingTime);
        if ([humanReadableSpeed intValue] != 0) {
            
            double curSpeed = [humanReadableSpeed doubleValue];
            if ([humanReadableSpeed rangeOfString:@"MB"].length > 0) {
                curSpeed = curSpeed * 1024;
            } else if([humanReadableSpeed rangeOfString:@"GB"].length > 0) {
                curSpeed = curSpeed * 1024 * 1024;
            }
            if (![operationSet3 isCancelled]) {
                [opSpeedList3 addObject:[NSNumber numberWithDouble:curSpeed]];
                line3Speed += curSpeed;
                line3Count ++;}
        }
        
    }];
    
   // [operation3 start];
    
    ////////   Line 4 ///////
    AFHTTPRequestOperation *operation4 = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    __weak  AFHTTPRequestOperation *operationSet4 = operation4;
    operation4.downloadSpeedMeasure.active = YES;
    [operation4 setCompletionBlock:^(void){
        NSLog(@"%@",@"Download finish [4]!");
        @synchronized(self){
            endCount++;
            if (endCount == 1) {
                line10Count = line10Count == 0 ? 1:line10Count;
                line9Count = line9Count == 0 ? 1:line9Count;
                line8Count = line8Count == 0 ? 1:line8Count;
                line7Count = line7Count == 0 ? 1:line7Count;
                line6Count = line6Count == 0 ? 1:line6Count;
                line5Count = line5Count == 0 ? 1:line5Count;
                line4Count = line4Count == 0 ? 1:line4Count;
                line3Count = line3Count == 0 ? 1:line3Count;
                line2Count = line2Count == 0 ? 1:line2Count;
                line1Count = line1Count == 0 ? 1:line1Count;
                for (AFHTTPRequestOperation * op in self.downOpeartions) {
                    if (op != operationSet4) {
                        [op cancel];
                    }
                    
                }
                self.downOpeartions = nil;
                double speed = 0;//(line1Speed / line1Count * 1) + (line2Speed / line2Count * 1) + (line3Speed / line3Count * 1) + (line4Speed / line4Count * 1);//  + (line5Speed / line5Count * 1) + (line6Speed / line6Count * 1) + (line7Speed / line7Count * 1)  + (line8Speed / line8Count * 1) + (line9Speed / line9Count * 1) + (line10Speed / line10Count * 1);
                speed = [accessSelf speedGetOf:opSpeedList] + [accessSelf speedGetOf:opSpeedList2] + [accessSelf speedGetOf:opSpeedList3] +[accessSelf speedGetOf:opSpeedList4];
                _total = speed;
                _count = 1;
                int n =getSignalStrength();
                _Signal = n/2 -104;
                _HUD.labelText = @"测速完成";
                [self testDone];
            }
        }
        
    }];
    [operation4 setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"Download begin [4]");
        NSString *humanReadableSpeed = operationSet4.downloadSpeedMeasure.humanReadableSpeed;
        NSString *humanReadableRemaingTime = [operationSet4.downloadSpeedMeasure humanReadableRemainingTimeOfTotalSize:totalBytesExpectedToRead numberOfCompletedBytes:totalBytesRead];
        
        NSLog(@"DOWN humanReadableSpeed:%@, humanReadableRemaingTime:%@", humanReadableSpeed, humanReadableRemaingTime);
        if ([humanReadableSpeed intValue] != 0) {
            
            double curSpeed = [humanReadableSpeed doubleValue];
            if ([humanReadableSpeed rangeOfString:@"MB"].length > 0) {
                curSpeed = curSpeed * 1024;
            } else if([humanReadableSpeed rangeOfString:@"GB"].length > 0) {
                curSpeed = curSpeed * 1024 * 1024;
            }
            if (![operationSet4 isCancelled]) {
                [opSpeedList4 addObject:[NSNumber numberWithDouble:curSpeed]];
                line4Speed += curSpeed;
                line4Count ++;}
        }
        
    }];
    self.downOpeartions = [NSArray arrayWithObjects:operation1, operation2, operation3, operation4, nil];

    [operation1 start];
    [operation2 start];
    [operation3 start];
    [operation4 start];
}

+(NSDictionary* )getCellularProviderName
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc]init];
    CTCarrier*carrier = [netInfo subscriberCellularProvider];

    NSLog(@"carrier:%@",carrier);
    NSDictionary *imsi = nil;
    if (carrier!=NULL) {
        NSMutableDictionary *dic=[[NSMutableDictionary alloc] init];
        [dic setObject:[carrier carrierName] forKey:@"Carriername"];
        [dic setObject:[carrier mobileCountryCode] forKey:@"MobileCountryCode"];
        [dic setObject:[carrier mobileNetworkCode]forKey:@"MobileNetworkCode"];
        [dic setObject:[carrier isoCountryCode] forKey:@"ISOCountryCode"];
        [dic setObject:[carrier allowsVOIP]?@"YES":@"NO" forKey:@"AllowsVOIP"];
        imsi = dic;
    }
    return imsi;//cellularProviderName;
}
- (IBAction)callTelphone:(id)sender {
    if (!self.isTesting) {
        [((AppDelegate *)[UIApplication sharedApplication].delegate) callTelphone];
    }
}

@end
