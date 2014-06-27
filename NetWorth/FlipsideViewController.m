//
//  FlipsideViewController.m
//  NetWorth
//
//  Created by kevin thornton on 5/7/14.
//  Copyright (c) 2014 kevin thornton. All rights reserved.
//

#import "FlipsideViewController.h"
#import "Securities.h"

@interface FlipsideViewController ()

@end

@implementation FlipsideViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize appDelegate;
@synthesize symbolTextField = _symbolTextField;
@synthesize quantityTextField = _quantityTextField;
@synthesize symbolScrollViewContainer = _symbolScrollViewContainer;
@synthesize symbolArray = _symbolArray;
@synthesize quantityArray = _quantityArray;

#pragma mark - Actions

// list out the symbols in labels on the scrollview
-(void)listSymbolsInScrollView {
    // delete all subviews; both labels and text fields
    for (UILabel *subview in self.symbolScrollViewContainer.subviews) {
        [subview removeFromSuperview];
    }
    for (UITextField *subview in self.symbolScrollViewContainer.subviews) {
        [subview removeFromSuperview];
    }
    
    // make sure to fetch
    [self.fetchedResultsController performFetch:nil];
    // query CD
    if (![[self.fetchedResultsController fetchedObjects] count] > 0 ) {
        NSLog(@"!!!!! ~~> There's nothing in the database from flip");
    } else {
        // set up the starting Y value so you can add and move down
        float startY = 10;
        
        // add in a TAG for each of these as an identifier
        // create two arrays with symbolArray[TAG] = security.symbol
        // and quantityArray[TAG] = security.quantity
        int tagIncrement = 0;
        
        // for each security in CD, right out the label and the text field
        for(Securities *security in [self.fetchedResultsController fetchedObjects]) {
            // create the label that sits on top of the shadow
            UILabel *securityLabel = [[UILabel alloc] init];
            securityLabel.text = security.symbol;
            securityLabel.tag = tagIncrement;
            securityLabel.textColor = [UIColor whiteColor];
            securityLabel.frame = CGRectMake(16,startY,90,30);
            [self.symbolScrollViewContainer addSubview:securityLabel];
            // add the security symbol to the array for editing
            [self.symbolArray insertObject:security.symbol atIndex:tagIncrement];
            
            // now create the text field with the quantity
            UITextField *securityQuantity = [[UITextField alloc] initWithFrame:CGRectMake(110, startY, 90, 30)];
            // convert from nssnumber to nnsstring
            securityQuantity.text = [security.quantity stringValue];
            securityQuantity.tag = tagIncrement;
            [securityQuantity setBackgroundColor:[UIColor whiteColor]];
            [self.symbolScrollViewContainer addSubview:securityQuantity];
            // add the security symbol to the array for editing
            [self.quantityArray insertObject:security.quantity atIndex:tagIncrement];
            
            // add a method so that when the amount is changed, the array is updated
            [securityQuantity addTarget:self
                            action:@selector(updateSymbolArray:)
                  forControlEvents:UIControlEventEditingChanged];
            
            // hide the keyboard when done
            [securityQuantity resignFirstResponder];
            
            // REMOVE button w/ TAG for removal of this security
            // create a - button to get rid of this security all together
            // when tapped, it executes removeSymbolFromArray which takes it out and re-draws this scrollview with a new fetch
            UIButton *securityRemoveButton = [[UIButton alloc] init];
            securityRemoveButton.tag = tagIncrement;
            securityRemoveButton.frame = CGRectMake(210, startY, 30, 30);
            [securityRemoveButton setTitle:@"-" forState:UIControlStateNormal];
            [securityRemoveButton setBackgroundColor:[UIColor redColor]];
            [securityRemoveButton setUserInteractionEnabled:YES];
            [securityRemoveButton addTarget:self action:@selector(removeSymbolFromArray:) forControlEvents:UIControlEventTouchDown];
            [self.symbolScrollViewContainer addSubview:securityRemoveButton];
            
            
            // increment to move down
            startY += 40;
            tagIncrement++;
        } // for
    } // else
} // end listSymbolsInScrollView

-(void)updateSymbolArray:(UITextField *)textFieldUpdated{
   // NSLog(@"textfield value: %@ - tag: %ld", [textFieldUpdated text], (long)textFieldUpdated.tag);
    [self.quantityArray replaceObjectAtIndex:textFieldUpdated.tag withObject:textFieldUpdated.text];
}

// get code from httpjsonrequest to list out labels in order
- (IBAction)updateSymbolAmounts {
    for (int arrayIncrementor = 0; arrayIncrementor <= ([self.symbolArray count] -1 ); arrayIncrementor++) {
        // update core data based on the order in the array
        
        NSError *error = nil;
        
        //This is your NSManagedObject subclass
        Securities *security = nil;
        
        //Set up to get the symbol you want to update
        NSFetchRequest * request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"Securities" inManagedObjectContext:self.managedObjectContext]];
        // set the predicate to search for the symbol from the symbolArray
        [request setPredicate:[NSPredicate predicateWithFormat:@"symbol=%@",[self.symbolArray objectAtIndex:arrayIncrementor]]];
        
        //Ask for it
        security = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
        
        if (error) {
            //Handle any errors
            NSLog(@"we had an error right away");
        }
        
        if (!security) {
            //Nothing there to update
            NSLog(@"didn't find any security");
        }
        
        
        // REMOVING FROM ARRAY BUT, not can't iterate over array because we are missing this number!!!!
        
        
        if ([[self.quantityArray objectAtIndex:arrayIncrementor] isKindOfClass:[NSString class]]) {
            // this is a string so, format it correctly
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            [security setQuantity:[f numberFromString:[self.quantityArray objectAtIndex:arrayIncrementor]]];
        } else {
            [security setQuantity:[self.quantityArray objectAtIndex:arrayIncrementor]];
        }
    }
    
    // save
    [self.managedObjectContext save:nil];
    
    // performFetch after SAVE so we can refill the fetched results controller
    [self.fetchedResultsController performFetch:nil];
    
    // call list symbols to reload the results in the scroll view
    // [self listSymbolsInScrollView];
    
}

// from the add button at the top
- (IBAction)addSymbolToCoreData {
    // insert new security into core data
    Securities *security = [NSEntityDescription insertNewObjectForEntityForName:@"Securities" inManagedObjectContext:self.managedObjectContext];
    // get values from text fields
    security.symbol = self.symbolTextField.text;
    // from text field nsstring to nsnumber
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *symbolQuantity = [f numberFromString:self.quantityTextField.text];
    security.quantity = symbolQuantity;
    
    // save
    [self.managedObjectContext save:nil];
    
    // performFetch after SAVE so we can refill the fetched results controller
    [self.fetchedResultsController performFetch:nil];

    // call list symbols to reload the results in the scroll view
    [self listSymbolsInScrollView];
}

// - button next to symbols that will remove from core data and re-draw table with a new fetch
-(void)removeSymbolFromArray:(UIButton *)symbolToBeRemoved {
    [self.quantityArray removeObjectAtIndex:symbolToBeRemoved.tag];
    [self updateSymbolAmounts];
    [self listSymbolsInScrollView];
}

// hooked to the done button in the upper left; tell my delegate(MainViewController) to execute flipsideViewControllerDidFinish on self(this || FlipsideViewController)
- (IBAction)done:(id)sender {
    [self.delegate flipsideViewControllerDidFinish:self];
}

// used to start off the action of listing out the symbols currently held in CD
-(void)viewWillAppear:(BOOL)animated{
   [self listSymbolsInScrollView];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    /*
     this is set up in MainViewController > prepareForSegue:
     // this works but, up for debate on corect coding
     // set up self.managedObjectContext from AppDelegate
     appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
     self.managedObjectContext = appDelegate.managedObjectContext;
    */
    // set up the fetchedResultsController
    NSString *entitySecurities = @"Securities"; // The entity in your model
    NSFetchRequest *requestSecurities = [NSFetchRequest fetchRequestWithEntityName:entitySecurities];
    // sort
    requestSecurities.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"symbol"
                                                                                               ascending:YES
                                                                                                selector:@selector(localizedCaseInsensitiveCompare:)]];
    // set up
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:requestSecurities
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil cacheName:nil];
    
    // set up the two arrays for editing
    self.symbolArray = [[NSMutableArray alloc] init];
    self.quantityArray = [[NSMutableArray alloc] init];
}


- (void)awakeFromNib
{
    [super awakeFromNib];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
