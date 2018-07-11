//
//  ViewController.m
//  FMDBHandler
//
//  Created by GGT on 2018/7/6.
//  Copyright © 2018年 GGT. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "FMDBHandler.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    Person *person = [[Person alloc] init];
//    person.age = 30;
//    person.name = @"Jack";
//    person.number = @20;
//    person.numberArray = @[@1, @"3", @"1", [NSDate date]];
//    [[FMDBHandler shareInstance] insertData:person tableName:@"Person"];
//    [[FMDBHandler shareInstance] deletedDataWithTableName:@"Person" columnNames:@[@"name", @"number"] values:@[@"Jack", @20]];
    
//    [[FMDBHandler shareInstance] updateDataWithTableName:@"Person" columnName:@"id" value:@1 updateColumnName:@"name" updateValue:@"Hello"];
//    [[FMDBHandler shareInstance] updateDataWithTableName:@"Person" columnNames:@[@"id", @"name"] columnValues:@[@1, @"渣渣"] updateColumnNames:@[@"number", @"testNumber"] updateColumnValues:@[@1, @1]];
    NSArray *personArray = [[FMDBHandler shareInstance] getAllDataWithTableName:@"Person" classObject:[Person class]];
    NSLog(@"%@", personArray);
}


@end
