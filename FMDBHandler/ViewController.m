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
    
    Person *person = [Person new];
    person.name = [NSString stringWithFormat:@"%ld", (long)self.i];
    person.age = self.i;
    person.sex = PersonSexMan;
    
    Person *son = [Person new];
    son.name = @"🙃";
    son.age = 12;
    son.sex = PersonSexMan;
    person.son = son;
    
    person.numberArray = @[son, son, son];
    
    [[FMDBHandler shareInstance] insertDatas:@[person, person, person, person] tableName:@"Person"];
    
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
        
        Person *son = [Person new];
        son.name = @"🙃";
        son.age = 12;
        son.sex = PersonSexMan;
        person.son = son;
        
        person.numberArray = @[son, son, son];
        
        [self insertDataWithModel:person];
    });
    
    self.i++;
}

- (void)insertDataWithModel:(Person *)person {
    
    [[FMDBHandler shareInstance] insertData:person tableName:@"Person"];
}


@end
