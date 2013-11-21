//
//  SFViewController.m
//  SFMapApp
//
//  Created by Spencer Fornaciari on 11/19/13.
//  Copyright (c) 2013 Spencer Fornaciari. All rights reserved.
//

#import "SFViewController.h"

#define GOOGLE_WEB_ADDRESS @"https://maps.googleapis.com/maps/api/place/search/json?location="
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
    
    //Declare Toolbar Items
    MKUserTrackingBarButtonItem *userTrackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    
    UIBarButtonItem *pointsOfInterestButton = [[UIBarButtonItem alloc] initWithTitle:@"Points of Interest"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(addPointsOfInterest:)];

    
    UIBarButtonItem *updateLocationButton = [[UIBarButtonItem alloc] initWithTitle:@"Update User"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(updateCurrentLocation:)];
    
    [self.toolbar setItems:[NSArray arrayWithObjects:userTrackingButton, pointsOfInterestButton, updateLocationButton, nil]];

    //Check Authorization Status
    [self locationManager:self.locationManager didChangeAuthorizationStatus:[CLLocationManager authorizationStatus]];

    _authorizationStatus = [CLLocationManager authorizationStatus];
    
    //Set search bar delegate
    self.mapSearch.delegate = self;
    
    //Add Gesture Recognizer to add annotations
    [self addGestureRecogniser];
    
    if (_authorizationStatus == kCLAuthorizationStatusNotDetermined || _authorizationStatus ==  kCLAuthorizationStatusRestricted)
    {
        UIAlertView *status =[[UIAlertView alloc] initWithTitle:@"Location services not confirmed"
                                                    message:@"Please consider enabling them"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles: nil];
        
        [status show];
    }
    
    else if (_authorizationStatus == kCLAuthorizationStatusDenied)
    {
        [self checkLocationStatus];
        
    }
    
    //(_authorizationStatus == kCLAuthorizationStatusAuthorized)
    else
    {
        self.mapView.delegate = self;
        self.mapView.mapType = MKMapTypeStandard;
        self.mapView.showsUserLocation = YES;
    
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager setDistanceFilter:kCLDistanceFilterNone];
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    
        firstLaunch = TRUE;
    }
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
}


-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [self.mapView setCenterCoordinate:userLocation.coordinate animated:YES];
}

-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
   //Get the center point of the visible map.
   CLLocationCoordinate2D center = [mapView centerCoordinate];
   MKCoordinateRegion region;
    
    //If this is the first launch of the app, then set the center point of the map to the user's location.
    if (firstLaunch) {
        region = MKCoordinateRegionMakeWithDistance(self.locationManager.location.coordinate,1000,1000);
        
        firstLaunch = FALSE;
    }
    
    else
    {
        //Set the center point to the visible region of the map and change the radius to match the search radius passed to the Google query string.
        region = MKCoordinateRegionMakeWithDistance(center, self.currentDistance, self.currentDistance);
    }
    
    //Set the visible region of the map.
    [mapView setRegion:region animated:YES];
}

#pragma mark - Google Query Functions

//Query Google Places for Map Annotations
-(void) queryGooglePlaces
{
    //Create URL for Google Places
    NSString *googlePlacesFormula = [NSString stringWithFormat:@"%@%f,%f&radius=%@&sensor=true&key=%@", GOOGLE_WEB_ADDRESS, self.pointCenter.latitude, self.pointCenter.longitude, [NSString stringWithFormat:@"%i", self.currentDistance], GOOGLE_API_KEY];
    
    //Formulate the string as a URL object.
    NSURL *googleQuery = [NSURL URLWithString:googlePlacesFormula];
    
    // Retrieve the results of the URL.
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:googleQuery];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
    
}

//Parse JSON Data from Google Places
-(void)fetchedData:(NSData *)responseData {
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
    //Array of places from Google Places API
    NSArray* places = [json objectForKey:@"results"];
    
    [self plotPositions:places];
}

-(void)plotPositions:(NSArray *)data
{
    //Clear annotations except user location
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[SFMapAnnotation class]]) {
            [self.mapView removeAnnotation:annotation];
        }
    }

    //Parse the Google Places API
    for (int i=0; i < data.count; i++) {
        
        NSDictionary* place = [data objectAtIndex:i];
     
        //Grab the title of the Place
        NSString *name=[place objectForKey:@"name"];

        //Add the coordinate of the Place
        CLLocationCoordinate2D placeCoord;
        placeCoord.latitude=[[place valueForKeyPath:@"geometry.location.lat"] doubleValue];
        placeCoord.longitude=[[place valueForKeyPath:@"geometry.location.lng"] doubleValue];
        
        SFMapAnnotation *placeObject = [[SFMapAnnotation alloc] initWithCoordinate:placeCoord title:name];
        
        [self.mapView addAnnotation:placeObject];
    }
}

// Define Annotation Parameters
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {

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


//Center map on new location
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



#pragma mark - Search Bar Declarations

//Finding coordinates from a location search
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    searchBar.keyboardType = UIKeyboardTypeWebSearch;
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:searchBar.text
                 completionHandler:^(NSArray* placemarks, NSError* error){
            
                     CLPlacemark *placemark = [placemarks objectAtIndex:0];
                     CLLocation *location = placemark.location;
                     CLLocationCoordinate2D coordinate = location.coordinate;
                     searchBar.text = @"";
                     [searchBar resignFirstResponder];
                      [self.mapView setCenterCoordinate:coordinate animated:YES];
                     
                 }];
}

//Refresh User Location
- (IBAction)updateCurrentLocation:(id)sender
{
    if (_authorizationStatus == kCLAuthorizationStatusAuthorized)
    {
        [self.mapView setCenterCoordinate:self.locationManager.location.coordinate animated:YES];
    } else {
        [self checkLocationStatus];
    }
}

#pragma mark - Add Points of Interest
- (IBAction)addPointsOfInterest:(id)sender
{
    if (_authorizationStatus == kCLAuthorizationStatusAuthorized)
    {
        //Query the Google Places API
        [self queryGooglePlaces];
    } else {
        [self checkLocationStatus];
    }
}


#pragma mark - Add New Pin to Map

- (void)addGestureRecogniser
{
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(addPinToMap:)];
    
    gesture.minimumPressDuration = 0.5;
    [self.mapView addGestureRecognizer:gesture];
}

- (void)addPinToMap:(UIGestureRecognizer *)gestureRecognizer
{
    
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    SFMapAnnotation *newAnnotation = [[SFMapAnnotation alloc] init];
    
    newAnnotation.coordinate = touchMapCoordinate;
    newAnnotation.title = @"New Annotation";
    
    [self.mapView addAnnotation:newAnnotation];
}

-(void)checkLocationStatus
{
    UIAlertView *status =[[UIAlertView alloc] initWithTitle:@"You have disabled location services"
                                                    message:@"You can't use the app unless you do :-("
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    [status show];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"%u", status);
    _authorizationStatus = status;
}

@end
