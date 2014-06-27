//
//  MainViewController.h
//  NetWorth
//
//  Created by kevin thornton on 5/7/14.
//  Copyright (c) 2014 kevin thornton. All rights reserved.
//

#import "FlipsideViewController.h"

#import <CoreData/CoreData.h>

@class Securities;

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate>

@property float totalNetWorth;
@property (strong, nonatomic) UILabel *netWorthAmountLabel;
@property (strong, nonatomic) NSString *totalNetWorthString;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

// UI
@property (strong, nonatomic) UITextView *noSymbolTextField;
@property (strong, nonatomic) IBOutlet UIView *labelHolderView;

// start the core data process to either get symbols or say we don't have any
-(void)startUpCoreDataSymbols;

// create the label to display with symbol and amount
-(void)createLabel:(Securities *)security  startY:(int)startY;

// call out to yahoo api to get json data of symbol
-(NSArray *)getSecurityInfo:(NSString *)symbol quantity:(NSNumber *)quantity;

-(void)writeLabelToView:(NSArray *)symbolArray startY:(int)startY;

-(void)displayNetWorth;

@end
