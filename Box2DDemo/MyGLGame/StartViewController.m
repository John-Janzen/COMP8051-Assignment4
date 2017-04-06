//
//  StartViewController.m
//  MyGLGame
//
//  Created by John Janzen on 2017-04-05.
//  Copyright © 2017 BCIT. All rights reserved.
//

#import "StartViewController.h"
#include "GameViewController.h"

@interface StartViewController ()

@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    GameViewController *game = [segue destinationViewController];
    if ([[segue identifier] isEqualToString:@"ArkanoidsSegue" ]) {
        game->_type = true;
    } else if ([[segue identifier] isEqualToString:@"PongSegue" ]) {
        game->_type = false;
    }
}

@end
