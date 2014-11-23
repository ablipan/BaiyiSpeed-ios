//
//  ViewController.m
//  BaiyiSpeed
//
//  Created by Cooriyou on 14-8-26.
//  Copyright (c) 2014年 AILK. All rights reserved.
//

#import "ViewController.h"
#import "ASIHTTPRequest.h"
#import "AppDelegate.h"
#import "Tools/MBProgressHUD.h"
#import "JSON.h"

#define INIT   100
#define LOGIN  101



@interface ViewController ()<ASIHTTPRequestDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txUserName;
@property (weak, nonatomic) IBOutlet UITextField *txPassword;
@property (weak, nonatomic) IBOutlet UIControl *vContent;

@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property( nonatomic ,strong) ASIHTTPRequest * request;
@property(nonatomic,strong)MBProgressHUD* HUD;
@property(nonatomic)BOOL isInit;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    if ([[[UIDevice currentDevice]systemVersion]floatValue] < 7.0){
        _vContent.frame = CGRectMake(_vContent.frame.origin.x , _vContent.frame.origin.y - 72, _vContent.frame.size.width,  _vContent.frame.size.height) ;
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavBar6"] forBarMetrics:UIBarMetricsDefault];
    }else{
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavBar"] forBarMetrics:UIBarMetricsDefault];
    }
    
    _isInit = NO;
    [self doInit];
    
}


- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_HUD hide:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)doInit
{
    _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_HUD];
    NSURL *url = [NSURL URLWithString:@"http://www.101test.com/sets/speedtest/getBasicInfo"];
    self.request = [ASIHTTPRequest requestWithURL:url];
    [self.request setDelegate:self];
    [self.request setTag:INIT];
    [self.request startAsynchronous];
    _HUD.labelText = @"初始化中，请稍后";
    [_HUD show:YES];
    return;
}

-(IBAction)login:(id)sender
{
//
    if ([_txUserName.text length] == 0 ||
        [_txPassword.text length] == 0) {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"输入框内容不能为空" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return ;
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.101test.com/sets/speedtest/checkPassport/%@",self.txPassword.text]];
    self.request = [ASIHTTPRequest requestWithURL:url];
    [self.request setDelegate:self];
    [self.request setTag:LOGIN];
    [self.request startAsynchronous];
    _HUD.labelText = @"登录中，请稍后";
    [_HUD show:YES];
}


-(IBAction)backgroundTap:(id)sender
{
    [_txUserName resignFirstResponder];
    [_txPassword resignFirstResponder];
}
- (IBAction)callTelphone:(id)sender {
    //[AppDelegate callTelphone];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) callTelphone];
}

- (void)requestStarted:(ASIHTTPRequest *)request{
    NSLog(@"%@",@"requestStarted");
    
}

- (void)requestFailed:(ASIHTTPRequest *)request{
    NSLog(@"%@",request.error);
    if (request.tag == INIT) {
        _isInit = NO;
    }
    [_HUD setLabelText:@"请求失败"];
    [_HUD hide:YES afterDelay:1];
}

- (void)requestFinished:(ASIHTTPRequest *)request{
//    NSLog(@"%@",request.responseString);
    
    if (request.responseStatusCode == 404) {
        NSLog(@"%@",@"404");
        if (request.tag == INIT) {
            _isInit = NO;
        }
        [_HUD setLabelText:@"404你懂得"];
    } else {
        
        if (request.tag == INIT) { // init
            NSString * respStr = request.responseString;
            NSDictionary * dict = [respStr JSONValue];
            NSLog(@"RET:\n%@",dict);
            NSNumber * errorcode = [dict objectForKey:@"code"];
            
            if ([errorcode intValue] == 0) {   // init success
                
                [_HUD setLabelText:@"初始化成功"];
                _isInit = YES;
                NSDictionary* data = [dict objectForKey:@"data"];
                AppDelegate* app = [[UIApplication sharedApplication]delegate];
                app.downloadUrl = [data objectForKey:@"downloadUrl"];
                app.uploadUrl = [data objectForKey:@"uploadUrl"];
                app.comments = [data objectForKey:@"comments"];
                app.formulaNum = [[data objectForKey:@"formulaNum"]intValue];
                
            }else{
                 [_HUD setLabelText:[NSString stringWithFormat:@"初始化失败，code = %d",[errorcode intValue]]];
                _isInit = NO;
            }
        }else{
            NSString * respStr = request.responseString;
            NSDictionary * dict = [respStr JSONValue];
            NSLog(@"RET:\n%@",dict);
            NSNumber * code = [dict objectForKey:@"code"];
            if ([code intValue] == 0) {   // login success
                NSDictionary* data = [dict objectForKey:@"data"];
                 NSNumber * errorcode = [data objectForKey:@"errorCode"];
                if ([errorcode intValue] == 0) {  // success
                    AppDelegate* app = [[UIApplication sharedApplication]delegate];
                    app.addressList = [data objectForKey:@"addressList"];
                    app.signalTester = [[data objectForKey:@"signalTester"]intValue];
                    [self performSegueWithIdentifier:@"PushInputBox" sender:self.btnLogin];
                }else{ // failed
                     [_HUD setLabelText:[NSString stringWithFormat:@"登录失败，code = %d",[errorcode intValue]]];
                }
            }else{
                [_HUD setLabelText:[NSString stringWithFormat:@"登录失败，code = %d",[code intValue]]];
            }
            
            
        }
    }
    
    [_HUD hide:YES afterDelay:1];
}

@end
