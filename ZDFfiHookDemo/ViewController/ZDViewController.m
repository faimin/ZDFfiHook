//
//  ZDViewController.m
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2020/6/22.
//  Copyright © 2020 Zero.D.Saber. All rights reserved.
//

#import "ZDViewController.h"
#import <ZDFfiHook/ZDFfiHook.h>
#import "AController.h"

@interface ZDViewController ()
@property (nonatomic, strong) AController *aController;
@end

@implementation ZDViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self hook];
    }
    return self;
}

- (void)hook {
    self.aController = [AController new];
    
    __weak typeof(self) weakTarget = self;
    [self.aController zd_hookInstanceMethod:@selector(viewDidLoad) option:ZDHookOption_After callback:^{
        NSLog(@"viewDidLoad");
        __strong typeof(weakTarget) self = weakTarget;
        id v = [self.aController exe];
        NSLog(@"%@", v);
    }];
    
    [self.aController zd_hookInstanceMethod:@selector(viewWillAppear:) option:ZDHookOption_After callback:^(BOOL animated){
        NSLog(@"viewWillAppear:%d", animated);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (IBAction)push:(UIButton *)sender {
    self.aController.view.backgroundColor = UIColor.orangeColor;
    [self.navigationController pushViewController:self.aController animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
