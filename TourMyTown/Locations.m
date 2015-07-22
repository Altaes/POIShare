//
//  Locations.m
//  TourMyTown
//
//  Created by Michael Katz on 8/15/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import "Locations.h"
#import "Location.h"

static NSString* const kBaseURL = @"http://localhost:3000/";
static NSString* const kLocations = @"locations";
static NSString* const kFiles = @"files";


@interface Locations ()
@property (nonatomic, strong) NSMutableArray* objects;
@end

@implementation Locations

- (id)init
{
    self = [super init];
    if (self) {
        _objects = [NSMutableArray array];
    }
    return self;
}

- (NSArray*) filteredLocations
{
    return [self objects];
}

- (void) addLocation:(Location*)location
{
    [self.objects addObject:location];
}

- (void)loadImage:(Location*)location
{
    //http://localhost:3000/files/[imageID.png]
    NSURL *url = [NSURL URLWithString:[[kBaseURL stringByAppendingString:kFiles] stringByAppendingPathComponent:location.imageId]];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    //Download task sent, downloads the file to a temp. location, and returns an url to that location (fileLocation)
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url completionHandler:^(NSURL *fileLocation, NSURLResponse *response, NSError *error) {
        if (!error) {
            //Temp location is only available during this completion block, so we must store in memory or move it elsewhere
            //Get the data from the fileLocation
            NSData *imageData = [NSData dataWithContentsOfURL:fileLocation];
            
            //Convert that data to an UIImage
            UIImage *image = [UIImage imageWithData:imageData];
            
            //If data is not an image, or image did not convert
            if (!image) {
                NSLog(@"unable to build image");
            }
            
            //Set the location image to this UIImage loaded
            location.image = image;
            
            
            if (self.delegate) {
                [self.delegate modelUpdated];
            }
        }
    }];
    [task resume];
}

- (void)parseAndAddLocations:(NSArray*)locations toArray:(NSMutableArray*)destinationArray
{
    //The response from the server is an array of NSDictionary
    //Loops through that array and initialize Location object with that dictionary
    for (NSDictionary *item in locations) {
        Location *location = [[Location alloc] initWithDictionary:item];
        
        //Add the new Location to the existing array of Location (self.objects)
        [destinationArray addObject:location];
        
        //Checks for imageId, if there is one, then load the image.
        if (location.imageId) {
            [self loadImage:location];
        }
    }
    
    //Tell the UI that the model has been changed, so we need an update
    if (self.delegate) {
        [self.delegate modelUpdated];
    }
}

- (void)import
{
    //Essentially it's http://localhost:3000/locations
    NSURL *url = [NSURL URLWithString:[kBaseURL stringByAppendingPathComponent:kLocations]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    //Creates a dataTask to transfer data from the webservice to the app
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        //The completion handler is for any errors
        if (error == nil) {
            
            //Deserializes the data using NSJSONSerialization, and the outpput is an array
            NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            
            //Append the current self.objects array with the newly deserialized data from responseArray
            [self parseAndAddLocations:responseArray toArray:self.objects];
        }
    }];
    
    //Data Tasks are created in the paused state, and before the method block ends, we must call [dataTask resume]
    [dataTask resume];
 
}

- (void) runQuery:(NSString *)queryString
{
    NSString *urlStr = [[kBaseURL stringByAppendingPathComponent:kLocations] stringByAppendingString:queryString];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            [self.objects removeAllObjects];
            NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            NSLog(@"received %lu items", (unsigned long)responseArray.count);
            [self parseAndAddLocations:responseArray toArray:self.objects];
        }
    }];
    [dataTask resume];
}

- (void) queryRegion:(MKCoordinateRegion)region
{
    CLLocationDegrees x0 = region.center.longitude - region.span.longitudeDelta;
    CLLocationDegrees x1 = region.center.longitude + region.span.longitudeDelta;
    CLLocationDegrees y0 = region.center.latitude - region.span.latitudeDelta;
    CLLocationDegrees y1 = region.center.latitude + region.span.latitudeDelta;
    
    NSString *boxQuery = [NSString stringWithFormat:@"{\"$geoWithin\":{\"$box\":[[%f,%f],[%f,%f]]}}", x0, y0, x1, y1];
    NSString *locationInBox = [NSString stringWithFormat:@"{\"location\":%@}", boxQuery];
    NSString *escBox = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)locationInBox, NULL, (CFStringRef)@"!*();':@&=+$,/?%#[]{}", kCFStringEncodingUTF8));
    
    NSString *query = [NSString stringWithFormat:@"?query=%@", escBox];
    [self runQuery:query];
}


- (void) persist:(Location*)location
{
    //Safe input check
    if (!location || location.name == nil || location.name.length == 0) {
        return;
    }
    
    //If there's an image, but no image id, then the image hasn't been saved yet
    if (location.image != nil && location.imageId == nil) {
        
        //Call to save the image and thus the image id as well
        [self saveNewLocationImageFirst:location];
        return;
    }
    
    //Default string is http://localhost:3000/locations
    NSString *locations = [kBaseURL stringByAppendingPathComponent:kLocations];
    
    //Stores the T/F value of the Location to be updated/added; T for it exists, F otherwise
    BOOL isExistingLocation = location._id != nil;
    
    //If the Location ID already exists, then we will append the locations NSString with the ID of the location
    //Otherwise we'll just use the already defined NSString locations
    NSURL *url = isExistingLocation ? [NSURL URLWithString:[locations stringByAppendingPathComponent:location._id]] :
    [NSURL URLWithString:locations];
    
    //Creates a standard NSURL request with the url created above
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //Determines if it is a PUT or POST depending on if the location ID already exists or not
    request.HTTPMethod = isExistingLocation ? @"PUT" : @"POST";
    
    //Creates a data object that is usable by HTTP Body, by serializing the location object (first turning it into a dictionary
    NSData *data = [NSJSONSerialization dataWithJSONObject:[location toDictionary] options:0 error:NULL];
    
    request.HTTPBody = data;
    
    //Declares for the body-parser that the data is of Content-Type: application/json
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //Standard configuration for NSURL Session
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    //Creates a dataTask for transferring the request, with a completion handler
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            
            //Creates the responseArray of the dictionaries returned by the server
            NSArray *responseArray = @[[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]];
            
            //Adds the responseArray to the local collection of objects (self.objects)
            [self parseAndAddLocations:responseArray toArray:self.objects];
        }
    }];
    
    //Remember that the dataTask must resume to start, as it is initially paused
    [dataTask resume];
 
}

- (void) saveNewLocationImageFirst:(Location *)location
{
    //Url of http://localhost:3000/files
    NSURL *url = [NSURL URLWithString:[kBaseURL stringByAppendingString:kFiles]];
    
    //Create a standard POST request with the URL; triggers handleUploadRequest of fileDriver
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    //The request will be a type of image/png, ensures proper saving, Content-Type header important for determining .ext
    [request addValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
    
    //Standard session configuration and initialization
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    //Turns a standard UIImage to a PNG data type
    NSData *bytes = UIImagePNGRepresentation(location.image);
    
    //Sends the data in the request itself, with a completion handler to get back the new id
    //Upload tasks can automatically set Content-Type header based on the data length
    //Upload tasks can also report progress and can run in the background
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:bytes completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        //If the completion (response) sent back to the server was error free and a success (201), store new obj id
        if (error == nil && [(NSHTTPURLResponse *)response statusCode] < 300) {
            
            //Turn the data received back into a JSON data type in a NSDictionary
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            
            //Saves the id of the image sent, into the location object
            location.imageId = responseDict[@"_id"];
            
            //Then saves the main location entity to the server; but only after saving the image and retreiving the id
            [self persist:location];
        }
    }];
    [task resume];
}

@end
