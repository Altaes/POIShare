//
//  AppDelegate.h
//  TourMyTown
//
//  Created by Michael Katz on 8/3/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Locations.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/** Singleton data model */
@property (strong, nonatomic) Locations* locations;

/** Helper to get static instance */
+ (AppDelegate*) appDelegate;

@end
