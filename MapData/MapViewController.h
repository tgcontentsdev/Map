//
//  MapViewController.h
//  MapData
//
//  Created by 佐分晴紀 on 2016/01/10.
//  Copyright © 2016年 Haruki. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MapViewController : ViewController

@property (assign,nonatomic) BOOL isLocation;

@property (assign,nonatomic) CLLocationDegrees longitude;
@property (assign,nonatomic) CLLocationDegrees latitude;

@end

