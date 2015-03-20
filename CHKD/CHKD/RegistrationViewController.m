//
//  RegistrationViewController.m
//  CHKD
//
//  Created by ravi pitapurapu on 2/18/15.
//  Copyright (c) 2015 Old Dominion University. All rights reserved.
//

#import "RegistrationViewController.h"
#import "RegistrationTableViewCell.h"
#import "ServiceManager.h"
#import "LoginViewController.h"


@interface RegistrationViewController ()<UITextFieldDelegate,ServiceProtocol>

@property (nonatomic, strong) NSMutableArray *textFieldArray;
@property (nonatomic, strong) NSMutableArray *flags;
@property (nonatomic, strong) NSMutableArray *data;
@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (nonatomic, strong) ServiceManager *serviceManager;
@property (nonatomic, strong) LoginViewController    *loginViewController;



@end

@implementation RegistrationViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareData];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title=@"Registration";
    
}

- (ServiceManager *)serviceManager
{
    if(!_serviceManager)
    {
        _serviceManager = [ServiceManager defaultManager];
        _serviceManager.serviceDelegate = self;
    }
    
    return  _serviceManager;
}


- (void)prepareData
{
    self.textFieldArray = [[NSMutableArray alloc] init];
    self.data = [[NSMutableArray alloc] init];
    
    [self.data addObject:@"First Name"];
    [self.data addObject:@"Last Name"];
    [self.data addObject:@"UserName"];
    [self.data addObject:@"Password"];
    [self.data addObject:@"Reenter Password"];
    
    //self.btnContinue.layer.cornerRadius = 5.0f;
    self.flags = [[NSMutableArray alloc] initWithObjects:@"0",@"0",@"0",@"0",@"0",@"0",@"0", nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.data.count+1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if(indexPath.row == 5)
    {
        UITableViewCell *cell;
        cell = [tableView dequeueReusableCellWithIdentifier:@"ContinueCell" forIndexPath:indexPath];
        return cell;
    }
    else
    {
        RegistrationTableViewCell *cell;
        cell = (RegistrationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"RegistrationCell" forIndexPath:indexPath];
        cell.txtField.placeholder = [self.data objectAtIndex:indexPath.row];
        cell.txtField.delegate = self;
        if(indexPath.row == 3|| indexPath.row == 4)
            cell.txtField.secureTextEntry = YES;
        
        [self.textFieldArray addObject:cell.txtField];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *returnValue;
    returnValue = self.headerView;
    
    returnValue.hidden = NO;
    
    return returnValue;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat returnValue;
    
    returnValue = self.headerView.frame.size.height;
    
    return returnValue;
}

- (IBAction)registrationTapped:(id)sender
{
    
    NSMutableDictionary *parameters =[self prepareParameters];
    
    self.serviceManager = [ServiceManager defaultManager];
    self.serviceManager.serviceDelegate = self;
    
    NSString *url = @"http://128.82.5.142:8080/register";
    [self.serviceManager postRequestCallWithURL:url andParameters:parameters];
    
}


-(NSMutableDictionary *) prepareParameters
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    UITextField *requiredTextField =(UITextField *) [self.textFieldArray  objectAtIndex:0];
    
    [parameters setObject:requiredTextField.text forKey:@"firstName"];
    requiredTextField = [self.textFieldArray  objectAtIndex:1];
     [parameters setObject:requiredTextField.text  forKey:@"lastName"];
    requiredTextField = [self.textFieldArray  objectAtIndex:2];
    
    [parameters setObject:requiredTextField.text forKey:@"username"];
    requiredTextField = [self.textFieldArray  objectAtIndex:3];
    [parameters setObject:requiredTextField.text forKey:@"password"];
    requiredTextField = [self.textFieldArray  objectAtIndex:4];
    [parameters setObject:requiredTextField.text  forKey:@"password_confirmation"];
    
    return parameters;
    
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    //indexOfCurrentActiveTextField = [self.textFieldArray indexOfObject:textField];
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    switch ([self.data indexOfObject:textField.placeholder]) {
        case 0:
            
            if(textField.text.length >0)
                [self handleValidationClearOnTextField:textField atIndex:0];
            else
                [self handleValidationIssueOnTextField:textField atIndex:0];
            
            break;
        case 1:
            
            if(textField.text.length > 0)
                [self handleValidationClearOnTextField:textField atIndex:1];
            else
                [self handleValidationIssueOnTextField:textField atIndex:1];
            
            break;
        case 2:
            
            if(textField.text.length > 2)
                [self handleValidationClearOnTextField:textField atIndex:2];
            else
                [self handleValidationIssueOnTextField:textField atIndex:2];
            
            break;
        case 3:
            
            if(textField.text.length>0)
                [self handleValidationClearOnTextField:textField atIndex:3];
            else
                [self handleValidationIssueOnTextField:textField atIndex:3];
            
            break;
        case 4:
        {
            UITextField *passwordTextField = [self.textFieldArray objectAtIndex:3];
            if(textField.text.length > 0 && [passwordTextField.text isEqualToString:textField.text])
                [self handleValidationClearOnTextField:textField atIndex:4];
            else
                [self handleValidationIssueOnTextField:textField atIndex:4];
            break;
        }
            
        default:
            break;
    }
    
}

- (void)handleValidationIssueOnTextField:(UITextField *)textField atIndex:(NSInteger)index
{
    [self.flags replaceObjectAtIndex:index withObject:@"0"];
    textField.backgroundColor = [UIColor redColor];
}

- (void)handleValidationClearOnTextField:(UITextField *)textField atIndex:(NSInteger)index
{
    [self.flags replaceObjectAtIndex:index withObject:@"1"];
    textField.backgroundColor = [UIColor whiteColor];
}

- (void)showAlertWithMessage:(NSString *)message andTitle:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

- (BOOL)verifyFields
{
    BOOL returnValue;
    for (int i=0 ; i < self.flags.count; i++)
        [self textFieldDidEndEditing:[self.textFieldArray objectAtIndex:i]];
    
    if([self.flags containsObject:@"0"])
        [self showAlertWithMessage:@"Please fill in all fields in red to continue." andTitle:@"Invalid fields in form"];
    else
        returnValue = YES;
    
    [self resignFirstResponder];
    
    return returnValue;
}

- (void)serviceCallCompletedWithResponseObject:(id)response
{
    NSDictionary *serviceResponse = (NSDictionary *) response;
    NSString *success = [serviceResponse valueForKey:@"success"];
    
    if([success boolValue ]== 1)
    {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        self.loginViewController = (LoginViewController *) [storyBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:self.loginViewController animated:YES];
    }
    
}

- (void)serviceCallCompletedWithError:(NSError *)error
{
    
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
