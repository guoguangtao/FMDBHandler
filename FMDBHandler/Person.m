//
//  Person.m
//  FMDBHandler
//
//  Created by GGT on 2018/7/9.
//Copyright © 2018年 GGT. All rights reserved.
//

#import "Person.h"
#import <objc/runtime.h>

@interface Person ()



@end

@implementation Person

#pragma mark - Lifecycle

/**
 *  归档
 */
- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    unsigned int count = 0;
    //  利用runtime获取实例变量的列表
    Ivar *ivars = class_copyIvarList([self class], &count);
    for (int i = 0; i < count; i ++) {
        //  取出i位置对应的实例变量
        Ivar ivar = ivars[i];
        //  查看实例变量的名字
        const char *name = ivar_getName(ivar);
        //  C语言字符串转化为NSString
        NSString *nameStr = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        //  利用KVC取出属性对应的值
        id value = [self valueForKey:nameStr];
        //  归档
        [aCoder encodeObject:value forKey:nameStr];
    }
    
    //  记住C语言中copy出来的要进行释放
    free(ivars);
}

/**
 *  解档
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList([self class], &count);
        for (int i = 0; i < count; i ++) {
            Ivar ivar = ivars[i];
            const char *name = ivar_getName(ivar);
            NSString *key = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            id value = [aDecoder decodeObjectForKey:key];
            
            //  设置到成员变量身上
            [self setValue:value forKey:key];
        }
        
        free(ivars);
    }
    
    return self;
}

- (void)dealloc {
    
    NSLog(@"%s", __func__);
}


#pragma mark - Custom Accessors (Setter 方法)


#pragma mark - Public


#pragma mark - Private


#pragma mark - Protocol


#pragma mark - 懒加载



@end
