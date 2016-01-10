//
//  CustomAnnotation.h
//  MapData
//
//  Created by 佐分晴紀 on 2016/01/10.
//  Copyright © 2016年 Haruki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface CustomAnnotation : MKAnnotationView <MKAnnotation,NSCoding>

@property(nonatomic,assign)CLLocationCoordinate2D coordinate;

@property(nonatomic,copy)NSString* title;
@property(nonatomic,copy)NSString* subtitle;

-(id)initWithCoordinate:(CLLocationCoordinate2D) coordinate;

-(void)encodeWithCoder:(NSCoder *)aCoder;
-(id)initWithCoder:(NSCoder *)aDecoder;

@end
