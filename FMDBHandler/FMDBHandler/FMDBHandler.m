//
//  FMDBHandler.m
//  FMDBHandler
//
//  Created by GGT on 2018/7/6.
//Copyright © 2018年 GGT. All rights reserved.
//

#import "FMDBHandler.h"
#import "FMDB.h"
#import <objc/runtime.h>

@interface FMDBHandler ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) NSMutableArray *valuesArray;

@end

@implementation FMDBHandler

#pragma mark - Lifecycle

static FMDBHandler *_instance;

+ (instancetype)shareInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });
    
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [super allocWithZone:zone];
        }
    });
    
    return _instance;
}

- (void)dealloc {
    
    NSLog(@"%s", __func__);
}


#pragma mark - Custom Accessors (Setter 方法)


#pragma mark - Public

/**
 根据传入的表名和模型，利用运行时去创建数据库
 如果已经存在该表，遍历字段，看看是否需要添加新字段
 如果没有该表，则利用运行时，创建数据库

 @param tableName 表名
 @param classObject 模型
 */
- (void)tableName:(NSString *)tableName classObject:(id)classObject {
    
    if ([self tableIsExist:tableName]) {
        // 如果表格存在，查看表格是否需要增加字段
        [self existColumnWithClassObject:classObject tableName:tableName];
    } else {
        // 表格不存在，创建表格
        NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer PRIMARY KEY AUTOINCREMENT%@", tableName, [self dataPropertyClassObject:classObject]];
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                BOOL success = [db executeUpdate:sqlString];
                if (success) {
                    NSLog(@"表创建成功");
                } else {
                    NSLog(@"表创建失败");
                }
            }
            
            [self closeDataBase:db];
        }];
    }
}

/**
 插入数据

 @param classObject 需要插入的数据
 @param tableName 表名
 */
- (void)insertData:(id)classObject tableName:(NSString *)tableName {
    
    // 先创建表格
    [self tableName:tableName classObject:classObject];
    // 插入数据
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if ([db open]) {
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@%@", tableName, [self insertSqlStringWithClassObject:classObject]];
            if ([db executeUpdate:sql withArgumentsInArray:self.valuesArray]) {
                NSLog(@"数据插入成功");
            } else {
                NSLog(@"数据插入失败");
            }
            [self.valuesArray removeAllObjects];
            [self closeDataBase:db];
        }
    }];
}

/**
 删除某条数据
 
 @param tableName 表名
 @param columnName 条件字段名
 @param value 条件字段内容
 */
- (void)deletedDataWithTableName:(NSString *)tableName columnName:(NSString *)columnName value:(id)value {
    
    if ([self tableIsExist:tableName]) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", tableName, columnName];
                BOOL success = [db executeUpdate:sql withArgumentsInArray:@[value]]; // 删除操作
                if (!success) NSLog(@"删除失败");
                [self closeDataBase:db];
            }
        }];
    }
}

/**
 按照多个条件删除某条数据
 
 @param tableName 表名
 @param columnNames 条件数组
 @param values 内容数组
 */
- (void)deletedDataWithTableName:(NSString *)tableName columnNames:(NSArray *)columnNames values:(NSArray *)values {
    
    if ([self tableIsExist:tableName]) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                // SQL语句拼接
                NSMutableString *sqlString = [NSMutableString stringWithString:[NSString stringWithFormat:@"DELETE FROM %@ WHERE", tableName]];
                for (int i = 0; i < columnNames.count; i++) {
                    NSString *columnName = columnNames[i];
                    if (i == columnNames.count - 1) {
                        // 最后一个不需要 and
                        [sqlString appendFormat:@" %@ = ?", columnName];
                    } else {
                        [sqlString appendFormat:@" %@ = ? and", columnName];
                    }
                }
                
                BOOL success = [db executeUpdate:sqlString withArgumentsInArray:values];
                if (!success) NSLog(@"删除失败");
                [self closeDataBase:db];
            }
        }];
    }
}

/**
 单个条件更新数据
 
 @param tableName 表名
 @param columnName 条件字段名
 @param value 条件字段值
 @param updateColumnName 需要更新的字段名
 @param updateValue 需要更新的字段内容
 */
- (void)updateDataWithTableName:(NSString *)tableName columnName:(NSString *)columnName value:(id)value updateColumnName:(NSString *)updateColumnName updateValue:(id)updateValue {
    
    if ([self tableIsExist:tableName]) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                NSMutableString *sqlString = [NSMutableString stringWithFormat:@"UPDATE %@ SET %@ = ? WHERE %@ = ?", tableName, updateColumnName, columnName];
                BOOL success = [db executeUpdate:sqlString withArgumentsInArray:@[updateValue, value]];
                if (!success) NSLog(@"删除失败");
                [self closeDataBase:db];
            }
        }];
    }
}

#pragma mark - Private

/**
 判断字段是否存在，不存在新增一个字段
 */
- (void)existColumnWithClassObject:(id)classObject tableName:(NSString *)tableName {
    
    unsigned int outCount = 0;
    Ivar *ivars = class_copyIvarList([classObject class], &outCount);
    for (unsigned int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        const char *name = ivar_getName(ivar);
        const char *type = ivar_getTypeEncoding(ivar);
        
        NSString *columnString = [[NSString stringWithFormat:@"%s", name] substringFromIndex:1];
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                if (![db columnExists:columnString inTableWithName:tableName]){
                    NSString *sqlString = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@", tableName, columnString, [self sqlTypeWithChar:type]];
                    BOOL success = [db executeUpdate:sqlString];
                    if (success) {
                        NSLog(@"%@字段增加成功", columnString);
                    } else {
                        NSLog(@"%@字段增加失败", columnString);
                    }
                }
                [self closeDataBase:db];
            }
        }];
    }
    free(ivars);
    
}

/**
 创建表格字符串拼接
 
 @param classObject 数据模型
 */
- (NSString *)dataPropertyClassObject:(id)classObject {
    
    unsigned int outCount = 0;
    Ivar * ivars = class_copyIvarList([classObject class], &outCount);
    NSMutableString *sqlString = [NSMutableString string];
    for (unsigned int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        const char *name = ivar_getName(ivar);
        const char *type = ivar_getTypeEncoding(ivar);
        NSLog(@"类型为 %s, 熟悉名 %s", type, name);
        [sqlString appendFormat:@", %@ %@", [[NSString stringWithFormat:@"%s", name] substringFromIndex:1], [self sqlTypeWithChar:type]];
    }
    [sqlString appendString:@");"];
    free(ivars);
    
    return sqlString;
}

/**
 插入数据数据库命令字符串拼接

 @param classObject 模型
 */
- (NSString *)insertSqlStringWithClassObject:(id)classObject {
    
    unsigned int outCount = 0;
    Ivar *ivars = class_copyIvarList([classObject class], &outCount);
    NSMutableString *keyString = [NSMutableString stringWithString:@" ("];
    NSMutableString *valueString = [NSMutableString stringWithString:@" VALUES ("];
    for (unsigned int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        const char *name = ivar_getName(ivar);
        NSString *nameStr = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        id value = [classObject valueForKeyPath:nameStr];
        // 设置keyString
        [keyString appendFormat:@"%@, ", [nameStr substringFromIndex:1]];

        // 设置Value 
        [valueString appendFormat:@"?, "];
        [self.valuesArray addObject:value];
    }
    
    [keyString replaceCharactersInRange:NSMakeRange(keyString.length - 2, 2) withString:@")"];
    [valueString replaceCharactersInRange:NSMakeRange(valueString.length - 2, 2) withString:@");"];
    
    free(ivars);
    
    return [NSString stringWithFormat:@"%@%@", keyString, valueString];
}

/**
 数据库路径
 */
- (NSString *)filePath {
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FMDB.sqlite"];
    NSLog(@"%@", filePath);
    return filePath;
}

/**
 SQL数据类型

 @param charType 对象模型属性类型
 */
- (NSString *)sqlTypeWithChar:(const char *)charType {
    
    NSString *str = [NSString stringWithFormat:@"%s", charType];
    
    if ([str isEqualToString:@"B"]) return @"INTEGER";                          // BOOL 类型
    if ([str isEqualToString:@"q"]) return @"INTEGER";                          // NSInteger 类型
    if ([str isEqualToString:@"i"]) return @"INTEGER";                          // int 类型
    if ([str isEqualToString:@"Q"]) return @"INTEGER";                          // NSUInteger 类型
    
    if ([str isEqualToString:@"f"]) return @"REAL";                             // 浮点类型
    if ([str isEqualToString:@"d"]) return @"REAL";                             // Double 类型
    
    if ([str isEqualToString:@"@\"NSString\""]) return @"TEXT";                 // 字符串
    if ([str isEqualToString:@"@\"NSMutableString\""]) return @"TEXT";          // 字符串
    
    return @"BLOB"; // 对象类型
}

/**
 判断一个表是否存在

 @param tableName 表名
 */
- (BOOL)tableIsExist:(NSString *)tableName {
    
    __block BOOL isExist = NO;
    
    NSString *sqlString = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", tableName];
    
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if ([db open]) {
            FMResultSet *result = [db executeQuery:sqlString];
            while ([result next]) {
                NSInteger count = [result intForColumn:@"countNum"];
                if (count == 1) {
                    isExist = YES;
                }
            }
            [result close];
            
            [self closeDataBase:db];
        }
    }];
    
    return isExist;
}

/**
 关闭数据库

 @param db 数据库管理
 */
- (void)closeDataBase:(FMDatabase *)db {
    
    if ([db open]) {
        [db close];
    }
}


#pragma mark - Protocol


#pragma mark - 懒加载

- (FMDatabaseQueue *)dbQueue {
    
    if (_dbQueue == nil) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self filePath]];
    }
    
    return _dbQueue;
}

- (NSMutableArray *)valuesArray {
    
    if (_valuesArray == nil) {
        _valuesArray = [[NSMutableArray alloc] init];
    }
    
    return _valuesArray;
}

@end
