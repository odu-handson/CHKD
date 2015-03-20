//
//  TestViewController.m
//  CHKD
//
//  Created by ravi pitapurapu on 10/7/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import "TestViewController.h"

@interface TestViewController ()

@property (nonatomic, weak) IBOutlet UITextField *txta;
@property (nonatomic, weak) IBOutlet UITextField *txtb;
@property (nonatomic, weak) IBOutlet UITextField *txtTime;
@property (nonatomic, weak) IBOutlet UILabel *lblResult;
@property (nonatomic, weak) IBOutlet UIButton *btnCalc;

@property (nonatomic,assign) double y;
@property (nonatomic,assign) double x;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self addCustomButtonToKeyBoardWithField:self.txta];
    [self addCustomButtonToKeyBoardWithField:self.txtb];
    [self addCustomButtonToKeyBoardWithField:self.txtTime];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnCalacTapped:(id)sender
{
    self.x = 1 / [self.txtTime.text doubleValue];
    self.y = ([self.txta.text doubleValue] * self.x * self.x) + ([self.txtb.text doubleValue] * self.x);
    double result = [self.txtTime.text doubleValue] * self.y;
    self.lblResult.text = [NSString stringWithFormat:@"%f",result];
}

- (void)addCustomButtonToKeyBoardWithField:(UITextField *)textField
{
    // My app is restricted to portrait-only, so the following works
    UIToolbar *numberPadAccessoryInputView      = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0f)];
    
    // My app-wide tint color is a gold-ish color, so darkGray contrasts nicely
    numberPadAccessoryInputView.barTintColor    = [UIColor lightGrayColor];
    
    // A basic "Done" button, that calls [self.textField resignFirstResponder]
    UIBarButtonItem *numberPadDoneButton        = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:textField action:@selector(resignFirstResponder)];
    
    // It's the only item in the UIToolbar's items array
    numberPadAccessoryInputView.items           = @[numberPadDoneButton];
    
    // In case the background of the view is similar to [UIColor darkGrayColor], this
    // is put as a contrasting edge line at the top of the UIToolbar
    UIView *topBorderView                       = [[UIView alloc] initWithFrame:CGRectMake(0, 0, numberPadAccessoryInputView.frame.size.width, 1.0f)];
    topBorderView.backgroundColor               = [UIColor whiteColor];
    [numberPadAccessoryInputView addSubview:topBorderView];
    
    // Make it so that this UITextField shows the UIToolbar
    textField.inputAccessoryView           = numberPadAccessoryInputView;
}
- (void)resignFirstResponder:(id)sender
{
    [sender resignFirstResponder];
}

@end
