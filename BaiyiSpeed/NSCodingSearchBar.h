//
//  NSCodingSearchBar.h
//  BaiyiSpeed
//
//  Created by Pan on 14/11/24.
//  Copyright (c) 2014年 AILK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSCodingSearchBar : UISearchBar

// Default by the system is YES.
// https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/UIKit.framework/UISearchBar.h
@property (nonatomic, assign, setter = setHasCentredPlaceholder:) BOOL hasCentredPlaceholder;

@end