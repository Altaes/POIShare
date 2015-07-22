//
//  Categories.h
//  TourMyTown
//
//  Created by Michael Katz on 10/10/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import <Foundation/Foundation.h>

/** The Categories represents the list of available tag categories. Locations can have multiple. */
@interface Categories : NSObject

+ (NSArray*) allCategories;
+ (NSArray*) activeCategories;

+ (NSArray*) filteredCategories;
+ (void) setFilteredCategories:(NSArray*)categories;


+ (BOOL) filterOnFor:(NSString*)category;
+ (void) setFilter:(NSString*)category on:(BOOL)on;

+ (NSString*) query;

@end
