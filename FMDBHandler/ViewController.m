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

@property (nonatomic, assign) int i;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _i = 0;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self createdModel];
}

- (void)createdModel {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Person *person = [Person new];
        person.name = [NSString stringWithFormat:@"%ld", (long)self.i];
        person.age = self.i;
        person.sex = PersonSexMan;
        [self insertDataWithModel:person];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *result = [[FMDBHandler shareInstance] getDataWithTableName:@"Person" classObject:[Person class] columName:@"age" columnValue:[NSNumber numberWithInt:self.i]];
        NSLog(@"查询结果 %ld", result.count);
    });
    self.i++;
}

- (void)insertDataWithModel:(Person *)person {
    
    [[FMDBHandler shareInstance] insertData:person tableName:@"Person"];
}


@end
