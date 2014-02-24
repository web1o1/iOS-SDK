//
//  DetailViewController.m
//
//  Created by linfish on 13/9/3.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

#pragma mark - UIViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    self.view.backgroundColor = [UIColor darkGrayColor];
    if (self.image != nil) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.image];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.frame = self.view.frame;
        [self.view addSubview:imageView];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
