//
//  SFViewController.h
//  SFMapApp
//
//  Created by Spencer Fornaciari on 11/19/13.
//  Copyright (c) 2013 Spencer Fornaciari. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "SFMapAnnotation.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


@interface SFViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;

@property (nonatomic) CLLocationCoordinate2D pointCenter;
@property (nonatomic) int currentDistance;

@property (strong, nonatomic) IBOutlet UISearchBar *mapSearch;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)updateCurrentLocation:(id)sender;
- (IBAction)addPointsOfInterest:(id)sender;

@end
