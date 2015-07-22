//
//  Location.m
//  TourMyTown
//
//  Created by Michael Katz on 8/15/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import "Location.h"

#define safeSet(d,k,v) if (v) d[k] = v;

@interface Location ()
@property (nonatomic, retain) id location;

@end

@implementation Location


- (instancetype) init
{
    self = [super init];
    if (self) {
        _categories = [NSMutableArray array];
    }
    return self;
}

#pragma mark - MKAnnotation

- (NSString *)title
{
    return self.name;
}

- (NSString *)subtitle
{
    return (self.details != nil && self.details.length > 0) ? self.details : self.placeName;
}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationDegrees lat = [self.location[@"coordinates"][1] doubleValue];
    CLLocationDegrees lon = [self.location[@"coordinates"][0] doubleValue];
    CLLocationCoordinate2D c = CLLocationCoordinate2DMake(lat, lon);
    return c;
}
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    [self setLatitude:newCoordinate.latitude longitude:newCoordinate.longitude];
}

#pragma mark - GeoJSON

- (void) setLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;
{
    //make a geoJSON object e.g. { "type": "Point", "coordinates": [100.0, 0.0] }
    _location = @{@"type":@"Point", @"coordinates" : @[@(longitude), @(latitude)] };
}

- (void) setGeoJSON:(id)geoPoint
{
    _location = geoPoint;
}

#pragma mark - serialization

- (instancetype) initWithDictionary:(NSDictionary*)dictionary
{
    self = [super init];
    if (self) {
        _name = dictionary[@"name"];
        _location = dictionary[@"location"];
        _placeName = dictionary[@"placename"];
        _imageId = dictionary[@"imageId"];
        _details = dictionary[@"details"];
        _categories = [NSMutableArray arrayWithArray:dictionary[@"categories"]];
        __id = dictionary[@"_id"];
    }
    return self;
}

- (NSDictionary*) toDictionary
{
    NSMutableDictionary* jsonable = [NSMutableDictionary dictionary];
    safeSet(jsonable, @"name", self.name);
    safeSet(jsonable, @"placename", self.placeName);
    safeSet(jsonable, @"location", self.location);
    safeSet(jsonable, @"details", self.details);
    safeSet(jsonable, @"imageId", self.imageId);
    safeSet(jsonable, @"categories", self.categories);
    safeSet(jsonable, @"_id", self._id);
    return jsonable;
}
@end
