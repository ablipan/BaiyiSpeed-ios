//
//  ResultViewController.m
//  BaiyiSpeed
//
//  Created by Cooriyou on 14-8-31.
//  Copyright (c) 2014年 AILK. All rights reserved.
//

#import "ResultViewController.h"
#import "AppDelegate.h"

@interface ResultViewController ()
@property (weak, nonatomic) IBOutlet UIView *vContent;
@property (weak, nonatomic) IBOutlet UILabel *lbAddress;
@property (weak, nonatomic) IBOutlet UILabel *lbCount;
@property (weak, nonatomic) IBOutlet UILabel *lbSignal;
@property (weak, nonatomic) IBOutlet UILabel *lbSpeed;
@property (weak, nonatomic) IBOutlet UILabel *lbMaxCount;

@end

@implementation ResultViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if ([[[UIDevice currentDevice]systemVersion]floatValue] < 7.0){
        _vContent.frame = CGRectMake(_vContent.frame.origin.x , _vContent.frame.origin.y - 72, _vContent.frame.size.width,  _vContent.frame.size.height) ;
        
    }
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    self.lbAddress.text =[NSString stringWithFormat:@"%@%@",app.college,app.address];
    self.lbCount.text = [NSString stringWithFormat:@"%d人",app.seatNumber];
    self.lbSignal.text = [NSString stringWithFormat:@"%d(dbm)",app.signal];
    self.lbSpeed.text = [NSString stringWithFormat:@"%d(KB/s)",app.speed];
    NSInteger n = (app.speed*app.formulaNum)/400;
    self.lbMaxCount.text = [NSString stringWithFormat:@"%d人",n];
    //self.navigationItem.hidesBackButton = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)callTelphone:(id)sender {
    [((AppDelegate *)[UIApplication sharedApplication].delegate) callTelphone];

}

- (IBAction)doBack:(id)sender{
    
    [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
//    [self.navigationController popToRootViewControllerAnimated:YES];
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
