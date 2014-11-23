//
//  PickerView.h
//
//
//  Created by Wu YouJian on 8/20/11.
//  Copyright 2011 asiainfo-linkage. All rights reserved.
//

#import <UIKit/UIKit.h>




typedef enum{
    enum_dateType,
    enum_listType
}viewType;

@protocol UIPickerViewHiddenDelegate

@optional
- (void)pickerViewDidHidden;

-(void)getSelectTable:(NSInteger)index;
-(void)getSelectDate:(NSDate*)selectDate;
@end

@interface PickerView : UIView<UIPickerViewDataSource,UIPickerViewDelegate> {
	UIDatePicker* datePicker;
	UIPickerView* tableListPickerView;
    
    UINavigationBar* toolbar;
	//UIToolbar * toolbar;
	viewType type;
	NSArray* tableNameList;
	
	id <UIPickerViewHiddenDelegate> delegate;
	NSInteger selTableIndex;
	NSDate* selDate;
    
    NSDate* minDate;
    NSDate* maxDate;
    
    BOOL cover;
}

@property(nonatomic,assign)id <UIPickerViewHiddenDelegate> delegate;
@property(nonatomic,assign)viewType type;
@property(nonatomic,retain)NSArray* tableNameList;
@property(nonatomic,assign)NSInteger selTableIndex;
@property(nonatomic,retain)NSDate* selDate;
@property(nonatomic,retain)NSDate* minDate;
@property(nonatomic,retain)NSDate* maxDate;
@property(nonatomic,assign)BOOL cover;


+(PickerView*)sharedPickerView;

-(void)showPickerView:(viewType)itype;
-(void)dismissPickerView;



@end
