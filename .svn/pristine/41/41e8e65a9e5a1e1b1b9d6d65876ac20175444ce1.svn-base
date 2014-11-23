//
//  PickerView.m
//
//
//  Created by Wu YouJian on 8/20/11.
//  Copyright 2011 asiainfo-linkage. All rights reserved.
//

#import "PickerView.h"

#define screenHeight [UIScreen mainScreen].bounds.size.height
#define screenWidth [UIScreen mainScreen].bounds.size.width

#define kDateSelectPickerTag    400
#define kOkTag                  401
#define kCancelTag              402
#define kMarkViewTag            403
#define kCoverViewTag            404



@interface PickerView(Private)

- (void)layoutTableListPickerView;
- (void)layoutDatePicker;
- (void)layoutToolBar;

@end


@implementation PickerView
@synthesize delegate;
@synthesize tableNameList;
@synthesize type;
@synthesize	selTableIndex;
@synthesize selDate;
@synthesize minDate;
@synthesize maxDate;
@synthesize cover;


// 单实例模式
static PickerView     *sharedPickerView = nil;


+(PickerView*)sharedPickerView{
    @synchronized ([PickerView class]) {
        if (sharedPickerView == nil) {
			sharedPickerView = [[PickerView alloc] initWithFrame:CGRectMake(0, screenHeight, screenWidth, 260)];
			[[[UIApplication sharedApplication] keyWindow] addSubview:sharedPickerView];
        }
    }
    return sharedPickerView;
}


#pragma mark -
#pragma mark UI Methods
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
        [self setBackgroundColor:[UIColor clearColor]];
        [self setClipsToBounds:YES];
    }
    return self;
}

-(void)toolbarAction:(UIBarButtonItem*)sender{
    [self dismissPickerView];
    
    UIBarButtonItem* btn = (UIBarButtonItem*)sender;
	if (btn.tag == kOkTag) {
		if (self.delegate != nil) {
			switch (self.type) {
				case enum_dateType:
					[self.delegate getSelectDate:[datePicker date]];
					
                    break;
				case enum_listType:
					[self.delegate getSelectTable:self.selTableIndex];
					break;
				default:
					break;
			}
		}
	}else {
	}
}

-(void)layoutToolBar{
    //创建工具栏
    UINavigationItem *item = [[UINavigationItem alloc] init];
    
    /*
    UIBarButtonItem *confirmBtn = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"ok.png"] style:UIBarButtonItemStylePlain target:self action:@selector(toolbarAction:)];//[[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(toolbarAction:)];
    
    confirmBtn.tag = kOkTag;
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(toolbarAction:)];
    cancelBtn.tag = kCancelTag;
    */
    
    // 连接按钮
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmButton.frame = CGRectMake(0,0, 45, 30);
    [confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmButton.tag = kOkTag;
    [confirmButton setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [confirmButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [confirmButton addTarget:self action:@selector(toolbarAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *confirmBarItem = [[[UIBarButtonItem alloc]initWithCustomView:confirmButton]autorelease];
    
    // 取消按钮
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(0,0, 45, 30);
    cancelButton.tag = kCancelTag;
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [cancelButton addTarget:self action:@selector(toolbarAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *cancelBarItem = [[[UIBarButtonItem alloc]initWithCustomView:cancelButton]autorelease];
    
    item.rightBarButtonItem = confirmBarItem;
    item.leftBarButtonItem = cancelBarItem;
    
    
    
    
    toolbar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 44)];
    // UIBarStyleBlackTranslucent
    toolbar.barStyle = UIBarStyleBlackOpaque;
    [toolbar pushNavigationItem:item animated:YES];
    //toolbar.items = @[cancelBtn,confirmBtn];
    
    @autoreleasepool {
        UIImage * navImage = [UIImage imageNamed:@"NavBar"];
        [toolbar setBackgroundImage:navImage forBarMetrics:UIBarMetricsDefault];
    }
    [item release];
    
    
    
    
    [self addSubview:toolbar];
}

- (void)layoutTableListPickerView {
	tableListPickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 44, screenWidth, 216)];
	tableListPickerView.delegate = self;
	tableListPickerView.dataSource = self;
	tableListPickerView.contentMode = UIViewContentModeCenter;
	tableListPickerView.backgroundColor = [UIColor whiteColor];
	tableListPickerView.showsSelectionIndicator = YES;
	[self addSubview:tableListPickerView];
}


- (void)layoutDatePicker {
	datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 44, screenWidth, 216)];
	datePicker.backgroundColor = [UIColor blackColor];
	datePicker.tag = kDateSelectPickerTag;
    
	
	datePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    //datePicker.locale = [NSLocale currentLocale];
    
	//
    if (minDate != nil ) {
        [datePicker setMinimumDate:minDate];
    }else{
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setHour:00];
        [components setMinute:00];
        [components setSecond:00];
        [components setDay:1];
        [components setMonth:1];
        [components setYear:2010];
        
        if ([components respondsToSelector:@selector(setTimeZone:)]) {
            [components setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        }
        
        NSDate *date = [gregorian dateFromComponents:components];
        [gregorian release];
        [components release];
        
        [datePicker setMinimumDate:date];
    }
    
    if (maxDate != nil ) {
        [datePicker setMaximumDate:maxDate];
    }else{
        [datePicker setMaximumDate:[NSDate date]];
    }
    
	[self addSubview:datePicker];
}


-(void)tap:(UITapGestureRecognizer*)gesture{
    UIView* markView = [[[UIApplication sharedApplication] keyWindow] viewWithTag:kMarkViewTag];
    [markView removeGestureRecognizer:gesture];
    [self dismissPickerView];
    
}

-(void)showPickerView:(viewType)itype{
    [self layoutToolBar];
    [self layoutDatePicker];
    [self layoutTableListPickerView];
    
    //[[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:self];
    
	self.type = itype;
	switch (type) {
		case enum_dateType:{
            if (cover) {
//                UIView* coverView = [[UIView alloc] initWithFrame:CGRectMake(screenWidth-110, 44, 110, self.frame.size.height-44)];
//                [coverView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:.8]];
                UIView* coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 44, screenWidth - 110, self.frame.size.height-44)];
                [coverView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:.5]];
                [coverView setTag:kCoverViewTag];
                [self addSubview:coverView];
                [coverView release];
            }
            
            
			if (self.selDate != nil) {
                [datePicker setDate:self.selDate];
            }else{
                [datePicker setDate:[NSDate date]];
            }
            
            tableListPickerView.hidden = YES;
            datePicker.hidden = NO;
            
            
			break;
		}
		case enum_listType:{
            tableListPickerView.hidden = NO;
            datePicker.hidden = YES;
            
			[tableListPickerView reloadComponent:0];
			[tableListPickerView selectRow:self.selTableIndex inComponent:0 animated:YES];
            
			break;
		}
		default:
			break;
	}
    
    UIView* markView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    markView.tag = kMarkViewTag;
    
    UITapGestureRecognizer* gesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(tap:)];
    [markView addGestureRecognizer:gesture];
    [gesture release];
    
    markView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    [[[UIApplication sharedApplication] keyWindow] insertSubview:markView belowSubview:self];
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(0, screenHeight-260, screenWidth, 260);
        markView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    } completion:^(BOOL finished) {
    }];
}

-(void)dismissPickerView{
    [self.delegate pickerViewDidHidden];
    UIView* markView = [[[UIApplication sharedApplication] keyWindow] viewWithTag:kMarkViewTag];
    [UIView animateWithDuration:0.3 animations:^{
        markView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        self.frame = CGRectMake(0, screenHeight, screenWidth, 260);
    } completion:^(BOOL finished) {
        tableListPickerView.hidden = YES;
        datePicker.hidden = YES;
        
        for (UIView* v in [tableListPickerView subviews]) {
            [v removeFromSuperview];
        }
        [tableListPickerView removeFromSuperview];
        tableListPickerView = nil;
        
        for (UIView* v in [datePicker subviews]) {
            [v removeFromSuperview];
        }
        [datePicker removeFromSuperview];
        datePicker = nil;
        
        for (UIView* v in [toolbar subviews]) {
            [v removeFromSuperview];
        }
        [toolbar removeFromSuperview];
        toolbar = nil;
        
        [markView removeFromSuperview];
        
        UIView* coverView = [self viewWithTag:kCoverViewTag];
        [coverView removeFromSuperview];
        coverView = nil;
    }];
}

#pragma mark -
#pragma mark Picker Data Source Methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSInteger num = 0;
	switch (component) {
		case 0:
		{
			if (pickerView == tableListPickerView) {
				num = [self.tableNameList count];
			}
			
			break;
		}
		default:
			break;
	}
	return num;
}

#pragma mark - Picker Delegate Methods
- (NSString *)pickerView:(UIPickerView*)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
	switch (component) {
		case 0:
		{
			if (pickerView == tableListPickerView) {
				return [self.tableNameList objectAtIndex:row];
			}
		}
		default:
			return @"-";
	}
}

- (void)pickerView:(UIPickerView *)pickerView
	  didSelectRow:(NSInteger)row
	   inComponent:(NSInteger)component
{
	if (component == 0) {
		if (pickerView == tableListPickerView) {
			self.selTableIndex = row;
		}
	}
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
	UILabel* label = [[[UILabel alloc] initWithFrame:CGRectMake(16.0,
																0,
																[pickerView rowSizeForComponent:component].width,
																[pickerView rowSizeForComponent:component].height)] autorelease];
	if (pickerView == tableListPickerView) {
		[label setText:[self.tableNameList objectAtIndex:row]];
	}
	
	label.lineBreakMode = NSLineBreakByTruncatingMiddle;
	[label setFont:[UIFont boldSystemFontOfSize:24]];
	[label setBackgroundColor:[UIColor clearColor]];
	[label setTextAlignment:NSTextAlignmentCenter];
	return label;
}


- (void)dealloc {
	[tableNameList release];
	[selDate release];
	[super dealloc];
}


@end
