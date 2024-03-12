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
@property (nonatomic, strong) NSMutableArray *valuesArray; /**< SQL Values */
@property (nonatomic, strong) dispatch_queue_t insertQueue; /**< 插入数据队列 */

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

- (instancetype)init {
    
    if (self = [super init]) {
        _insertQueue = dispatch_queue_create("com.gcd.queueCreate.currentQueue", DISPATCH_QUEUE_SERIAL);
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self filePath]];
        _valuesArray = [[NSMutableArray alloc] init];
    }
    
    return self;
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
    
    // 插入单个数据
    [self insertSimpleData:classObject tableName:tableName];
}

/**
 插入数组
 
 @param dataArray 数组
 @param tableName 表名
 @param transaction 是否用事务方式插入 YES（事务）/NO（非事务）
 */
- (void)insertDatas:(NSArray *)dataArray tableName:(NSString *)tableName transaction:(BOOL)transaction {
    
    // 表格的判断和创建
    if (dataArray.count) {
        [self tableName:tableName classObject:[dataArray firstObject]];
    }
    
    if (transaction) {
        // 使用事务插入
        dispatch_async(self.insertQueue, ^{
            [self insertDatasByTransaction:dataArray tableName:tableName];
        });
    } else {
        // 插入数据库
        dispatch_async(self.insertQueue, ^{
            for (id object in dataArray) {
                [self insertSimpleData:object tableName:tableName];
            }
        });
    }
}

/**
 通过事务插入数据

 @param dataArray 数组
 @param tableName 表名
 */
- (void)insertDatasByTransaction:(NSArray *)dataArray tableName:(NSString *)tableName {
    
    __block BOOL result = YES;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        NSLog(@"当前线程:%@", [NSThread currentThread]);
        if ([db open]) {
            for (id object in dataArray) {
                NSString *sqlString = [NSString stringWithFormat:@"INSERT INTO %@%@", tableName, [self insertSqlStringWithClassObject:object]];
                result = [db executeUpdate:sqlString withArgumentsInArray:self.valuesArray] & result;
            }
            if (!result) {
                NSLog(@"插入失败");
            }
        }
    }];
}

/**
 插入单条数据

 @param classObject 需要插入的对象
 @param tableName 表名
 */
- (void)insertSimpleData:(id)classObject tableName:(NSString *)tableName {
    
    // 插入数据
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSLog(@"当前线程:%@", [NSThread currentThread]);
        if ([db open]) {
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@%@", tableName, [self insertSqlStringWithClassObject:classObject]];
            if ([db executeUpdate:sql withArgumentsInArray:self.valuesArray]) {
                NSLog(@"数据插入成功");
            } else {
                NSLog(@"数据插入失败");
            }
        }
    }];
}

/// 删除某个表格所有数据
/// @param tableName 表名
- (void)deleteAllDataWithTableName:(NSString *)tableName {
    
    dispatch_async(self.insertQueue, ^{
        if ([self tableIsExist:tableName]) {
            [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
                NSLog(@"当前线程:%@", [NSThread currentThread]);
                if ([db open]) {
                    NSString *sql = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
                    BOOL success = [db executeUpdate:sql];
                    if (success) {
                        NSLog(@"删除 %@ 表成功", tableName);
                    } else {
                        NSLog(@"删除 %@ 表失败", tableName);
                    }
                }
            }];
        }
    });
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
- (void)deletedDataWithTableName:(NSString *)tableName columnNames:(NSArray *)columnNames values:(NSArray *)values whereType:(FMDBHandlerWhereSQLType)whereType {
    
    if ([self tableIsExist:tableName]) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                
                // SQL语句拼接
                NSMutableString *sqlString = [NSMutableString stringWithString:[NSString stringWithFormat:@"DELETE FROM %@ %@", tableName, [self whereSQLStringWithColumnNames:columnNames whereType:whereType]]];
                BOOL success = [db executeUpdate:sqlString withArgumentsInArray:values];
                if (!success) NSLog(@"删除失败");
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
                if (!success) NSLog(@"更新失败");
            }
        }];
    }
}

/**
 多个条件更新数据
 
 @param tableName 表名
 @param columnNames 条件字段名
 @param columnValues 条件字段值
 @param updateColumnNames 需要更新的字段名数组
 @param updateColumnValues 需要更新的字段内容数组
 */
- (void)updateDataWithTableName:(NSString *)tableName columnNames:(NSArray *)columnNames columnValues:(NSArray *)columnValues updateColumnNames:(NSArray *)updateColumnNames updateColumnValues:(NSArray *)updateColumnValues whereType:(FMDBHandlerWhereSQLType)whereType {
    
    if ([self tableIsExist:tableName]) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                // SQL语句字符串拼接
                NSMutableString *sqlString = [NSMutableString stringWithFormat:@"UPDATE %@ SET", tableName];
                // 需要更新的字段
                for (int i = 0; i < updateColumnNames.count; i++) {
                    NSString *columnName = updateColumnNames[i];
                    if (i < updateColumnNames.count - 1) {
                        [sqlString appendFormat:@" %@ = ?,", columnName];
                    } else {
                        [sqlString appendFormat:@" %@ = ? ", columnName];
                    }
                }
                // 查询条件
                [sqlString appendString:[self whereSQLStringWithColumnNames:columnNames whereType:whereType]];
                NSMutableArray *arguments = [NSMutableArray arrayWithArray:updateColumnValues];
                [arguments addObjectsFromArray:columnValues];
                BOOL success = [db executeUpdate:sqlString withArgumentsInArray:arguments];
                if (!success) NSLog(@"更新失败");
            }
        }];
    }
}

/**
 根据单个条件获取数据
 
 @param tableName 表名
 @param columnName 条件字段名
 @param value 条件字段值
 */
- (NSArray *)getDataWithTableName:(NSString *)tableName classObject:(id)classObject columName:(NSString *)columnName columnValue:(id)value {
    
    __block NSMutableArray *resultArray = [NSMutableArray array];
    if ([self tableIsExist:tableName]) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", tableName, columnName];
                FMResultSet *resultSet = [db executeQuery:sqlString withArgumentsInArray:@[value]];
                while ([resultSet next]) {
                    // 数据解析
                    id classObj = [NSClassFromString(NSStringFromClass(classObject)) new];
                    [self classObject:classObj ResultSet:resultSet];
                    [resultArray addObject:classObj];
                }
                
                [resultSet close];
            }
        }];
    }
    
    return resultArray;
}

/**
 根据多个条件获取数据
 
 @param tableName 表名
 @param classObject 数据模型
 @param columnNames 条件字段名
 @param values 条件字段值
 */
- (NSArray *)getDataWithTableName:(NSString *)tableName classObject:(id)classObject columnNames:(NSArray *)columnNames columnValues:(NSArray *)values whereType:(FMDBHandlerWhereSQLType)whereType {
    
    __block NSMutableArray *resultArray = [NSMutableArray array];
    if ([self tableIsExist:tableName]) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@ %@", tableName, [self whereSQLStringWithColumnNames:columnNames whereType:whereType]];
                FMResultSet *resultSet = [db executeQuery:sqlString withArgumentsInArray:values];
                while ([resultSet next]) {
                    id classObj = [[NSClassFromString(NSStringFromClass(classObject)) alloc] init];
                    [self classObject:classObj ResultSet:resultSet];
                    [resultArray addObject:classObj];
                }
                
                [resultSet close];
            }
        }];
    }
    
    return resultArray;
}

/**
 获取所有数据

 @param tableName 表名
 @param classObject 类
 */
- (NSArray *)getAllDataWithTableName:(NSString *)tableName classObject:(id)classObject {
    
    __block NSMutableArray *resultArray = [NSMutableArray array];
    if ([self tableIsExist:tableName]) {
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([db open]) {
                NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
                FMResultSet *resultSet = [db executeQuery:sqlString];
                NSString *classString = NSStringFromClass(classObject);
                while ([resultSet next]) {
                    // 进行数据解析
                    id classObj = [[NSClassFromString(classString) alloc] init];
                    [self classObject:classObj ResultSet:resultSet];
                    [resultArray addObject:classObj];
                }
                
                [resultSet close];
            }
        }];
    }
    
    return resultArray;
}

/**
 执行自定义SQL更新语句
 
 @param sqlString SQL语句
 */
- (BOOL)executeUpdate:(NSString *)sqlString {
    
    __block BOOL result = NO;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if ([db open]) {
            result = [db executeUpdate:sqlString];
        }
    }];
    
    return result;
}

/**
 执行自定义SQL查询语句

 @param sqlString SQL查询语句
 @param classObject 模型数据
 */
- (NSArray *)executeQuery:(NSString *)sqlString classObject:(id)classObject {
    
    __block NSMutableArray *resultArray = [NSMutableArray array];
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if ([db open]) {
            FMResultSet *resultSet = [db executeQuery:sqlString];
            while ([resultSet next]) {
                id classObj = [[NSClassFromString(NSStringFromClass(classObject)) alloc] init];
                [self classObject:classObj ResultSet:resultSet];
                [resultArray addObject:classObj];
            }
            
            [resultSet close];
        }
    }];
    
    return resultArray;
}


#pragma mark - Private

/**
 WHERE语句拼接

 @param columnNames 条件数组
 */
- (NSString *)whereSQLStringWithColumnNames:(NSArray *)columnNames whereType:(FMDBHandlerWhereSQLType)whereType {
    
    NSString *str = whereType == FMDBHandlerWhereSQLTypeOr ? @"OR" : @"AND";
    NSMutableString *sqlString = [NSMutableString stringWithFormat:@"WHERE"];
    for (int i = 0; i < columnNames.count; i++) {
        NSString *columnName = columnNames[i];
        if (i < columnNames.count - 1) {
            [sqlString appendFormat:@" %@ = ? %@", columnName, str];
        } else {
            [sqlString appendFormat:@" %@ = ?", columnName];
        }
    }
    
    return sqlString;
}

/**
 利用运行时将数据赋值
 
 @param classObject 模型数据
 @param resultSet 结果集合
 */
- (void)classObject:(id)classObject ResultSet:(FMResultSet *)resultSet {
    
    unsigned int outCount = 0;
    Ivar *ivars = class_copyIvarList([classObject class], &outCount);
    for (unsigned int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        const char *name = ivar_getName(ivar);
        const char *type = ivar_getTypeEncoding(ivar);
        NSString *sqlType = [NSString stringWithCString:type encoding:NSUTF8StringEncoding];
        NSString *columnName = [[NSString stringWithCString:name encoding:NSUTF8StringEncoding] substringFromIndex:1];
        [self setupClassObject:classObject sqlType:sqlType name:columnName resultSet:resultSet];
    }
    free(ivars);
}

/**
 给数据模型赋值
 
 @param classObject 数据Model对象
 @param sqlType SQL数据类型
 @param name 属性名
 @param resultSet 查询结果集合
 */
- (void)setupClassObject:(id)classObject sqlType:(NSString *)sqlType name:(NSString *)name resultSet:(FMResultSet *)resultSet {
    
    if ([sqlType isEqualToString:@"B"]) {
        // BOOL 类型
        [classObject setValue:[NSNumber numberWithBool:[resultSet boolForColumn:name]] forKey:name];
    } else if ([sqlType isEqualToString:@"q"]) {
        // NSInteger 类型
        [classObject setValue:[NSNumber numberWithInteger:[resultSet longForColumn:name]] forKey:name];
    } else if ([sqlType isEqualToString:@"i"]) {
        // int 类型
        [classObject setValue:[NSNumber numberWithInt:[resultSet intForColumn:name]] forKey:name];
    } else if ([sqlType isEqualToString:@"Q"]) {
        // NSUInteger 类型
        [classObject setValue:[NSNumber numberWithUnsignedInteger:[resultSet unsignedLongLongIntForColumn:name]] forKey:name];
    } else if ([sqlType isEqualToString:@"f"]) {
        // 浮点类型
        [classObject setValue:[NSNumber numberWithFloat:[resultSet doubleForColumn:name]] forKey:name];
    } else if ([sqlType isEqualToString:@"d"]) {
        // Double 类型
        [classObject setValue:[NSNumber numberWithDouble:[resultSet doubleForColumn:name]] forKey:name];
    } else if ([sqlType isEqualToString:@"@\"NSString\""] || [sqlType isEqualToString:@"@\"NSMutableString\""]) {
        // 字符串
        [classObject setValue:[resultSet stringForColumn:name] forKey:name];
    } else {
        // 对象类型
        NSData *data = [resultSet objectForColumn:name];
        [classObject setValue:[NSKeyedUnarchiver unarchiveObjectWithData:data] forKey:name];
    }
}

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
    [self.valuesArray removeAllObjects];
    for (unsigned int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        const char *name = ivar_getName(ivar);
        const char *type = ivar_getTypeEncoding(ivar);
        NSString *nameStr = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        NSString *typeString = [self sqlTypeWithChar:type];
        id value = [classObject valueForKeyPath:nameStr];
        if ([typeString isEqualToString:@"BLOB"]) {
            value = [NSKeyedArchiver archivedDataWithRootObject:value];
        }
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
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YXCDataBase.sqlite"];
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
        }
    }];
    
    return isExist;
}


#pragma mark - Protocol


#pragma mark - 懒加载

@end
