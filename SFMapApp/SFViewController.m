//
//  SFViewController.m
//  SFMapApp
//
//  Created by Spencer Fornaciari on 11/19/13.
//  Copyright (c) 2013 Spencer Fornaciari. All rights reserved.
//

#import "SFViewController.h"

#define GOOGLE_API_KEY @"AIzaSyANZFTDtVBzKXtSTT8eED7uzG5GfH2uleU"

@interface SFViewController ()

@end

@implementation SFViewController
{
    BOOL firstLaunch;
    CLAuthorizationStatus _authorizationStatus;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _authorizationStatus = [CLLocationManager authorizationStatus];
    self.mapSearch.delegate = self;
    
//    if (_authorizationStatus == kCLAuthorizationStatusNotDetermined || _authorizationStatus ==  kCLAuthorizationStatusRestricted)
//    {
//        UIAlertView *status =[[UIAlertView alloc] initWithTitle:@"Please allow location services"
//                                                    message:@"Please consider enabling them"
//                                                       delegate:self
//                                              cancelButtonTitle:@"Ok"
//                                              otherButtonTitles: nil];
//        
//        [status show];
//    }
//    
//    else if (_authorizationStatus == kCLAuthorizationStatusDenied)
//    {
//        UIAlertView *status =[[UIAlertView alloc] initWithTitle:@"You have disabled location services"
//                                                        message:@"You can't use the app unless you do :-("
//                                                       delegate:self
//                                              cancelButtonTitle:@"Ok"
//                                              otherButtonTitles: nil];
//        [status show];
//        
//    }
    
    if (_authorizationStatus == kCLAuthorizationStatusAuthorized)
    {
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager setDistanceFilter:kCLDistanceFilterNone];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    
    firstLaunch=TRUE;
    }
    
       //NSLog(@"%hhd", firstLaunch);
    
    
    
    
    
//    self.mapSearch.showsCancelButton = YES;
//
//    self.locationManager = [[CLLocationManager alloc] init];
//    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
//    self.locationManager.delegate = self;
//    
//    [self.locationManager startUpdatingLocation];
//    
//    self.location = [[CLLocation alloc] init];
//    
//    self.mapView.mapType = MKMapTypeStandard;
//    self.mapView.showsUserLocation = YES;
//    self.mapView.delegate = self;
//    
//    MKCoordinateRegion region;//= MKCoordinateRegionMakeWithDistance(self.location.coordinate, 0.5*1609.344, 0.5*1609.344);
//    region.center.latitude = self.mapView.userLocation.coordinate.latitude;
//    region.center.longitude = self.mapView.userLocation.coordinate.longitude;
//    
//    region.span = MKCoordinateSpanMake(0.00725, 0.00725);
//    
//    [self.mapView setRegion:region animated:YES];
    
    	// Do any additional setup after loading the view, typically from a nib.
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.location = locations.lastObject;
   // NSLog(@"%@", self.location);
}


-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [self.mapView setCenterCoordinate:userLocation.coordinate animated:YES];
}

-(void)mapView:(MKMapView *)mv didAddAnnotationViews:(NSArray *)views
{
    //Zoom back to the user location after adding a new set of annotations.
    //Get the center point of the visible map.
   CLLocationCoordinate2D centre = [mv centerCoordinate];
    NSLog(@"%f, %f", centre.latitude, centre.longitude);
    MKCoordinateRegion region;
    //If this is the first launch of the app, then set the center point of the map to the user's location.
    if (firstLaunch) {
        region = MKCoordinateRegionMakeWithDistance(self.locationManager.location.coordinate,1000,1000);
        NSLog(@"%f, %f", self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude);
        firstLaunch=NO;
    }else {
        //Set the center point to the visible region of the map and change the radius to match the search radius passed to the Google query string.
        region = MKCoordinateRegionMakeWithDistance(centre,self.currentDistance,self.currentDistance);
    }
    //Set the visible region of the map.
    [mv setRegion:region animated:YES];
}

-(void) queryGooglePlaces//: (NSString *) googleType
{
    // Build the url string to send to Google. NOTE: The GOOGLE_API_KEY is a constant that should contain your own API key that you obtain from Google. See this link for more info:
    // https://developers.google.com/maps/documentation/places/#Authentication
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?location=%f,%f&radius=%@&sensor=true&key=%@", self.pointCenter.latitude, self.pointCenter.longitude, [NSString stringWithFormat:@"%i", self.currentDistance], GOOGLE_API_KEY];
    
    //NSLog(@"%@", url);
    
    //Formulate the string as a URL object.
    NSURL *googleRequestURL=[NSURL URLWithString:url];
    
    // Retrieve the results of the URL.
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: googleRequestURL];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
    
}

-(void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
    //NSLog(@"%@", json);
    
    //The results from Google will be an array obtained from the NSDictionary object with the key "results".
    NSArray* places = [json objectForKey:@"results"];
    
    //Write out the data to the console.
    //NSLog(@"Google Data: %@", places);
    
    [self plotPositions:places];
}



-(void)plotPositions:(NSArray *)data
{
    
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[SFMapAnnotation class]]) {
            [self.mapView removeAnnotation:annotation];
        }
    }

    // 2 - Loop through the array of places returned from the Google API.
    for (int i=0; i < data.count; i++) {
        //Retrieve the NSDictionary object in each index of the array.
        NSDictionary* place = [data objectAtIndex:i];
        // 3 - There is a specific NSDictionary object that gives us the location info.
        NSDictionary *geo = [place objectForKey:@"geometry"];
        // Get the lat and long for the location.
        NSDictionary *loc = [geo objectForKey:@"location"];
        // 4 - Get your name and address info for adding to a pin.
        NSString *name=[place objectForKey:@"name"];
        //NSString *vicinity=[place objectForKey:@"vicinity"];
        // Create a special variable to hold this coordinate info.
        CLLocationCoordinate2D placeCoord;
        // Set the lat and long.
        placeCoord.latitude=[[loc objectForKey:@"lat"] doubleValue];
        placeCoord.longitude=[[loc objectForKey:@"lng"] doubleValue];
        
        // 5 - Create a new annotation.
        SFMapAnnotation *placeObject = [[SFMapAnnotation alloc] initWithCoordinate:placeCoord title:name];
        
        [self.mapView addAnnotation:placeObject];
    }
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    // Define your reuse identifier.
    static NSString *identifier = @"SFMapAnnotation";
    
    if ([annotation isKindOfClass:[SFMapAnnotation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        } else {
            annotationView.annotation = annotation;
        }
        annotationView.pinColor = MKPinAnnotationColorGreen;
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        return annotationView;
    }
    return nil;
}

//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
//    //7
//    if([annotation isKindOfClass:[MKUserLocation class]])
//        return nil;
//    
//    //8
//    static NSString *identifier = @"myAnnotation";
//    MKPinAnnotationView * annotationView = (MKPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
//    if (!annotationView)
//    {
//        //9
//        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
//        annotationView.pinColor = MKPinAnnotationColorPurple;
//        annotationView.animatesDrop = YES;
//        annotationView.canShowCallout = YES;
//    }else {
//        annotationView.annotation = annotation;
//    }
//    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//    return annotationView;
//}

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    //Get the east and west points on the map so you can calculate the distance (zoom level) of the current map view.
    MKMapRect mRect = self.mapView.visibleMapRect;
    MKMapPoint eastMapPoint = MKMapPointMake(MKMapRectGetMinX(mRect), MKMapRectGetMidY(mRect));
    MKMapPoint westMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), MKMapRectGetMidY(mRect));
    
    //Set your current distance instance variable.
    self.currentDistance = MKMetersBetweenMapPoints(eastMapPoint, westMapPoint);
    
    //Set your current center point on the map instance variable.
    self.pointCenter = self.mapView.centerCoordinate;
}


- (IBAction)updateCurrentLocation:(id)sender
{
    NSLog(@"%u", _authorizationStatus);
    
    if (_authorizationStatus == kCLAuthorizationStatusDenied)
    {
        UIAlertView *status =[[UIAlertView alloc] initWithTitle:@"You have disabled location services"
                                                        message:@"You can't use the app unless you do :-("
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles: nil];
        [status show];
        
    } else {
        [self queryGooglePlaces];
    }
    

    //    [self mapView];
}

//-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//{
//    
//    
//    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
//    
//    [geocoder geocodeAddressString:searchText
//                 completionHandler:^(NSArray* placemarks, NSError* error){
//                     for (CLPlacemark* aPlacemark in placemarks)
//                     {
//                         NSLog(@"%@", aPlacemark.location);
//                         
//                         // Process the placemark.
//                     }
//                 }];
//
//}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:searchBar.text
                 completionHandler:^(NSArray* placemarks, NSError* error){
                     for (CLPlacemark *aPlacemark in placemarks)
                     {
                         NSLog(@"%@", aPlacemark.location);
                         
                         // Process the placemark.
                     }
                     CLPlacemark *placemark = [placemarks objectAtIndex:0];
                     CLLocation *location = placemark.location;
                     CLLocationCoordinate2D coordinate = location.coordinate;
                     [searchBar resignFirstResponder];
                      [self.mapView setCenterCoordinate:coordinate animated:YES];
                 }];
   

}


- (IBAction)searchBar:(id)sender {
}
@end
