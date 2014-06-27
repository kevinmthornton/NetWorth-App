//
//  FlipsideViewController.h
//  NetWorth
//
//  Created by kevin thornton on 5/7/14.
//  Copyright (c) 2014 kevin thornton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class FlipsideViewController;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

@interface FlipsideViewController : UIViewController
@property (strong, nonatomic) AppDelegate *appDelegate;
// for CD, handed down from AppDelegate
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (weak, nonatomic) id <FlipsideViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UITextField *symbolTextField;
@property (strong, nonatomic) IBOutlet UITextField *quantityTextField;
@property (strong, nonatomic) IBOutlet UIScrollView *symbolScrollViewContainer;

// for holding symbols and quantities for editing
@property NSMutableArray *symbolArray;
@property NSMutableArray *quantityArray;

//
-(void)listSymbolsInScrollView;

// when a text field is edited, update the amounts in the array
-(void)updateSymbolArray:(UITextField *)textFieldUpdated;

// button in upper right to press when you update symbol amounts text fields in symbolScrollViewContainer
- (IBAction)updateSymbolAmounts;

// add button to put symbol into CD
- (IBAction)addSymbolToCoreData;

// tap a button and this symbol is removed from the list
-(void)removeSymbolFromCoreData:(UIButton *)symbolToBeRemoved;

// go back to main view
- (IBAction)done:(id)sender;

@end
