//
//  Locations.h
//  TourMyTown¡
//
//  Created by Michael Katz on 8/15/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class Location;

@protocol LocationModelDelegate <NSObject>

- (void) modelUpdated;

@end

@interface Locations : NSObject

@property (nonatomic, weak) id<LocationModelDelegate> delegate;

- (NSArray*) filteredLocations;
- (void) addLocation:(Location*)location;

- (void) import;
- (void) persist:(Location*)location;

- (void) runQuery:(NSString*)queryString;
- (void) queryRegion:(MKCoordinateRegion)region;
@end
