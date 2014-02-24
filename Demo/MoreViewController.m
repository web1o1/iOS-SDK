//
//  MoreViewController.m
//
//  Created by linfish on 13/9/9.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import "MoreViewController.h"
#import "DetailViewController.h"

@interface MoreViewController ()

@end

@implementation MoreViewController
@synthesize names;
@synthesize images;

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
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.names count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.text = [self.names objectAtIndex:indexPath.row];

    UIImage *image = [self.images objectAtIndex:indexPath.row];
    if (image != nil && ![image isEqual:[NSNull null]]) {
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.imageView.frame = CGRectMake(0.0, 0.0, cell.frame.size.height, cell.frame.size.height);
        cell.imageView.image = image;
    }
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    DetailViewController *detailViewController = [[DetailViewController alloc] init];
    detailViewController.title = [self.names objectAtIndex:indexPath.row];
    detailViewController.view.backgroundColor = [UIColor darkGrayColor];

    UIImage *image = [self.images objectAtIndex:indexPath.row];
    if (image != nil && ![image isEqual:[NSNull null]]) {
        detailViewController.image = image;
    }

    [self.navigationController pushViewController:detailViewController animated:YES];
}

@end
