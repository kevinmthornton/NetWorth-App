//
//  Securities.h
//  NetWorth
//
//  Created by kevin thornton on 5/8/14.
//  Copyright (c) 2014 kevin thornton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Securities : NSManagedObject

@property (nonatomic, retain) NSString * symbol;
@property (nonatomic, retain) NSNumber * quantity;

@end
