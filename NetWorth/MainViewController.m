//  MainViewController.m - NetWorth
//
//  Created by kevin thornton on 5/7/14. - Copyright (c) 2014 kevin thornton. All rights reserved.

#import "MainViewController.h"
#import "Securities.h"

// for shadowing and borders
#import <QuartzCore/QuartzCore.h>
// for attributedText
#import <CoreText/CoreText.h>

// not used at the moment but, could be in the future if we need more specific data
// in order for the yahooapis.com string to work you have to use an unescaped(no \/ or \?) string and piece it together with NSMutableString
// you have to put in query string transformations
#define YAHOO_START_STRING @"http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20csv%20where%20url='http://download.finance.yahoo.com/d/quotes.csv%3Fs="
#define YAHOO_END_STRING @"%26f=sl1d1t1c1ohgv%26e=.csv'%20and%20columns='symbol%2Cprice%2Cdate%2Ctime%2Cchange%2Ccol1%2Chigh%2Clow%2Ccol2'&format=json&diagnostics=true&callback="

@interface MainViewController ()
@end

@implementation MainViewController
@synthesize netWorthAmountLabel = _netWorthAmountLabel;
@synthesize totalNetWorthString = _totalNetWorthString;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize totalNetWorth = _totalNetWorth;

@synthesize noSymbolTextField = _noSymbolTextField;
@synthesize labelHolderView = _labelHolderView;

// 1
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:steelBlueColor];
    
    // set up the top label -- !!!!!! use NSAutoLayout eventually !!!!
    // create a label with which to attach the shadow
    UILabel *shadowLabel = [[UILabel alloc] init];
    [shadowLabel setFrame:CGRectMake(8,20,290,30)];
    [shadowLabel setBackgroundColor:steelBlueColor];
    [shadowLabel.layer setCornerRadius:0];
    [shadowLabel.layer setMasksToBounds:YES];
    // create the shadow for the shadowLabel
    CALayer *shadowLayer = [CALayer new];
    shadowLayer.frame = CGRectMake(8,20,290,30);
    shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    shadowLayer.shadowOpacity = 0.4;
    shadowLayer.shadowOffset = CGSizeMake(-2,2);
    shadowLayer.shadowRadius = 1;
    // add the shadowLayer and shadowLabel together
    [shadowLayer addSublayer:shadowLabel.layer];
    [self.view.layer addSublayer:shadowLayer];      
    
    // create the label that sits on top of the shadow
    UILabel *netWorthTextLabel = [[UILabel alloc] init];
    netWorthTextLabel.text = @" Net Worth";
    netWorthTextLabel.textColor = [UIColor whiteColor];
    netWorthTextLabel.frame = CGRectMake(16,40,290,30);
    [netWorthTextLabel setBackgroundColor:steelBlueColor]; // defined in NetWorth-Prefix.pch
    [self.view addSubview:netWorthTextLabel];
    
    // create the label that will hold the total value of all symbols added together
    self.netWorthAmountLabel = [[UILabel alloc] init];
    self.netWorthAmountLabel.textColor = [UIColor whiteColor];
    self.netWorthAmountLabel.frame = CGRectMake(216,40,290,30);
    [self.netWorthAmountLabel setBackgroundColor:steelBlueColor]; // defined in NetWorth-Prefix.pch
    [self.view addSubview:self.netWorthAmountLabel];
    
    // set up noSymbolTextField
    self.noSymbolTextField = [[UITextView alloc] init];
    // clear out the noSymbolTextField
    self.noSymbolTextField.text = @"";
}

// 2
// since we have the 'i' in the bottom, our view already loaded so we should start from here
-(void)viewWillAppear:(BOOL)animated {
    // clear out the self.totalNetWorth value so it doesn't keep accumulating
    self.totalNetWorth = 0;
    // clear out all the current labels so we can re-write them with new data
    for (UILabel *theLabel in self.labelHolderView.subviews) {
        [theLabel removeFromSuperview];
    }
    
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
    // make sure to get results
    [self.fetchedResultsController performFetch:nil];
    
    // check CD for values; this VC needs access to Core Data
    [self startUpCoreDataSymbols];
} // end viewWillAppear

// 3
-(void)startUpCoreDataSymbols {
    // check to see if we have data; no data, display "no symbols. add some with i below"
    if (![[self.fetchedResultsController fetchedObjects] count] > 0 ) {
        // send message saying to use the i button in the bottom right to add symbols
        self.noSymbolTextField.text = @"Please use the i button in the \nlower right to enter symbols";
        self.noSymbolTextField.textColor = [UIColor whiteColor];
        self.noSymbolTextField.frame = CGRectMake(16,80,290,130); // x, y, width, height
        [self.noSymbolTextField setBackgroundColor:steelBlueColor];
        [self.labelHolderView addSubview:self.noSymbolTextField];
    } else {
        // start the label Y axis here and increment as we go through the securities
        // set to block var to be manipulated
        __block float createStartY = 10;
        [[self.fetchedResultsController fetchedObjects] enumerateObjectsUsingBlock:^(Securities *security, NSUInteger index, BOOL *stop) {
            [self createLabel:security startY:createStartY];
            createStartY +=40;
        }];
        
        // this for...in didn't work as reliably as the enumerateObjectsUsingBlock
        // send the Securities object to createLabel: coming out of the Core Data method
//      float createStartY = 10;
//        for(Securities *security in [self.fetchedResultsController fetchedObjects]) {
//            [self createLabel:security startY:createStartY];
//            createStartY +=40;
//        }
        // call displayNetWorth to get the final number of all the price * amount's added up
        // [self displayNetWorth];
    }
} // end start up CD symbols

// 4
// write out the label for each security to the main view
-(void)createLabel:(Securities *)security  startY:(int)startY {
    // do you want to show last price and change?
    // attributedText -- http://stackoverflow.com/questions/11031623/how-can-i-use-attributedtext-in-uilabel
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // send out symbol to get price
        NSArray *priceChangeArray = [self getSecurityInfo:security.symbol quantity:security.quantity];
        // update the UI on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self writeLabelToView:priceChangeArray startY:startY];
        });
    });
}

// 5 go out to yahoo and get the json data for the passed symbol
-(NSArray *)getSecurityInfo:(NSString *)symbol quantity:(NSNumber *)quantity {
    NSString *symbolString = [NSString stringWithFormat:@"http://download.finance.yahoo.com/d/quotes.csv?s=%@&f=sl1d1t1c1ohgv&e=.csv",symbol];
    NSURL *dataURL = [NSURL URLWithString:symbolString];
    
    // get text data from yahoo; comes back in comma seperated format
    // symbol, price, date, time, change, open, low, high, something
    NSError *error = nil;
    NSString *symbolTextFromYahoo = [NSString stringWithContentsOfURL:dataURL encoding:NSASCIIStringEncoding error:&error];
    // NSLog(@"%@", symbolTextFromYahoo);
    NSArray *symbolArray = [symbolTextFromYahoo componentsSeparatedByString:@","];
    NSNumber *price = [symbolArray objectAtIndex:1];
    NSString *stringChange = [symbolArray objectAtIndex:4];
    NSNumber *changeNumber = [NSNumber numberWithFloat:[stringChange floatValue]];
    
    // calculate values
    float changeFloat = ([changeNumber floatValue] / [price floatValue]) * 100;
    float value = [quantity floatValue] * [price floatValue];
    
    // add up the values for a total net worth to display at top; self.totalNetWorth is a float
    self.totalNetWorth += value;
    
    // make this string into a currency format
    NSNumberFormatter * formatter;
    formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
    [formatter setCurrencySymbol: @"$"];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    NSNumber *valueNumber = [NSNumber numberWithFloat:value];
    NSString *valueString = [formatter stringFromNumber:valueNumber];
    
    // was the change up or down? --> a - will be in place already if down so, we just need to format the +
    NSString *prefix = [NSString stringWithFormat:@"+"];
    NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"+"];
    NSRange range = [stringChange rangeOfCharacterFromSet:cset];
    if (range.location == NSNotFound) {
        // it's a negative number and will already have a - sign in front so, we don't need to do anything
        prefix = [NSString stringWithFormat:@""];
    }
    
    NSString *change = [NSString stringWithFormat:@"%@%f",prefix,changeFloat];
    
    /*
     We COULD do it this way and get back json data but, I only need the price and change so, this is overkill for now
    // in order for the yahooapis.com string to work you have to use an unescaped string and piece it together with NSMutableString
    NSMutableString *mutableSymbolString = [[NSMutableString alloc] init];
    [mutableSymbolString appendString:YAHOO_START_STRING];
    [mutableSymbolString appendString:symbol];
    [mutableSymbolString appendString:YAHOO_END_STRING];
    NSString *symbolString = [mutableSymbolString copy];
    NSURL *dataURL = [NSURL URLWithString:symbolString];
    NSData *data=[NSData dataWithContentsOfURL:dataURL];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error]; // user &error from above
    NSLog(@"symbol: %@ \n %@", symbol, jsonDict);
    */

    NSArray *returnedArray = [[NSArray alloc] initWithObjects:symbol, valueString, change, nil];
    return returnedArray;
}

// send in the symbolArray which holds symbol and price and Y position
-(void)writeLabelToView:(NSArray *)symbolArray startY:(int)startY {

    UILabel *securityLabel = [[UILabel alloc] init];
    securityLabel.text = [symbolArray objectAtIndex:0];
    securityLabel.textColor = [UIColor whiteColor];
    securityLabel.frame = CGRectMake(6,startY,90,30);
    [self.labelHolderView addSubview:securityLabel];
    
    UILabel *changeLabel = [[UILabel alloc] init];
    changeLabel.text = [symbolArray objectAtIndex:2];
    changeLabel.textColor = [UIColor whiteColor];
    changeLabel.frame = CGRectMake(46,startY,90,30);
    [self.labelHolderView addSubview:changeLabel];
    
    // NSString *priceText = [[symbolArray objectAtIndex:1] stringValue];
    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.text = [symbolArray objectAtIndex:1];
    priceLabel.textColor = [UIColor whiteColor];
    priceLabel.frame = CGRectMake(206,startY,90,30);
    [self.labelHolderView addSubview:priceLabel];
    
    // make this string into a currency format
    NSNumberFormatter * formatter;
    NSNumber          * totalNetWorthCurrency;
    formatter = [[NSNumberFormatter alloc] init];
    totalNetWorthCurrency   = [NSNumber numberWithFloat: self.totalNetWorth];
    [formatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
    [formatter setCurrencySymbol: @"$"];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    
    // !!! this is not calculating all the way consistantly !!!
    // keep updating the netWorthAmountLabel label as we go
    [self.netWorthAmountLabel setText:[formatter stringFromNumber:totalNetWorthCurrency]]; // self.totalNetWorthString];

} // end writeLabelToView



-(void)displayNetWorth {
    // make this string into a currency format
    NSNumberFormatter * formatter;
    NSNumber          * totalNetWorthCurrency;
    formatter = [[NSNumberFormatter alloc] init];
    totalNetWorthCurrency   = [NSNumber numberWithFloat: self.totalNetWorth];
    [formatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
    [formatter setCurrencySymbol: @"$"];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    
    [self.netWorthAmountLabel setText:[formatter stringFromNumber:totalNetWorthCurrency]]; // self.totalNetWorthString];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Flipside View

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // this is in the Attributes Inspector of the Seque between main and flipside
    if ([[segue identifier] isEqualToString:@"showFlip"]) {
        // why does this work from here and not viewDidLoad???
        [[segue destinationViewController] setManagedObjectContext:self.managedObjectContext];
        // set the delegate to MainViewController so we can execute done:
        [[segue destinationViewController] setDelegate:self];
    }
}

// this is called from FlipsideViewController > done:
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
