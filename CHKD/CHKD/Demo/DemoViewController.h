//
//  DemoViewController.h
//  CHKD
//
//  Created by ravi pitapurapu on 10/27/14.
//  Copyright (c) 2014 Old Dominion University. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DemoViewController : UIViewController<NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;


@end
