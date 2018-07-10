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
- (void)insertData:(id)classObject tableName:(NSString *)tableName;

/**
 按照单个条件删除某条数据

 @param tableName 表名
 @param columnName 条件字段名
 @param value 条件字段内容
 */
- (void)deletedDataWithTableName:(NSString *)tableName columnName:(NSString *)columnName value:(id)value;

/**
 按照多个条件删除某条数据

 @param tableName 表名
 @param columnNames 条件数组
 @param values 内容数组
 */
- (void)deletedDataWithTableName:(NSString *)tableName columnNames:(NSArray *)columnNames values:(NSArray *)values;

@end
