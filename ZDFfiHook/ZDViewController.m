//
//  ZDViewController.m
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2020/6/22.
//  Copyright © 2020 Zero.D.Saber. All rights reserved.
//

#import "ZDViewController.h"
#import "NSObject+ZDFfiHook.h"
#import "AController.h"

@interface ZDViewController ()
@property (nonatomic, strong) AController *aController;
@end

@implementation ZDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.aController = [AController new];
    
    [self.aController zd_hookInstanceMethod:@selector(viewDidLoad) option:ZDHookOption_After callback:^{
        NSLog(@"viewDidLoad");
    }];
    
    [self.aController zd_hookInstanceMethod:@selector(viewWillAppear:) option:ZDHookOption_After callback:^(BOOL animated){
        NSLog(@"viewWillAppear:%d", animated);
    }];
}

- (IBAction)push:(UIButton *)sender {
    self.aController.view.backgroundColor = UIColor.redColor;
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
