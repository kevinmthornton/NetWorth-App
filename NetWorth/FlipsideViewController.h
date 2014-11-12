//
//  FlipsideViewController.h
//  NetWorth
//
//  Created by kevin thornton on 5/7/14.
//  Copyright (c) 2014 kevin thornton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class FlipsideViewController;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

@interface FlipsideViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UINavigationItem *topNavigationItem;

@property (weak, nonatomic) IBOutlet UIButton *updateBtn;
// for CD, handed down from AppDelegate
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (weak, nonatomic) id <FlipsideViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIButton *addButton;
@property (strong, nonatomic) IBOutlet UITextField *symbolTextField;
@property (strong, nonatomic) IBOutlet UITextField *quantityTextField;
@property (strong, nonatomic) IBOutlet UITableView *symbolTableView;
@property (strong, nonatomic) IBOutlet UILabel *symbolLabel;


@property (strong, nonatomic) IBOutlet UIScrollView *symbolScrollViewContainer;

// for holding symbols and quantities for editing
@property NSMutableArray *symbolArray;
@property NSMutableArray *quantityArray;

//
//-(void)listSymbolsInScrollView;

// when a text field is edited, update the amounts in the array
// -(void)updateSymbolArray:(UITextField *)textFieldUpdated;

// button in upper right to press when you update symbol amounts text fields in symbolScrollViewContainer
-(void)updateSymbolAmounts:(NSString *)symbol quantity:(NSString *)quantity;

// add button to put symbol into CD
- (IBAction)addSymbolToCoreData;

// tap a button and this symbol is removed from the list
-(void)removeSymbolFromCoreData:(UIButton *)symbolToBeRemoved;

// go back to main view
- (IBAction)done:(id)sender;

// ** keyboard
// register the notification for the keyboard actions
- (void)registerForKeyboardNotifications;
- (IBAction)dismissKeyboard:(UIButton *)senderButton;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWillBeHidden:(NSNotification*)aNotification;


@end
