###### 数据模型
数据模型需要遵守 `NSCoding` 协议，和实现归档和解档方法，可以利用 `Runtime` 方式进行归档和解档，[这里](https://www.jianshu.com/p/67669eca6ca4) 有利用运行时进行归档和解档的方法实现，模型中基本数据类型不能用 `NSUInteger`，归档和解档会有问题。

###### 方法

```
/**
 初始化表格

 @param tableName 表名
 @param classObject 模型
 */
- (void)tableName:(NSString *)tableName classObject:(id)classObject;
```

```
/**
 插入数据
 
 @param classObject 需要插入的数据
 @param tableName 表名
 */
- (void)insertData:(id)classObject tableName:(NSString *)tableName;
```

```
/**
 按照单个条件删除某条数据

 @param tableName 表名
 @param columnName 条件字段名
 @param value 条件字段内容
 */
- (void)deletedDataWithTableName:(NSString *)tableName columnName:(NSString *)columnName value:(id)value;
```

```
/**
 按照多个条件删除某条数据

 @param tableName 表名
 @param columnNames 条件数组
 @param values 内容数组
 */
- (void)deletedDataWithTableName:(NSString *)tableName columnNames:(NSArray *)columnNames values:(NSArray *)values whereType:(FMDBHandlerWhereSQLType)whereType;
```

```

/**
 单个条件更新数据
 
 @param tableName 表名
 @param columnName 条件字段名
 @param value 条件字段值
 @param updateColumnName 需要更新的字段名
 @param updateValue 需要更新的字段内容
 */
- (void)updateDataWithTableName:(NSString *)tableName
                     columnName:(NSString *)columnName
                          value:(id)value
               updateColumnName:(NSString *)updateColumnName
                    updateValue:(id)updateValue;
```

```

/**
 多个条件更新数据

 @param tableName 表名
 @param columnNames 条件字段名
 @param columnValues 条件字段值
 @param updateColumnNames 需要更新的字段名数组
 @param updateColumnValues 需要更新的字段内容数组
 */
- (void)updateDataWithTableName:(NSString *)tableName
                    columnNames:(NSArray *)columnNames
                   columnValues:(NSArray *)columnValues
              updateColumnNames:(NSArray *)updateColumnNames
             updateColumnValues:(NSArray *)updateColumnValues
                      whereType:(FMDBHandlerWhereSQLType)whereType;
```

```
/**
 根据单个条件获取数据

 @param tableName 表名
 @param classObject 数据模型
 @param columnName 条件字段名
 @param value 条件字段值
 */
- (NSArray *)getDataWithTableName:(NSString *)tableName
                      classObject:(id)classObject
                        columName:(NSString *)columnName
                      columnValue:(id)value;
```

```
/**
 根据多个条件获取数据

 @param tableName 表名
 @param classObject 数据模型
 @param columnNames 条件字段名
 @param values 条件字段值
 */
- (NSArray *)getDataWithTableName:(NSString *)tableName
                      classObject:(id)classObject
                      columnNames:(NSArray *)columnNames
                     columnValues:(NSArray *)values
                        whereType:(FMDBHandlerWhereSQLType)whereType;
```

```
/**
 获取表所有数据

 @param tableName 表名
 */
- (NSArray *)getAllDataWithTableName:(NSString *)tableName classObject:(id)classObject;
```

```
/**
 执行自定义SQL更新语句

 @param sqlString SQL语句
 */
- (BOOL)executeUpdate:(NSString *)sqlString;
```

```
/**
 执行自定义SQL查询语句
 
 @param sqlString SQL查询语句
 @param classObject 模型数据
 */
- (NSArray *)executeQuery:(NSString *)sqlString classObject:(id)classObject;
```


