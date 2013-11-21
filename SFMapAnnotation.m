//
//  SFMapAnnotation.m
//  SFMapApp
//
//  Created by Spencer Fornaciari on 11/20/13.
//  Copyright (c) 2013 Spencer Fornaciari. All rights reserved.
//

#import "SFMapAnnotation.h"


@implementation SFMapAnnotation

//- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate;

-(id) initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title;
{
    self = [super init];
    self.title = title;
    self.coordinate = coordinate;
    
    return self;
}


@end
