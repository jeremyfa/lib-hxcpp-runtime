//
//  ViewController.m
//  HXCPPRuntimeSampleApp
//
//  Created by Jeremy FAIVRE on 19/10/2015.
//  Copyright © 2015 Jeremy Faivre. All rights reserved.
//

#import "ViewController.h"

#import "HXCPPRuntime.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Init HXCPPRuntime
    [HXCPPRuntime sharedRuntime];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
