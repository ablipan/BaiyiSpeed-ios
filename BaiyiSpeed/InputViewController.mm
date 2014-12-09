//
//  InputViewController.m
//  BaiyiSpeed
//
//  Created by Cooriyou on 14-8-28.
//  Copyright (c) 2014年 AILK. All rights reserved.
//

#import "InputViewController.h"
#import "ASIHTTPRequest.h"
#import "AppDelegate.h"
#import "Tools/MBProgressHUD.h"
#import "JSON.h"
#import "PickerView.h"
#import "DDList.h"
#import "PassValueDelegate.h"
#import "FMDatabase.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import "NSCodingSearchBar.h"
#import "StringB.h"
#import <arpa/inet.h>
#import <netdb.h>

@implementation CollegeInfo

- (NSString*)description{
    return self.collegeName;
}

@end

@interface InputViewController () <UIPickerViewHiddenDelegate, UITextFieldDelegate, UISearchBarDelegate, PassValueDelegate, UIAlertViewDelegate,CLLocationManagerDelegate>{
    
    CGPoint  centerPoint;
    UISearchBar * currentSearchBar;
    DDList				 *_ddList;
    NSCodingSearchBar * _citySearchBar; //城市搜索框
    NSCodingSearchBar * _collegeSearchBar; // 大学搜索框
    NSCodingSearchBar * _classroomSearchBar; //详细地址搜索框...
    NSCodingSearchBar * _seatnumSearchBar; //座位数...

}
@property(nonatomic ,strong) NSMutableArray * cityArrays;
@property(nonatomic ,strong) NSMutableArray * collegeArrays;

@property(nonatomic, strong) NSMutableArray * schoolInfoArray;
@property(nonatomic, strong) NSMutableArray *tableNameList;

@property (weak, nonatomic) IBOutlet UITextField *txCollege;
@property (weak, nonatomic) IBOutlet UITextField *txCity;
@property (weak, nonatomic) IBOutlet UITextField *txAddress;
@property (weak, nonatomic) IBOutlet UITextField *txSeatNum;

@property (weak, nonatomic) IBOutlet UIImageView *btnNext;
@property (weak, nonatomic) IBOutlet UIControl *vContent;

@property( nonatomic ,strong) ASIHTTPRequest * request;
@property(nonatomic,strong)MBProgressHUD* HUD;

#define INIT   100 // 初始化请求
#define SUBMIT 101 // 提交请求
#define GET_DETAIL_ADDS 102 //获得详细地址请求标识
#define NETWORK 200 //网络检查dialog

@property(nonatomic)BOOL isInit; //是否初始化...
@property(nonatomic)NSString *historyCity;  // 记录历史城市...
@property(nonatomic)NSString *historyCollege; // 记录历史大学；避免每次点击详细地址时都进行请求...
@property(nonatomic)NSMutableArray *classroomArray;

@property (nonatomic,retain)CLLocationManager* locationManager;

@end

@implementation InputViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

// 从db中查询所有城市
- (void)queryCityData {
    debugMethod();
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"init" ofType:@"db"];
    self.cityArrays = [NSMutableArray arrayWithCapacity:1000];
    FMDatabase * db = [FMDatabase databaseWithPath:dbPath];
    if ([db open]) {
        NSString * sql = @"select distinct(city) from campus";
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next]) {
            NSString * city = [rs stringForColumn:@"city"];
            [self.cityArrays addObject:city];
        }
        [db close];
    }    
}

// 从db中查询所有大学
- (void)queryCampusData{
    debugMethod();
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"init" ofType:@"db"];
    self.collegeArrays = [NSMutableArray arrayWithCapacity:1000];
    FMDatabase * db = [FMDatabase databaseWithPath:dbPath];
    if ([db open]) {
        NSString * sql = @"select * from campus";
        if ([StringB trim:_citySearchBar.text].length != 0) {
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@" where city ='%@'",[StringB trim:_citySearchBar.text]]];
        }
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next]) {
//            int userId = [rs intForColumn:@"id"];
            CollegeInfo * college = [[CollegeInfo alloc] init];
            NSString * name = [rs stringForColumn:@"name"];
            NSString * city = [rs stringForColumn:@"city"];
            college.collegeName = name;
            college.cityOfCollege = city;
            [self.collegeArrays addObject:college];
//            debugLog(@"user id = %d, name = %@, pass = %@", userId, name, city);
        }
        [db close];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (![AppDelegate isEnable3G] && ![AppDelegate isEnableWIFI]) {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"手机网络不可用" delegate:self cancelButtonTitle:@"退出" otherButtonTitles: nil];
        alert.tag = NETWORK;
        [alert show];
    }
    
    if ([[[UIDevice currentDevice]systemVersion]floatValue] < 7.0){
        _vContent.frame = CGRectMake(_vContent.frame.origin.x , _vContent.frame.origin.y - 72, _vContent.frame.size.width,  _vContent.frame.size.height) ;
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavBar6"] forBarMetrics:UIBarMetricsDefault];
    }else{
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavBar"] forBarMetrics:UIBarMetricsDefault];
    }
    
    _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_HUD];
    _isInit = NO;
    [self doInit]; //获得初始化数据...
    [self queryCityData]; // 查询城市信息
    
    NSLog(@"_txCity:%f,_txCollege:%f,_txAddress:%f",_txCity.frame.origin.x,_txCollege.frame.origin.x,_txAddress.frame.origin.x);
    
    _txCity.hidden = YES;
    _citySearchBar = [[NSCodingSearchBar alloc] initWithFrame: CGRectMake(50 , _txCity.frame.origin.y, _txCity.frame.size.width+25, _txCity.frame.size.height)];// 初始化，不解释
    [_vContent addSubview:_citySearchBar];
    _citySearchBar.backgroundImage = [self createImageWithColor:[UIColor clearColor]];
    _citySearchBar.delegate = self;
    [_citySearchBar setImage:_citySearchBar.backgroundImage forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    //[_citySearchBar setImage:_citySearchBar.backgroundImage forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    [_citySearchBar setImage:_citySearchBar.backgroundImage forSearchBarIcon:UISearchBarIconResultsList state:UIControlStateNormal];
    
//    [_citySearchBar setBackgroundColor:[UIColor clearColor]];
//    [_citySearchBar insertSubview: [[UIImageView alloc] initWithImage: [self createImageWithColor:[UIColor clearColor]] ] atIndex:1];
//    _citySearchBar.searchTextPositionAdjustment = UIOffsetMake(-16, 0);
    _citySearchBar.placeholder = @"城市";
    [_citySearchBar setHasCentredPlaceholder:NO]; // placehoder不居中
        
    _txCollege.hidden = YES;
    _collegeSearchBar = [[NSCodingSearchBar alloc] initWithFrame: CGRectMake(50, _txCollege.frame.origin.y,  _txCollege.frame.size.width+25, _txCollege.frame.size.height)];// 初始化，不解释
    [_vContent addSubview:_collegeSearchBar];
    _collegeSearchBar.backgroundImage = [self createImageWithColor:[UIColor clearColor]];
    _collegeSearchBar.delegate = self;
    [_collegeSearchBar setImage:_collegeSearchBar.backgroundImage forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
//    [_collegeSearchBar setImage:_collegeSearchBar.backgroundImage forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    [_collegeSearchBar setImage:_collegeSearchBar.backgroundImage forSearchBarIcon:UISearchBarIconResultsList state:UIControlStateNormal];
//    [_collegeSearchBar insertSubview: [[UIImageView alloc] initWithImage: [self createImageWithColor:[UIColor clearColor]] ] atIndex:1];
//    _collegeSearchBar.searchTextPositionAdjustment = UIOffsetMake(-16, 0);
    _collegeSearchBar.placeholder = @"学校或其他机构";
    [_collegeSearchBar setHasCentredPlaceholder:NO]; // placehoder不居中

    _txAddress.hidden = YES;
    _classroomSearchBar = [[NSCodingSearchBar alloc] initWithFrame: CGRectMake(50 , _txAddress.frame.origin.y, _txAddress.frame.size.width+25, _txAddress.frame.size.height)];// 初始化，不解释
    [_vContent addSubview:_classroomSearchBar];
    _classroomSearchBar.backgroundImage = [self createImageWithColor:[UIColor clearColor]];
    _classroomSearchBar.delegate = self;
    [_classroomSearchBar setImage:_classroomSearchBar.backgroundImage forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
//    [_classroomSearchBar setImage:_classroomSearchBar.backgroundImage forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    [_classroomSearchBar setImage:_classroomSearchBar.backgroundImage forSearchBarIcon:UISearchBarIconResultsList state:UIControlStateNormal];
//    [_classroomSearchBar insertSubview: [[UIImageView alloc] initWithImage: [self createImageWithColor:[UIColor clearColor]] ] atIndex:1];
//    _classroomSearchBar.searchTextPositionAdjustment = UIOffsetMake(-16, 0);
    _classroomSearchBar.placeholder = @"校区楼号等详细地址信息";
    [_classroomSearchBar setHasCentredPlaceholder:NO]; // placehoder不居中
    
    
    
    _txSeatNum.hidden = YES;
    _seatnumSearchBar = [[NSCodingSearchBar alloc] initWithFrame: CGRectMake(50 , _txSeatNum.frame.origin.y, _txSeatNum.frame.size.width+25, _txSeatNum.frame.size.height)];// 初始化，不解释
    [_vContent addSubview:_seatnumSearchBar];
    _seatnumSearchBar.backgroundImage = [self createImageWithColor:[UIColor clearColor]];
    _seatnumSearchBar.delegate = self;
    [_seatnumSearchBar setImage:_seatnumSearchBar.backgroundImage forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    //    [_seatnumSearchBar setImage:_seatnumSearchBar.backgroundImage forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    [_seatnumSearchBar setImage:_seatnumSearchBar.backgroundImage forSearchBarIcon:UISearchBarIconResultsList state:UIControlStateNormal];
    //    [_seatnumSearchBar insertSubview: [[UIImageView alloc] initWithImage: [self createImageWithColor:[UIColor clearColor]] ] atIndex:1];
    //    _seatnumSearchBar.searchTextPositionAdjustment = UIOffsetMake(-16, 0);
    [_seatnumSearchBar setKeyboardType:UIKeyboardTypeNumberPad];
    _seatnumSearchBar.placeholder = @"座位数";
    [_seatnumSearchBar setHasCentredPlaceholder:NO]; // placehoder不居中
    
    //自定义返回按钮
    UIImage *backButtonImage = [[UIImage imageNamed:@"nav_backbar.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 0)];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    //将返回按钮的文字position设置不在屏幕上显示
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(NSIntegerMin, NSIntegerMin) forBarMetrics:UIBarMetricsDefault];
    
//    UIButton * collegeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    collegeBtn.frame = CGRectMake(CGRectGetMaxX(self.txCollege.frame), self.txCollege.frame.origin.y, 50, 40);
//    [_vContent addSubview:collegeBtn];
//    [collegeBtn addTarget:self action:@selector(textFieldClicked:) forControlEvents:UIControlEventTouchUpInside];
//    self.txCollege.delegate = self;
//    self.txAddress.delegate = self;
//    self.txCity.delegate = self;
    
    _ddList = [[DDList alloc] initWithStyle:UITableViewStylePlain];
	_ddList._delegate = self;
	[_vContent addSubview:_ddList.view];
	[_ddList.view setFrame:CGRectMake(_txAddress.frame.origin.x - 46  , _txAddress.frame.origin.y + 37, _txAddress.frame.size.width + 80, 0)];
    
    
    // 定位...
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
//    self.locationManager.purpose = @"To provide functionality based on user's current location.";
//    [self.locationManager startUpdatingLocation];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == NETWORK) {
        if (buttonIndex == 0) {     // and they clicked OK.
            exit(0);
        }
    }
}

// 查询基本信息
-(void)doInit
{
    NSURL *url = [NSURL URLWithString:[[AppDelegate getBaseUrl] stringByAppendingString:@"getBasicInfo"]];
    self.request = [ASIHTTPRequest requestWithURL:url];
    [self.request setDelegate:self];
    [self.request setTag:INIT];
    [self.request startAsynchronous];
    return;
}

- (void)backButtonClicked:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

// 视图即将显式
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    if ([CLLocationManager locationServicesEnabled]) {
    #if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
         if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            BOOL hasAlwaysKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] != nil;
            BOOL hasWhenInUseKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] != nil;
            if (hasAlwaysKey) {
                [_locationManager requestAlwaysAuthorization];
            } else if (hasWhenInUseKey) {
                [_locationManager requestWhenInUseAuthorization];
            } else {
                NSAssert(hasAlwaysKey || hasWhenInUseKey, @"To use location services in iOS 8+, your Info.plist must provide a value for either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription.");
            }
        }
    #endif /* __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1 */
        
        [_locationManager startUpdatingLocation];
    }
}

// 视图已显式时
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    centerPoint = self.vContent.center;
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    if ([app.addressList count] != 0 && !app.hasAlerted ) {
//        NSString *comments = app.comments;
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"测速预计花费时间3分钟，花费流量20兆，建议购买流量包。" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
        app.hasAlerted = YES;
    }
}

// 视图即将消失时...
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    [_locationManager stopUpdatingLocation];
    [_HUD hide:YES];
}

#pragma mark SearchBar Delegate Methods
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    currentSearchBar = searchBar;
    // 教室搜索
	if ([searchText length] != 0) {
        if (searchBar == _classroomSearchBar) {
            NSPredicate *sPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchBar.text];
            NSArray * arr = [self.classroomArray filteredArrayUsingPredicate:sPredicate];
            NSLog(@"%@", arr);
            if (arr.count > 0) {
                [_ddList updateData: [arr mutableCopy]];
                [self setDDListHidden:NO];
            } else {
                [self setDDListHidden:YES];
                
            }
        } else if (searchBar == _collegeSearchBar){ // 大学搜索
            NSPredicate *sPredicate = [NSPredicate predicateWithFormat:@"SELF.collegeName contains[c] %@", searchBar.text];
            NSArray * arr = [self.collegeArrays filteredArrayUsingPredicate:sPredicate];
            NSLog(@"%@", arr);
            if (arr.count > 0) {
                [_ddList updateData: [arr mutableCopy]];
                [self setCollegeDDListHidden:NO];
            } else {
                [self setCollegeDDListHidden:YES];

            }
        } else if (searchBar == _citySearchBar){ // 城市搜索
            NSPredicate *sPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchBar.text];
            NSArray * arr = [self.cityArrays filteredArrayUsingPredicate:sPredicate];
            NSLog(@"%@", arr);
            if (arr.count > 0) {
                [_ddList updateData: [arr mutableCopy]];
                [self setCityDDListHidden:NO];
            } else {
                [self setCityDDListHidden:YES];
                
            }
        }
    }
    else {
        if (currentSearchBar == _classroomSearchBar) {
            [self setDDListHidden:YES];
        } else if (currentSearchBar == _collegeSearchBar){
            [self setCollegeDDListHidden:YES];
        } else if (currentSearchBar == _citySearchBar){
            [self setCityDDListHidden:YES];
        }
        
    }
}

#pragma mark UISearchBar事件
// 搜索框开始输入...
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (_classroomSearchBar == searchBar) { //详细地址点击时获取详细信息列表
        currentSearchBar = _classroomSearchBar;
        if (_citySearchBar.text.length != 0 && _collegeSearchBar.text.length!=0) {
            [self getDetailAddList];
        }
        self.vContent.center = CGPointMake(centerPoint.x, centerPoint.y - 105);
    } else if (_collegeSearchBar == searchBar){ // 大学输入框点击
        [self queryCampusData]; // 查询大学信息
        self.vContent.center = CGPointMake(centerPoint.x, centerPoint.y - 55);
    } else if (_seatnumSearchBar == searchBar)
    {
        self.vContent.center = CGPointMake(centerPoint.x, centerPoint.y - 150);
    }
}
// 搜索框输入完成
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = NO;
    //searchBar.text = @"";
    self.vContent.center = centerPoint;
    
}
// 搜索框搜索按钮点击事件
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self setDDListHidden:YES];
    [searchBar resignFirstResponder];
}
// 搜索框取消按钮点击事件
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
}

// 使用大学、城市查询详细地址信息
-(void)getDetailAddList
{
    _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_HUD];
    NSURL *url = [NSURL URLWithString:[[AppDelegate getBaseUrl] stringByAppendingString:@"getDetailAddList"]];
    NSMutableString * info = nil;
    info = [NSMutableString stringWithFormat:@"{\
            \"city\": \"%@\",\
            \"college\": \"%@\"}",
            _citySearchBar.text,
            _collegeSearchBar.text
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
    [self.request setTag:GET_DETAIL_ADDS];
    [self.request setPostBody:tempJsonData];
    [self.request startAsynchronous];
    _HUD.labelText = @"正在获取详细地址列表...";
    [_HUD show:YES];
    return;
}

#pragma mark PassValue protocol

// 下拉提示框传值
- (void)passValue:(NSString *)value{

}

// 下拉提示框选中
- (void)passSelectIndex:(int)index{
    if (currentSearchBar == _collegeSearchBar){ // 大学
        CollegeInfo * college = [_ddList._searchText objectAtIndex:index];
        _collegeSearchBar.text = college.collegeName;
        _citySearchBar.text = college.cityOfCollege;
        [self searchBarSearchButtonClicked:_collegeSearchBar];
        
    }else if (currentSearchBar == _citySearchBar) // 城市
    {
        NSString *city = [_ddList._searchText objectAtIndex:index];
        _citySearchBar.text = city;
        [self searchBarSearchButtonClicked:_citySearchBar];
    }else if(currentSearchBar == _classroomSearchBar) // 详细地址...
    {
        _classroomSearchBar.text = _ddList._selectedText;
        [self searchBarSearchButtonClicked:_classroomSearchBar];
    }
}


#pragma mark - Tools

- (void)setDDListHidden:(BOOL)hidden {
	NSInteger height = hidden ? 0 : 190;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.2];
	[_ddList.view setFrame:CGRectMake(_txAddress.frame.origin.x-60  , _txAddress.frame.origin.y + 35, _txAddress.frame.size.width+80, height)];
	[UIView commitAnimations];
}

- (void)setCollegeDDListHidden:(BOOL)hidden {
	NSInteger height = hidden ? 0 : 140;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.2];
	[_ddList.view setFrame:CGRectMake(_txCollege.frame.origin.x-60  , _txCollege.frame.origin.y + 35, _txCollege.frame.size.width+80, height)];
	[UIView commitAnimations];
}

- (void)setCityDDListHidden:(BOOL)hidden {
	NSInteger height = hidden ? 0 : 120;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.2];
	[_ddList.view setFrame:CGRectMake(_txCity.frame.origin.x -60 , _txCity.frame.origin.y + 35, _txCity.frame.size.width+80, height)];
	[UIView commitAnimations];
}

- (UIImage *)createImageWithColor: (UIColor *) color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}


#pragma mark - UIPickerViewHiddenDelegate


#pragma mark implement BMKSearchDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"定位失败...: %@",error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation * currLocation = [locations lastObject];
    
    CLGeocoder *Geocoder=[[CLGeocoder alloc]init];
    CLGeocodeCompletionHandler handler = ^(NSArray *place, NSError *error) {
        if (place.count >0) {
            CLPlacemark *placemark = [place objectAtIndex:0];
//            [AppDelegate debugWithDialog:[placemark.locality stringByAppendingString:placemark.administrativeArea]];
            NSString *cityStr = placemark.locality;
            if (!cityStr) {
                cityStr = placemark.administrativeArea;
            }
            if (cityStr) {
                cityStr = [[cityStr componentsSeparatedByString:@"市"] objectAtIndex:0];
                if ([self.cityArrays containsObject:cityStr]) {
                    _citySearchBar.text = cityStr;
                    [_locationManager stopUpdatingLocation];
                }
            }
        }
    };
    [Geocoder reverseGeocodeLocation:currLocation completionHandler:handler];

}


-(IBAction)backgroundTap:(id)sender
{
    [_collegeSearchBar resignFirstResponder];
    [_citySearchBar resignFirstResponder];
    //[_txAddress resignFirstResponder];
    [_classroomSearchBar resignFirstResponder];
    [_seatnumSearchBar resignFirstResponder];
    [self searchBarSearchButtonClicked:_classroomSearchBar];

}

- (IBAction)callTelphone:(id)sender {
    [((AppDelegate *)[UIApplication sharedApplication].delegate) callTelphone];
}

-(IBAction)next:(id)sender
{
    [self backgroundTap:nil];
    
    if ([_citySearchBar.text length] == 0 ||
        [_collegeSearchBar.text length] == 0 ||
        [_classroomSearchBar.text length] == 0 ||
        [_seatnumSearchBar.text length]==0) {
        
        NSString * str = @"";
        if ([_citySearchBar.text length] == 0) {
            str = @"城市不能为空";
        }else if ([_collegeSearchBar.text length] == 0) {
            str = @"地址不能为空";
        } else if ([_classroomSearchBar.text length] == 0) {
            str = @"详细地址不能为空";
        }else if (_seatnumSearchBar.text.length == 0){
            str = @"座位数不能为空";
        }
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"提示" message:str delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return ;
    }
    _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_HUD];
    NSURL *url = [NSURL URLWithString: [[AppDelegate getBaseUrl] stringByAppendingString:@"saveAddress"]];
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    NSMutableString * info = nil;
    info = [NSMutableString stringWithFormat:@"{\
            \"city\": \"%@\",\
            \"college\": \"%@\",\
            \"seatNumber\": \"%d\",\
            \"address\":\"%@\"}",
            _citySearchBar.text,
            _collegeSearchBar.text,
            _seatnumSearchBar.text.intValue,
            _classroomSearchBar.text
            ];
    app.address = _classroomSearchBar.text;
    app.college = _collegeSearchBar.text;
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
    [self.request setTag:SUBMIT];
    [self.request setPostBody:tempJsonData];
    [self.request startAsynchronous];
    _HUD.labelText = @"正在保存考场地址...";
    [_HUD show:YES];
    return;

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
        if (request.tag == INIT) {
            _isInit = NO;
        }
        [_HUD setLabelText:@"404你懂得"];
        [_HUD hide:YES afterDelay:1];
    } else {
        if (request.tag == INIT) { //初始化
            NSString * respStr = request.responseString;
            NSDictionary * dict = [respStr JSONValue];
            NSLog(@"RET:\n%@",dict);
            NSNumber * errorcode = [dict objectForKey:@"code"];
            
            if ([errorcode intValue] == 0) {   // init success
                
//                [_HUD setLabelText:@"初始化成功"];
                _isInit = YES;
                NSDictionary* data = [dict objectForKey:@"data"];
                AppDelegate* app = [[UIApplication sharedApplication]delegate];
                app.downloadUrl = [data objectForKey:@"downloadUrl"];
                app.uploadUrl = [data objectForKey:@"uploadUrl"];
                app.comments = [data objectForKey:@"comments"];
                app.formulaNum = [[data objectForKey:@"formulaNum"]intValue];
                
            }else{
//                [_HUD setLabelText:[NSString stringWithFormat:@"初始化失败，code = %d",[errorcode intValue]]];
                _isInit = NO;
            }
        }else if(request.tag == SUBMIT){ //提交地址信息
            NSString * respStr = request.responseString;
            NSDictionary * dict = [respStr JSONValue];
            NSLog(@"RET:\n%@",dict);
            NSNumber * code = [dict objectForKey:@"code"];
            if ([code intValue] == 0) {   // login success
                NSDictionary* data = [dict objectForKey:@"data"];
                NSNumber * errorcode = [data objectForKey:@"errorCode"];
                if ([errorcode intValue] == 0) {  // success
                    [_HUD setLabelText:@"保存考场地址成功"];
                    AppDelegate *app = [[UIApplication sharedApplication]delegate];
                    app.addressId = [[data objectForKey:@"addressId"]intValue];
                    [self performSegueWithIdentifier:@"pushTest" sender:self.btnNext];
                }else{
                    [_HUD setLabelText:[NSString stringWithFormat:@"保存考场地址失败，code = %d",[errorcode intValue]]];
                }
            }else{
                [_HUD setLabelText:@"保存考场地址失败"];
            }
            
        }else if(request.tag == GET_DETAIL_ADDS) //使用城市学校、获取详细地址信息
        {
            NSString * respStr = request.responseString;
            NSDictionary * dict = [respStr JSONValue];
            NSLog(@"RET:\n%@",dict);
            NSNumber * errorcode = [dict objectForKey:@"code"];
            if ([errorcode intValue] == 0) {   // init success
                NSArray* data = [dict objectForKey:@"data"];
                self.classroomArray = [data mutableCopy];
                if (data.count > 0) {
                    [_ddList updateData: self.classroomArray];
                    [self setDDListHidden:NO];
                } else {
                    [self setDDListHidden:YES];
                    self.classroomArray = nil;
                }
//                [AppDelegate debugWithDialog:respStr];
//                [AppDelegate debugWithDialog:[NSString stringWithFormat:@"学校 %d",[data count]]];
            }else{
                self.classroomArray = nil;
            }
            [_HUD hide:YES];
        }
        [_HUD hide:YES afterDelay:1];
    }
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

#pragma mark - UITextfield Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    NSLog(@"textFieldDidBeginEditing");
    self.vContent.center = CGPointMake(centerPoint.x, centerPoint.y - 40);

}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    NSLog(@"textFieldDidEndEditing");
    self.vContent.center = centerPoint;
    
}






#pragma mark 测试Socket下载
-(IBAction)download:(id)sender
{
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@", @"http://ixisu.com", @"80"]];
    NSThread * backgroundThread = [[NSThread alloc] initWithTarget:self
                                                          selector:@selector(loadDataFromServerWithURL:)
                                                            object:url];
    [backgroundThread start];

}

- (void)networkFailedWithErrorMessage:(NSString *)message
{
    // Update UI
    //
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSLog(@" >> %@", message);
        
//        self.receiveTextView.text = message;
//        self.connectButton.enabled = YES;
//        [self.networkActivityView stopAnimating];
        [AppDelegate debugWithDialog:@"Download Error"];
    }];
}

- (void)networkSucceedWithData:(NSData *)data
{
    // Update UI
    //
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString * resultsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@" >> Received string: '%@'", resultsString);
        
//        self.receiveTextView.text = resultsString;
//        self.connectButton.enabled = YES;
//        [self.networkActivityView stopAnimating];
        [AppDelegate debugWithDialog:[NSString stringWithFormat:@"Download success,data length:%d",data.length]];
    }];
}

- (void)loadDataFromServerWithURL:(NSURL *)url
{
    NSString * host = [url host];
    NSNumber * port = [url port];
    
    // Create socket
    //
    int socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
    if (-1 == socketFileDescriptor) {
        NSLog(@"Failed to create socket.");
        return;
    }
    
    // Get IP address from host
    //
    struct hostent * remoteHostEnt = gethostbyname([host UTF8String]);
    if (NULL == remoteHostEnt) {
        close(socketFileDescriptor);
        
        [self networkFailedWithErrorMessage:@"Unable to resolve the hostname of the warehouse server."];
        return;
    }
    
    struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
    
    // Set the socket parameters
    //
    struct sockaddr_in socketParameters;
    socketParameters.sin_family = AF_INET;
    socketParameters.sin_addr = *remoteInAddr;
    socketParameters.sin_port = htons([port intValue]);
    
    // Connect the socket
    //
    int ret = connect(socketFileDescriptor, (struct sockaddr *) &socketParameters, sizeof(socketParameters));
    if (-1 == ret) {
        close(socketFileDescriptor);
        
        NSString * errorInfo = [NSString stringWithFormat:@" >> Failed to connect to %@:%@", host, port];
        [self networkFailedWithErrorMessage:errorInfo];
        return;
    }
    
    // 发送报文
    const char *sendData = "GET /speedtest/test.bin /HTTP/1.1\r\n Host:http://ixisu.com:80\r\n Connection:Keep-Alive \r\n Cookie:pfMf_3d7c_lastvisit=1416963541,pfMf_3d7c_saltkey=ZIOwXXCP\r\n\r\n";
    int sendResult = send(socketFileDescriptor, sendData ,strlen(sendData), 0);
    if (-1 == sendResult) {
        close(socketFileDescriptor);
        NSString * errorInfo = [NSString stringWithFormat:@" >> Failed to send msg to %@:%@", host, port];
        [self networkFailedWithErrorMessage:errorInfo];
        return;
    }
    
    NSLog(@" >> Successfully connected to %@:%@", host, port);
    
    NSMutableData * data = [[NSMutableData alloc] init];
    BOOL waitingForData = YES;
    
    // Continually receive data until we reach the end of the data
    //
    int maxCount = 5;   // just for test.
    int i = 0;
    while (waitingForData && i < maxCount) {
        const char * buffer[1024];
        int length = sizeof(buffer); //对象或类型所占的内存字节数
        
        // Read a buffer's amount of data from the socket; the number of bytes read is returned
        //
        int result = recv(socketFileDescriptor, &buffer, length, 0);
        if (result > 0) {
            [data appendBytes:buffer length:result];
        }
        else {
            // if we didn't get any data, stop the receive loop
            //
            waitingForData = NO;
        }
        
        ++i;
    }
    
    // Close the socket
    //
    close(socketFileDescriptor);
    
    [self networkSucceedWithData:data];
}





@end
