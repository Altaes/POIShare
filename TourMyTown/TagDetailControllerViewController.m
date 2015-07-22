//
//  TagDetailControllerViewController.m
//  TourMyTown
//
//  Created by Michael Katz on 9/30/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import "TagDetailControllerViewController.h"
#import "AppDelegate.h"
#import "Location.h"

#import "FilterListViewController.h"

#define kCategoryRow 2

@interface TagDetailControllerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, CategoryDelegate>
@property (nonatomic, strong) UIImage* picture;
@end

@implementation TagDetailControllerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.descriptionTextField.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        [self persistLocation];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.location) {
        self.titleTextField.text = self.location.name;
        self.descriptionTextField.text = self.location.details;
    }
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kCategoryRow) {
        FilterListViewController* flvc = [[FilterListViewController alloc] initWithSelectedCategories:self.location.categories deleagte:self];
        [self.navigationController pushViewController:flvc animated:YES];
    }
}

- (void)selectedCategories:(NSArray *)array
{
    [self.location.categories setArray:array];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kCategoryRow inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kCategoryRow) {
        cell.detailTextLabel.text = [self.location.categories componentsJoinedByString:@", "];
    }
}
#pragma mark - Model
- (void) persistLocation
{
    if (!self.location) {
        self.location = [[Location alloc] init];
    }
    
    BOOL modified = ![self.location.name isEqualToString:self.titleTextField.text] || ![self.location.details isEqualToString:self.descriptionTextField.text] || ![self.location.image isEqual:self.picture];
    if (modified) {
        self.location.name = self.titleTextField.text;
        self.location.details = self.descriptionTextField.text;
        self.location.image = self.picture;
        self.location.configuredBySystem = NO;
        
        [[AppDelegate appDelegate].locations persist:self.location];
    }
}

#pragma mark - Images
- (IBAction) takePicture:(id)sender
{
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [self presentViewController:imagePicker animated:YES completion:^{
        
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [self dismissModalViewControllerAnimated:YES];
    self.picture = image;
    self.imageView.image = image;
}


#pragma mark - Text
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (textField == self.descriptionTextField) {
        self.location.details = textField.text;
    }
}
@end
