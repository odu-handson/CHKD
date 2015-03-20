//
//  LoginViewController.m
//  CHKD
//
//  Created by ravi pitapurapu on 2/18/15.
//  Copyright (c) 2015 Old Dominion University. All rights reserved.
//

#import "LoginViewController.h"
#import "ServiceManager.h"
#import "HomeViewController.h"

@interface LoginViewController ()<ServiceProtocol>

@property (weak, nonatomic) IBOutlet UITextField *txtUserName;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UIScrollView *loginScrollView;

@property (nonatomic,strong) UITextField *activeField;
@property (nonatomic, strong) ServiceManager    *serviceManager;
@property (nonatomic, strong) HomeViewController    *homeViewController;
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic,strong) NSString *userId;



@end

@implementation LoginViewController


- (ServiceManager *)serviceManager
{
    if(!_serviceManager)
    {
        _serviceManager = [ServiceManager defaultManager];
        _serviceManager.serviceDelegate = self;
    }
    
    return  _serviceManager;
}

- (NSUserDefaults *)defaults
{
    if(!_defaults)
        _defaults = [NSUserDefaults standardUserDefaults];
    
    return _defaults;
}

-(void) awakeFromNib
{
     self.txtUserName.clipsToBounds = YES;
    self.txtUserName.layer.cornerRadius= 5.0f;
    self.txtPassword.clipsToBounds = YES;
    self.txtPassword.layer.cornerRadius = 5.0f;
    [self registerForKeyboardNotifications];
    self.navigationItem.hidesBackButton = YES;
   
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginTapped:(id)sender
{
    
    //NSDictionary *success = [NSDictionary ]
    
    NSMutableDictionary *parameters =[self prepareParameters];
    
    [self.serviceManager postRequestCallWithURL:@"http://128.82.5.142:8080/login" andParameters:parameters];

}

- (IBAction)regsiterTapped:(id)sender
{
    NSMutableDictionary *parameters =[self prepareParameters];
    
    [self.serviceManager postRequestCallWithURL:@"http://128.82.5.142:8080/walks" andParameters:parameters];

}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.loginScrollView.contentInset = contentInsets;
    self.loginScrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        [self.loginScrollView scrollRectToVisible:self.activeField.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.loginScrollView.contentInset = contentInsets;
    self.loginScrollView.scrollIndicatorInsets = contentInsets;
}



-(NSMutableDictionary *) prepareParameters
{
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    [parameters setObject:self.txtUserName.text forKey:@"username"];
    [parameters setObject:self.txtPassword.text forKey:@"password"];
    return parameters;
}

#pragma mark - ServiceProtocol Methods
- (void)serviceCallCompletedWithResponseObject:(id)response
{
    
    NSDictionary *serviceResponse = (NSDictionary *) response;
    
    NSString *success = [serviceResponse valueForKey:@"success"];
    NSString *userId = [serviceResponse valueForKey:@"user_id"];
    
    if([success boolValue ]== 1)
    {
        [self saveUserId:userId];
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        self.homeViewController = (HomeViewController *) [storyBoard instantiateViewControllerWithIdentifier:@"HomeViewController"];
        [self.navigationController pushViewController:self.homeViewController animated:YES];
    }
   
}

- (void)serviceCallCompletedWithError:(NSError *)error
{
    
}

- (void)saveUserId:(NSString *)userId
{
    [self.defaults setObject:userId  forKey:@"user_id"];
    self.userId = userId;
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
