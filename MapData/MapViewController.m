//
//  MapViewController.m
//  MapData
//
//  Created by 佐分晴紀 on 2016/01/10.
//  Copyright © 2016年 Haruki. All rights reserved.
//

#import "MapViewController.h"
#import "CustomAnnotation.h"
#import "DataViewController.h"

@interface MapViewController ()<MKMapViewDelegate,CLLocationManagerDelegate>

@property(strong,nonatomic) CLLocationManager *locationManager;
@property(strong,nonatomic) NSMutableArray *annotationArray;
@property(weak,nonatomic) IBOutlet MKMapView *mapView;

@property(weak,nonatomic) IBOutlet UIButton *addButton;
@property(weak,nonatomic) IBOutlet UIButton *dataButton;

-(IBAction)addButtonAction:(id)sender;
-(IBAction)dataButtonAction:(id)sender;


@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.distanceFilter = 5;
    
    [self.locationManager requestWhenInUseAuthorization];
    
    self.isLocation = NO;
    
    [self.locationManager startUpdatingLocation];
    
    self.mapView.delegate = self;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;


}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSUserDefaults *nd = [NSUserDefaults standardUserDefaults];
    NSMutableData *data = [nd objectForKey:@"annotationData"];
    NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]initForReadingWithData:data];
    
    self.annotationArray = [[decoder decodeObjectForKey:@"annotation"]mutableCopy];
    [decoder finishDecoding];
    
    if (self.isLocation) {
        CLLocationCoordinate2D co;
        co.latitude = self.latitude;
        co.longitude = self.longitude;
        self.mapView.centerCoordinate = co;
        
        MKCoordinateSpan span = MKCoordinateSpanMake(0.01,0.01);
        MKCoordinateRegion region = MKCoordinateRegionMake(co, span);
        [self.mapView setRegion:region animated:YES];
    }
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    
    if (self.annotationArray == nil) {
        self.annotationArray = [NSMutableArray arrayWithCapacity:0];
    }
    
    for (CustomAnnotation *annotation in self.annotationArray) {
        [self.mapView addAnnotation:annotation];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    self.longitude = newLocation.coordinate.longitude;
    self.latitude = newLocation.coordinate.latitude;
    
    self.isLocation = YES;
}


-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    [self.locationManager stopUpdatingLocation];
}

-(MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    
    if (annotation == mapView.userLocation) {
        return  nil;
    }
    
    MKAnnotationView *annotationView;
    NSString* identifier = @"Pin";
    annotationView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if (nil == annotationView) {
        annotationView = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:identifier];
    }
    annotationView.canShowCallout = YES;
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    annotationView.annotation = annotation;
    
    return annotationView;
}

-(IBAction)addButtonAction:(id)sender{
    
    CLLocationCoordinate2D co;
    co.latitude = self.latitude;
    co.longitude = self.longitude;
    self.mapView.centerCoordinate = co;
    
    MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
    MKCoordinateRegion region = MKCoordinateRegionMake(co, span);
    [self.mapView setRegion:region animated:YES];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    CLLocation *location = [[CLLocation alloc]initWithLatitude:self.latitude longitude:self.longitude];
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks,NSError *error){
        if (error) {
            NSLog(@"リバースジオコーディング失敗");
        }else{
            if (0 < [placemarks count]) {
                for(CLPlacemark *placemark in placemarks){
                    NSString *name = [NSString stringWithFormat:@"%@",placemark.name];
                    NSString *address = [NSString stringWithFormat:@"%@%@%@%@%@",placemark.country,placemark.administrativeArea,placemark.locality,placemark.thoroughfare,placemark.subThoroughfare];
                    
                    CustomAnnotation *annotation;
                    CLLocationCoordinate2D annoLocation;
                    annoLocation.latitude = self.latitude;
                    annoLocation.longitude = self.longitude;
                    annotation =[[CustomAnnotation alloc]initWithCoordinate:annoLocation];
                    annotation.title = name;
                    annotation.subtitle = address;
                    [self.mapView addAnnotation:annotation];
                    
                    [self.annotationArray addObject:annotation];
                    
                    NSUserDefaults *nd =[NSUserDefaults standardUserDefaults];
                    NSMutableData *data = [NSMutableData data];
                    NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
                    
                    [encoder encodeObject:[self.annotationArray copy] forKey:@"annotation"];
                    
                    [encoder finishEncoding];
                    [nd setObject:data forKey:@"annotationData"];
                    [nd synchronize];
                    
                }
            }
        }
    }];
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    
    CLLocationCoordinate2D fromCoordinate = CLLocationCoordinate2DMake(self.latitude, self.longitude);
    CLLocationCoordinate2D toCoordinate = view.annotation.coordinate;
    
    MKPlacemark *fromPlacemark = [[MKPlacemark alloc]initWithCoordinate:fromCoordinate addressDictionary:nil];
    MKPlacemark *toPlacemark = [[MKPlacemark alloc]initWithCoordinate:toCoordinate addressDictionary:nil];
    
    MKMapItem *fromItem = [[MKMapItem alloc]initWithPlacemark:fromPlacemark];
    MKMapItem *toItem = [[MKMapItem alloc]initWithPlacemark:toPlacemark];
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    request.source = fromItem;
    request.destination = toItem;
    request.requestsAlternateRoutes = YES;
    
    MKDirections *directions = [[MKDirections alloc]initWithRequest:request];
    
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response,NSError *error){
        if (error) return ;
        
        if ([response.routes count] > 0) {
            MKRoute *route = [response.routes objectAtIndex:0];
            
            [self.mapView addOverlay:route.polyline];
        }
        
    }];
}


-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *route = overlay;
        MKPolylineRenderer *routeRenderer = [[MKPolylineRenderer alloc]initWithPolyline:route];
        routeRenderer.lineWidth = 5.0;
        routeRenderer.strokeColor = [UIColor redColor];
        return routeRenderer;
    }else{
        return  nil;
    }
}

-(IBAction)dataButtonAction:(id)sender{
    
    [self performSegueWithIdentifier:@"DataView" sender:self];
}

-(IBAction)exitFromDataView:(UIStoryboardSegue *)sender{
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"DataView"]) {
        
    }
}







/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
