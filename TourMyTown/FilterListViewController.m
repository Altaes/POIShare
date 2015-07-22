//
//  FilterListViewController.m
//  TourMyTown
//
//  Created by Michael Katz on 10/10/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import "FilterListViewController.h"

#import "Categories.h"

@interface FilterListViewController ()
@property (nonatomic, retain) NSMutableArray* selections;
@end

@implementation FilterListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype) initWithSelectedCategories:(NSArray*)selections deleagte:(id<CategoryDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.selections = [NSMutableArray arrayWithArray:selections];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.title = @"Choose categories";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.delegate selectedCategories:self.selections];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [Categories allCategories].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString* category = [Categories allCategories][indexPath.row];
    cell.textLabel.text = category;
    cell.accessoryType = [self.selections containsObject:category] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* category = [Categories allCategories][indexPath.row];
    BOOL on = [self.selections containsObject:category];
    if (on) {
        [self.selections removeObject:category];
    } else {
        [self.selections addObject:category];
    }
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
@end
