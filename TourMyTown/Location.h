//
//  Location.h
//  TourMyTown
//
//  Created by Michael Katz on 8/15/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Location : NSObject <MKAnnotation>
@property (nonatomic, copy) NSString* _id;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* placeName;
@property (nonatomic, copy) NSString* details;
@property (nonatomic, retain, readonly) NSMutableArray* categories;

/** This property starts out YES until modified manually or loaded from the network. This way dragging the pin will update the coordinates and geocoded info */
@property (nonatomic) BOOL configuredBySystem;

@property (nonatomic, strong) UIImage* image;
@property (nonatomic, copy) NSString* imageId;

#pragma mark - JSON-ification

- (instancetype) initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) toDictionary;

#pragma mark - Location

- (void) setLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;
- (void) setGeoJSON:(id)geoPoint;
- (void) setCoordinate:(CLLocationCoordinate2D)newCoordinate;
@end
