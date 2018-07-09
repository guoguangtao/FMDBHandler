//
//  FMDBHandler.h
//  FMDBHandler
//
//  Created by GGT on 2018/7/6.
//Copyright © 2018年 GGT. All rights reserved.
//

#import <Foundation/Foundation.h>

/// FMDB数据库管理
@interface FMDBHandler : NSObject

#pragma mark - Property


#pragma mark - Method

+ (instancetype)shareInstance;

/**
 初始化表格

 @param tableName 表名
 @param classObject 模型
 */
- (void)tableName:(NSString *)tableName classObject:(id)classObject;

/**
 插入数据
 
 @param classObject 需要插入的数据
 @param tableName 表名
 */
- (void)inserData:(id)classObject tableName:(NSString *)tableName;

@end
