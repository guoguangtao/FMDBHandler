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
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(20, 100, self.view.bounds.size.width - 40, 50)];
    button.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:button];
    
    Person *person = [[Person alloc] init];
    person.age = 30;
    person.name = @"Jack";
    person.number = @20;
    [[FMDBHandler shareInstance] inserData:person tableName:@"Person"];
}


@end
