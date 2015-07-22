//
//  ViewController.m
//  TourMyTown
//
//  Created by Michael Katz on 8/3/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import "MapViewController.h"

#import "MBProgressHUD.h"

#import "Locations.h"
#import "Location.h"
#import "Categories.h"

#import "AppDelegate.h"
#import "TagDetailControllerViewController.h"
#import "FilterListViewController.h"

#define kDetailSegue @"tagdetail"

@interface MapViewController () <UIAlertViewDelegate, LocationModelDelegate, CategoryDelegate>
@property (nonatomic) BOOL waitingForLocation;
@property (nonatomic, retain) Location* recentLocation;
@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UILongPressGestureRecognizer* longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.mapView addGestureRecognizer:longTap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kDetailSegue]) {
        TagDetailControllerViewController* detailController = segue.destinationViewController;
        detailController.location = self.recentLocation;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshAnnotations];
    [self locations].delegate = self;
    [self refreshAnnotations];
}

- (void) refreshAnnotations
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapView removeAnnotations:self.mapView.annotations];
        for (id<MKAnnotation> a in self.locations.filteredLocations) {
            [self.mapView addAnnotation:a];
        }
        [self.view setNeedsLayout];
    });
}

#pragma mark - Model
- (void)modelUpdated
{
    [self refreshAnnotations];
}

- (Locations*) locations
{
    return [AppDelegate appDelegate].locations;
}

- (void) setupAnnotationWithGeocoder:(Location*)tag location:(CLLocation*)location
{
    //Try to get the Local name for the user's location.
    [[[CLGeocoder alloc] init] reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        NSString* message = nil;
        if (!error) {
            NSLog(@"%@",placemarks);
            MKPlacemark* mark = placemarks[0];
            tag.placeName = mark.name;
            [tag setLatitude:mark.location.coordinate.latitude longitude:mark.location.coordinate.longitude];
            message = mark.name;
        } else {
            //if the name can't be located, still create a tag with the less-ressed data.
            CLLocationCoordinate2D coordinate = location.coordinate;
            [tag setLatitude:coordinate.latitude longitude:coordinate.longitude];
            message = [NSString stringWithFormat:@"%4.2f,%4.2f", coordinate.latitude, coordinate.longitude];
        }
        tag.configuredBySystem = YES;

        tag.name = message;
        [self.locations addLocation:tag];
        [self.mapView addAnnotation:tag];
        self.recentLocation = tag;
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
        [self performSegueWithIdentifier:kDetailSegue sender:self];
    }];
}

- (void) addLocationAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    CLLocation* location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    Location* newTag = [[Location alloc] init];
    [self setupAnnotationWithGeocoder:newTag location:location];
}

- (IBAction)addLocation:(id)sender {
    
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setDetailsLabelText:@"Locating..."];
    [hud setDimBackground:YES];

    CLLocationCoordinate2D centerCoord = self.mapView.centerCoordinate;
    [self addLocationAtCoordinate:centerCoord];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        Location* t = [self.locations.filteredLocations lastObject];
        NSString* title = [alertView textFieldAtIndex:0].text;
        if (!title) title = t.placeName;
        t.name = title;
        [self.locations persist:t];
    }
}


#pragma mark - Map View

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (_waitingForLocation == YES) {
        _waitingForLocation = NO;
        [self addLocation:nil];
        MKCoordinateRegion reg = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 1500, 1500);
        [mapView setRegion:reg animated:YES];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[Location class]]) {
        MKPinAnnotationView* pin = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
        if (!pin) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
            pin.canShowCallout = YES;
            UIButton* callout = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            pin.rightCalloutAccessoryView = callout;
            UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., 36., 36.)];
            pin.leftCalloutAccessoryView = imageView;
            pin.draggable = YES;
        }
        pin.annotation = annotation;
        [(UIImageView*)pin.leftCalloutAccessoryView setImage:[(Location*)annotation image]];
        return pin;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSLog(@"hit %@", view.annotation);
    self.recentLocation = (Location*) view.annotation;
    [self performSegueWithIdentifier:kDetailSegue sender:self];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    Location* annotation = (Location*) annotationView.annotation;
    if (newState == MKAnnotationViewDragStateEnding && annotation.configuredBySystem) {
        CLLocationCoordinate2D co = [(Location*) annotationView.annotation coordinate];
        CLLocation* cllocation = [[CLLocation alloc] initWithLatitude:co.latitude longitude:co.longitude];
        [self setupAnnotationWithGeocoder:annotation location:cllocation];
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
    if (_waitingForLocation == YES) {
        _waitingForLocation = NO;
    }
    
    NSLog(@"failed to get user location error: %@", error);
    if ([error code] == kCLErrorDenied && [[error domain] isEqualToString:kCLErrorDomain]) {
        //user disabled location
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
                                                        message:@"Enable Location preferences in settings to tag new hot spots and find nearby ones."
                                                       delegate:self
                                              cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Could not locate you" message:@"Try again in a few minutes" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil] show];
    }
    
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAfterMapRegion) object:nil];
    [self performSelector:@selector(updateAfterMapRegion) withObject:nil afterDelay:2];
}


#pragma mark - Actions

- (void) updateAfterMapRegion
{
    MKCoordinateRegion region = self.mapView.region;
    [self.locations queryRegion:region];
}

- (IBAction)updateFilter:(id)sender {
    FilterListViewController* flvc = [[FilterListViewController alloc] initWithSelectedCategories:[Categories filteredCategories] deleagte:self];
    [self.navigationController pushViewController:flvc animated:YES];
}

- (void)selectedCategories:(NSArray *)array
{
    [Categories setFilteredCategories:array];
    [self.locations runQuery:[Categories query]];
}

- (void) tapped:(UILongPressGestureRecognizer*)longPress
{
    if (longPress.state == UIGestureRecognizerStateRecognized) {
        CGPoint tapLocation = [longPress locationInView:self.mapView];
        CLLocationCoordinate2D mapLocation = [self.mapView convertPoint:tapLocation toCoordinateFromView:self.mapView];
        [self addLocationAtCoordinate:mapLocation];
    }
}
@end
