//
//  TagDetailControllerViewController.h
//  TourMyTown
//
//  Created by Michael Katz on 9/30/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Location;

@interface TagDetailControllerViewController : UITableViewController

@property (strong, nonatomic) Location* location;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@end
