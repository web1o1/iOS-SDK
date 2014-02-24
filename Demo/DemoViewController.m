//
//  DemoViewController.m
//
//  Created by linfish on 13/8/26.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import "DemoViewController.h"
#import "DemoDataHandler.h"
#import "DetailViewController.h"
#import "MoreViewController.h"

@interface DemoViewController ()
@property (nonatomic, retain) UIView *scanBar;
@property (nonatomic, retain) UIActivityIndicatorView *indicator;
@property (nonatomic, retain) UIButton *addImageButton;
@property (nonatomic, retain) UIButton *clearDataButton;
@property (nonatomic, retain) UIButton *switchModeButton;
@property (nonatomic, retain) DemoDataHandler *dataHandler;
@property (nonatomic, retain) UIImage *capturedImage;
@property (nonatomic, retain) NSArray *resultNames;
@property (nonatomic, assign) KernelMode mode;
@property (nonatomic, retain) NSDate *start;
@end

@implementation DemoViewController
@synthesize scanBar;
@synthesize indicator;
@synthesize addImageButton;
@synthesize clearDataButton;
@synthesize switchModeButton;
@synthesize dataHandler;
@synthesize capturedImage;
@synthesize resultNames;
@synthesize mode;
@synthesize start;

//CGRect region = CGRectMake(8.0, 36.0, 304.0, 384.0);
CGRect region = CGRectZero;
UIColor *color = [UIColor colorWithRed:0.1 green:0.63 blue:0.9 alpha:1.0];

typedef enum {
    at_matched = 0,
    at_matched_more,
    at_similar,
    at_similar_more,
    at_add_image,
    at_add_image_warning,
    at_clear_data
} AlertTag;

#pragma mark - UIViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setUser:@"demo"];
        [self setLogLocation:YES];
        [self setDecodeBarCode:YES];
        [self setRecognizeSimilar:YES];
        [self setRecognizeMode:km_online];
        [self setRecognizePrefer:kp_speed];

        [self setDelegate:self];
        [self setInterest:region withBorder:color];
        [self loadKernelData];

        self.mode = km_online;
        self.dataHandler = [[DemoDataHandler alloc] initWithUser:@"demo"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (CGRectEqualToRect(region, CGRectZero)) {
        region = self.view.bounds;
    }
    self.scanBar = [[UIView alloc] initWithFrame:CGRectMake(region.origin.x, region.origin.y, region.size.width, 3.0)];
    [self.scanBar setBackgroundColor:color];
    [self.scanBar setHidden:YES];
    [self.view addSubview:self.scanBar];

    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.indicator.center = CGPointMake(region.origin.x + region.size.width / 2.0, region.origin.y + region.size.height / 2.0);
    [self.view addSubview:self.indicator];

    self.addImageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.addImageButton addTarget:self action:@selector(addImage) forControlEvents:UIControlEventTouchUpInside];
    [self.addImageButton setFrame:CGRectMake(3.0, self.view.bounds.size.height - 48.0, self.view.bounds.size.width / 3.0 - 6.0, 40.0)];
    [self.addImageButton setTitle:@"Add Image" forState:UIControlStateNormal];
    [self.view addSubview:self.addImageButton];

    self.switchModeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.switchModeButton addTarget:self action:@selector(switchMode:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchModeButton setFrame:CGRectMake(self.view.bounds.size.width / 3.0 + 3.0, self.view.bounds.size.height - 48.0, self.view.bounds.size.width / 3.0 - 6.0, 40.0)];
    [self.switchModeButton setTitle:@"Offline Mode" forState:UIControlStateNormal];
    [self.view addSubview:self.switchModeButton];

    self.clearDataButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.clearDataButton addTarget:self action:@selector(clearData) forControlEvents:UIControlEventTouchUpInside];
    [self.clearDataButton setFrame:CGRectMake(2.0 * self.view.bounds.size.width / 3.0 + 3.0,
                                         self.view.bounds.size.height - 48.0,
                                         self.view.bounds.size.width / 3.0 - 6.0, 40.0)];
    [self.clearDataButton setTitle:@"Clear Data" forState:UIControlStateNormal];
    [self.view addSubview:self.clearDataButton];


    NSString *logoPath = [[NSBundle mainBundle] pathForResource:@"funwish_logo" ofType:@"png"];
    UIImage *logo = [UIImage imageWithContentsOfFile:logoPath];
    UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake(8.0, 8.0, 72.0, 24.0)];
    logoView.image = logo;
    [self.view addSubview:logoView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runAnimation) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.scanBar.hidden = YES;
    [self.view.layer removeAllAnimations];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Animation Control
- (void)runAnimation
{
    self.scanBar.frame = CGRectMake(region.origin.x, region.origin.y, region.size.width, 3.0);
    [UIView animateWithDuration:2.0
                          delay:0.0
                        options:UIViewAnimationOptionRepeat |
                                UIViewAnimationOptionCurveLinear |
                                UIViewAnimationOptionAutoreverse |
                                UIViewAnimationOptionOverrideInheritedCurve |
                                UIViewAnimationOptionOverrideInheritedDuration
                     animations:^{ self.scanBar.frame = CGRectMake(region.origin.x, region.origin.y + region.size.height, region.size.width, 3.0); }
                     completion:nil];
}

- (void)showAnimation
{
    if (self.scanBar.hidden == YES) {
        [self runAnimation];
        self.scanBar.hidden = NO;
        self.start = [NSDate date];
    }
}

- (void)hideAnimation
{
    self.scanBar.hidden = YES;
    [self.view.layer removeAllAnimations];
}

#pragma mark - ScanDelegate
- (void)recognizeMatched:(NSArray*)names withImage:(UIImage*)image
{
    self.resultNames = names;
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.start];
    UIAlertView *alert = nil;
    if ([names count] == 1) {
        alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Matched - %.2f", interval]
                                           message:[names objectAtIndex:0]
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"Detail", nil];
        alert.tag = at_matched;
    } else {
        NSString *msg = @"";
        for (int i = 0; i < [names count] && i < 3; i++) {
            msg = [msg stringByAppendingString:[names objectAtIndex:i]];
            if (i + 1 != [names count]) {
                msg = [msg stringByAppendingString:@"\n"];
            }
        }
        alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Matched - %.2f", interval]
                                           message:msg
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"More", nil];
        alert.tag = at_matched_more;
    }

    [alert show];
}

- (void)recognizeSimilar:(NSArray*)names withImage:(UIImage*)image
{
    self.resultNames = names;
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.start];
    UIAlertView *alert = nil;
    if ([names count] == 1) {
        alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Similar - %.2f", interval]
                                           message:[names objectAtIndex:0]
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"Detail", nil];
        alert.tag = at_similar;
    } else {
        NSString *msg = @"";
        for (int i = 0; i < [names count] && i < 3; i++) {
            msg = [msg stringByAppendingString:[names objectAtIndex:i]];
            if (i + 1 != [names count]) {
                msg = [msg stringByAppendingString:@"\n"];
            }
        }
        alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Similar - %.2f", interval]
                                           message:msg
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"More", nil];
        alert.tag = at_similar_more;
    }

    [alert show];
}

- (void)recognizeFailed:(UIImage*)image
{
    NSLog(@"failed");
}

- (void)recognizeBegin
{
    [self showAnimation];
}

- (void)recognizeEnd
{
    // do nothing
}

- (void)barcodeDecoded:(NSArray*)names withImage:(UIImage*)image
{
    self.resultNames = names;
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.start];
    UIAlertView *alert = nil;
    if ([names count] == 1) {
        alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Barcode - %.2f", interval]
                                           message:[names objectAtIndex:0]
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:nil];
    } else {
        NSString *msg = @"";
        for (int i = 0; i < [names count] && i < 3; i++) {
            msg = [msg stringByAppendingString:[names objectAtIndex:i]];
            if (i + 1 != [names count]) {
                msg = [msg stringByAppendingString:@"\n"];
            }
        }
        alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Barcode - %.2f", interval]
                                           message:msg
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:nil];
    }

    [alert show];
}

// notify when detecting errors
- (void)notifyError:(KernelError)error
{
    NSLog(@"error %d", error);
}

// return captured frame
- (void)capturedFrame:(UIImage*)image
{
    self.capturedImage = image;

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter Description"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Add Data", nil];
    alert.tag = at_add_image;
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    UITextField *textField = [alert textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeAlphabet;

    [alert show];
}

#pragma mark - UIAlertViewDelegate
- (void)willPresentAlertView:(UIAlertView *)alertView  // before animation and showing view
{
    [self hideAnimation];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (alertView.tag == at_add_image) {
            NSString *name = [alertView textFieldAtIndex:0].text;
            if ([name length] >= 3) {
                [self startBusy];
            }
        } else if (alertView.tag == at_clear_data) {
            [self startBusy];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self recognizeContinue];
    } else if (alertView.tag == at_add_image) {
        NSString *name = [alertView textFieldAtIndex:0].text;
        if ([name length] >= 3) {
            [self.dataHandler addImage:self.capturedImage withName:name];
            [self loadKernelData];
            [self endBusy];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Description Too Short"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            alert.tag = at_add_image_warning;
            [alert show];
        }
    } else if (alertView.tag == at_clear_data) {
        [self.dataHandler clearData];
        [self loadKernelData];
        [self endBusy];
    } else if (alertView.tag == at_matched_more || alertView.tag == at_similar_more) {
        MoreViewController *moreViewController = [[MoreViewController alloc] initWithStyle:UITableViewStylePlain];
        moreViewController.title = @"More";

        NSMutableArray *images = [[NSMutableArray alloc] init];
        for (NSString *name in self.resultNames) {
            UIImage *image = [self.dataHandler getImage:name];
            if (image == nil) {
                [images addObject:[NSNull null]];
            } else {
                [images addObject:image];
            }
        }
        moreViewController.names = self.resultNames;
        moreViewController.images = images;
        [self.navigationController pushViewController:moreViewController animated:YES];
    } else {
        DetailViewController *detailViewController = [[DetailViewController alloc] init];
        detailViewController.title = alertView.title;
        detailViewController.view.backgroundColor = [UIColor darkGrayColor];

        UIImage *image = [self.dataHandler getImage:alertView.message];
        detailViewController.image = image;
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}

#pragma mark - DemoViewController private
- (void)startBusy
{
    dispatch_async(dispatch_get_main_queue(), ^{ [self.indicator startAnimating]; });
    self.addImageButton.enabled = NO;
    self.clearDataButton.enabled = NO;
}

- (void)endBusy
{
    self.addImageButton.enabled = YES;
    self.clearDataButton.enabled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{ [self.indicator stopAnimating]; });

    [self recognizeContinue];
}

- (void)switchMode:(UIButton*)button
{
    if (self.mode == km_offline) {
        self.mode = km_online;
        [self.switchModeButton setTitle:@"Online Mode" forState:UIControlStateNormal];
    } else {
        self.mode = km_offline;
        [self.switchModeButton setTitle:@"Offline Mode" forState:UIControlStateNormal];
    }
    [self setRecognizeMode:self.mode];
}

- (void)addImage
{
    [self recognizePause];
    [self captureNextFrame];
}

- (void)clearData
{
    [self recognizePause];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Clear Data"
                                                    message:@"All recognition data added\nby \"Add Image\" will be cleared"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Process", nil];
    alert.tag = at_clear_data;
    [alert show];
}
@end
