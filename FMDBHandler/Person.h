//
//  Person.h
//  FMDBHandler
//
//  Created by GGT on 2018/7/9.
//Copyright © 2018年 GGT. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PersonSex) {
    PersonSexMan = 1,
    PersonSexWoman
};

@interface Person : NSObject

#pragma mark - Property

@property (nonatomic, assign) int age;          /**< 年龄 */
@property (nonatomic, copy) NSString *name;     /**< 名字 */
@property (nonatomic, assign) PersonSex sex;    /**< 性别 */
@property (nonatomic, strong) NSNumber *number;
@property (nonatomic, assign) double testNumber;

#pragma mark - Method

@end
