//
//  CustomClass.h
//  TestRunTime
//
//  Created by ys on 16/6/13.
//  Copyright © 2016年 jzh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomClass : NSObject
{
    NSString *varTest1;
    NSString *varTest2;
    NSString *varTest3;
}

@property (nonatomic, assign) NSString *varTest1;
@property (nonatomic, assign) NSString *varTest2;
@property (nonatomic, assign) NSString *varTest3;

- (void)fun1;

@end
