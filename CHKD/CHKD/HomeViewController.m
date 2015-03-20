//
//  HomeViewController.m
//  CHKD
//
//  Created by ravi pitapurapu on 10/27/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import "HomeViewController.h"

#import "TrainingViewController.h"
#import "DemoViewController.h"

#define SEG_ID_TRAINING_VIEW_LOADER @"SEG_ID_TRAINING_VIEW_LOADER"
#define SEG_ID_DEMO_VIEW_LOADER @"SEG_ID_DEMO_VIEW_LOADER"

@interface HomeViewController ()

@property (nonatomic, weak) IBOutlet UIButton *btnTraining;
@property (nonatomic, weak) IBOutlet UIButton *btnDemo;

@end

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = @"Home View Controller";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnTrainingTapped:(id)sender
{
    [self performSegueWithIdentifier:SEG_ID_TRAINING_VIEW_LOADER sender:self];
}

- (IBAction)btnDemoTapped:(id)sender
{
    [self performSegueWithIdentifier:SEG_ID_DEMO_VIEW_LOADER sender:self];
}

@end
