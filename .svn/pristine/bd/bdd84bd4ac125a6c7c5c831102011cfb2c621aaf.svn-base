//
//  DDList.h
//  DropDownList
//
//  Created by kingyee on 11-9-19.
//  Copyright 2011 Kingyee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PassValueDelegate;

@interface DDList : UITableViewController {
	NSArray		*_searchText;
	NSString		*_selectedText;
	NSMutableArray	*_resultList;
	id <PassValueDelegate>	_delegate;
}

@property (nonatomic, strong)NSArray		*_searchText;

@property (nonatomic, copy)NSString		*_selectedText;
@property (nonatomic, retain)NSMutableArray	*_resultList;
@property (weak) id <PassValueDelegate> _delegate;

- (void)updateData:(NSMutableArray *) addressList ;

@end
