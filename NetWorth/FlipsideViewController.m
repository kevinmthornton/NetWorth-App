//
//  FlipsideViewController.m
//  NetWorth
//
//  Created by kevin thornton on 5/7/14.
//  Copyright (c) 2014 kevin thornton. All rights reserved.
//

#import "FlipsideViewController.h"
#import "Securities.h"
#import <QuartzCore/QuartzCore.h>

@interface FlipsideViewController ()

@end

@implementation FlipsideViewController

@synthesize topNavigationItem = _topNavigationItem;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize addButton = _addButton;
@synthesize symbolTextField = _symbolTextField;
@synthesize quantityTextField = _quantityTextField;
@synthesize symbolTableView = _symbolTableView;
@synthesize symbolLabel = _symbolLabel;
@synthesize symbolArray = _symbolArray;
@synthesize quantityArray = _quantityArray;

@synthesize symbolScrollViewContainer = _symbolScrollViewContainer;

#pragma mark - Actions


// RE-DO this as a table view with editable fields
#pragma mark - table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // only need one section
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // need count from JSON data
//    return self.symbolArray.count;
    return [[self.fetchedResultsController fetchedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"symbolCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

// they started editing the amount field
-(void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"symbolCell" forIndexPath:indexPath];
    if (cell) {
        NSIndexPath* indexPath = [tableView indexPathForCell:cell];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
    NSLog(@"started editing");
}

-(void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"finished editing");
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // I want this editable
    return YES;
}

// delete the row from the table and from core data
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
     NSLog(@"deleting object: %@", [self.fetchedResultsController objectAtIndexPath:indexPath]);
     NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
     [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
     
     NSError *error = nil;
     if (![context save:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
         abort();
     }
     // refill the fetch results controller
     [self.fetchedResultsController performFetch:nil];
     [self.symbolTableView reloadData];
 }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // find the point in the table where we are
    CGPoint pointInTable = [textField.superview convertPoint:textField.frame.origin toView:self.symbolTableView];
    CGPoint contentOffset = self.symbolTableView.contentOffset;
    // figure out how high to move this
    contentOffset.y = (pointInTable.y - textField.inputAccessoryView.frame.size.height);
    // move it's contentOffset
    [self.symbolTableView setContentOffset:contentOffset animated:YES];
    // show the Done button in the upper right
    self.topNavigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissKeyboard:)];
    
    return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    // get the current indexPath from the textField's superview that was passed in; best way??
    NSIndexPath *indexPath = [self.symbolTableView indexPathForCell:(UITableViewCell *)[[textField superview] superview]];
    Securities *security = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // update core data with the new amount and symbol from the table cell
    [self updateSymbolAmounts:security.symbol quantity:textField.text];
    
    [textField resignFirstResponder];
    
    // move this back down
    if ([textField.superview.superview isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell*)textField.superview.superview;
        NSIndexPath *indexPath = [self.symbolTableView indexPathForCell:cell];
        
        [self.symbolTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:TRUE];
    }
    
    // hide the Done button in the upper right
    self.topNavigationItem.rightBarButtonItem = nil;
}

// custom cell set up
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    UILabel *symbolLabel = (UILabel *)[cell viewWithTag:1];
//    symbolLabel.text = [self.symbolArray objectAtIndex:indexPath.row];
    Securities *security =[self.fetchedResultsController objectAtIndexPath:indexPath];
    symbolLabel.text = security.symbol;
    UITextField *symbolTextField = (UITextField *)[cell viewWithTag:2];
    symbolTextField.text = [NSString stringWithFormat:@"%@", security.quantity];
    symbolTextField.delegate = self;
    
}


/*
#pragma mark - symbols
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
            // TODO: check to make sure this is filled in
            [self.quantityArray insertObject:security.quantity atIndex:tagIncrement];
            
            // add a method so that when the amount is changed, the array is updated
            [securityQuantity addTarget:self
                            action:@selector(updateSymbolArray:)
                  forControlEvents:UIControlEventEditingChanged];
            
            // hide the keyboard when done
            [securityQuantity resignFirstResponder];
            
            // REMOVE button w/ TAG for removal of this security
            // create a - button to get rid of this security all together
            // when tapped, it executes removeSymbolFromCoreData which takes it out and re-draws this scrollview with a new fetch
            UIButton *securityRemoveButton = [[UIButton alloc] init];
            securityRemoveButton.tag = tagIncrement;
            securityRemoveButton.frame = CGRectMake(210, startY, 30, 30);
            [securityRemoveButton setTitle:@"-" forState:UIControlStateNormal];
            [securityRemoveButton setBackgroundColor:[UIColor redColor]];
            [securityRemoveButton setUserInteractionEnabled:YES];
            [securityRemoveButton addTarget:self action:@selector(removeSymbolFromCoreData:) forControlEvents:UIControlEventTouchDown];
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

*/



// hooked to the Update button in the upper left; tell my delegate(MainViewController) to execute flipsideViewControllerDidFinish on self(this || FlipsideViewController)
- (IBAction)done:(id)sender {
    // update the amounts and go back to the main a screen
//    [self updateSymbolAmounts];
    // set off the delegate method to go back to main
    [self.delegate flipsideViewControllerDidFinish:self];
}


#pragma mark - core data methods
// update core data from upper right button; get symbols in table and update amounts

-(void)updateSymbolAmounts:(NSString *)symbol quantity:(NSString *)quantity {
    NSError *error = nil;
    
    // NSManagedObject subclass
    Securities *security = nil;
    
    // set up to get the symbol you want to update
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Securities" inManagedObjectContext:self.managedObjectContext]];
    // set the predicate to search for the symbol from the symbolArray
    [request setPredicate:[NSPredicate predicateWithFormat:@"symbol=%@",symbol]];
    
    // ask for it
    security = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
    
    if (error) {
        //Handle any errors
        NSLog(@"we had an error right away");
    }
    
    if (!security) {
        //Nothing there to update
        NSLog(@"didn't find any security");
    }
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    [security setQuantity:[f numberFromString:quantity]];
   
    // save
    [self.managedObjectContext save:nil];
}


/*
- (IBAction)updateSymbolAmounts {
    for (int arrayIncrementor = 0; arrayIncrementor <= ([self.symbolArray count] -1 ); arrayIncrementor++) {
        NSError *error = nil;
        
        // NSManagedObject subclass
        Securities *security = nil;
        
        // set up to get the symbol you want to update
        NSFetchRequest * request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"Securities" inManagedObjectContext:self.managedObjectContext]];
        // set the predicate to search for the symbol from the symbolArray
        [request setPredicate:[NSPredicate predicateWithFormat:@"symbol=%@",[self.symbolArray objectAtIndex:arrayIncrementor]]];
        
        // ask for it
        security = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
        
        if (error) {
            //Handle any errors
            NSLog(@"we had an error right away");
        }
        
        if (!security) {
            //Nothing there to update
            NSLog(@"didn't find any security");
        }
        
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
    
}
*/

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
//    [self listSymbolsInScrollView];
    // reload the table to display the new symbol
    [self.symbolTableView reloadData];
}

// - button next to symbols that will remove from core data and re-draw table with a new fetch
-(void)removeSymbolFromCoreData:(UIButton *)symbolToBeRemoved {
    // get the text and quantity from the array's
    NSString *symbolTextToBeRemoved = [self.symbolArray objectAtIndex:symbolToBeRemoved.tag];
    NSString *symbolQuantityToBeRemoved = [self.quantityArray objectAtIndex:symbolToBeRemoved.tag];
    
    // set up the security fetch with predicate
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Securities" inManagedObjectContext:self.managedObjectContext]];
    NSError *error = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"symbol == %@ AND quantity = %@", symbolTextToBeRemoved, symbolQuantityToBeRemoved];
    [request setPredicate:predicate];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    Securities *securityToBeRemoved = [results firstObject];
    
    // remove from core data
    [self.managedObjectContext deleteObject:securityToBeRemoved];
    
    if (![self.managedObjectContext save:&error]){
        NSLog(@"Error ! %@", error);
    }
    // redraw view so it gets new values
//    [self listSymbolsInScrollView];
}

#pragma mark - views

// used to start off the action of listing out the symbols currently held in CD
-(void)viewWillAppear:(BOOL)animated{
   // [self listSymbolsInScrollView];
}


- (void)viewDidLoad {
    [super viewDidLoad];
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
    // fetch the data
    [self.fetchedResultsController performFetch:nil];
    
    // set up the two arrays for editing
    self.symbolArray = [[NSMutableArray alloc] init];
    self.quantityArray = [[NSMutableArray alloc] init];
    
    // Add nice button stuff
    self.addButton.layer.cornerRadius = 5;
    self.addButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.addButton.layer.borderWidth = 1;
    
    // set up table view
    self.symbolTableView.delegate = self;
    self.symbolTableView.dataSource = self;
    // MUST have since portrait/landscape changed with this 'auto resize'; the setting in IB is 44 and has to be different
    self.symbolTableView.rowHeight = 45;
    
    // listen for the keyboard
//    [self registerForKeyboardNotifications];
}

#pragma mark keyboard
// get rid of the keyboard with the "Done" button in upper right
- (IBAction)dismissKeyboard:(UIButton *)senderButton {
    [self.view endEditing:YES];
}

/*
// register the notification for the keyboard actions
- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (IBAction)dismissKeyboard:(UIButton *)senderButton {
    // [sender resignFirstResponder]; // doesn't work as well
    [self.view endEditing:YES];
    self.topNavigationItem.rightBarButtonItem = nil;
    // not needed now but, neat idea
    //float kbHeight = (float)senderButton.tag;
    
    CGRect aRect = self.view.frame;
    // animate text back to orgin
//    [UIView animateWithDuration:0.3f animations:^ {
//        self.view.frame = CGRectMake(0, 0, aRect.size.width, aRect.size.height);
//    }];
     [self.symbolTableView setContentOffset:CGPointZero animated:YES];
}

// called when the UIKeyboardDidShowNotification is sent
- (void)keyboardWasShown:(NSNotification*)aNotification {
    
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    // animate whole main UIVeiw area up
//    [UIView animateWithDuration:0.3f animations:^ {
//        self.view.frame = CGRectMake(0, -kbSize.height, aRect.size.width, aRect.size.height + kbSize.height);
//    }];
    
    
    self.topNavigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissKeyboard:)];
    // assign the height to the button tag for reading later
    self.topNavigationItem.rightBarButtonItem.tag = kbSize.height;
}

// called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    [self.symbolTableView setContentOffset:CGPointZero animated:YES];
}
*/

-(BOOL)prefersStatusBarHidden {
    return YES;
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
