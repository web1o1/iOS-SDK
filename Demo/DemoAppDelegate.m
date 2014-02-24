//
//  DemoAppDelegate.m
//
//  Created by linfish on 13/8/22.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import "DemoAppDelegate.h"
#import "DemoViewController.h"

@interface DemoAppDelegate ()
@property (strong, retain) UINavigationController *navControl;
@end

@implementation DemoAppDelegate
@synthesize navControl;

- (void)launchImageClicked
{
    [UIView transitionWithView:self.window
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCurlUp
                    animations:^{ [self.window setRootViewController:self.navControl]; }
                    completion:nil];
}

#pragma mark - AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application setApplicationSupportsShakeToEdit:YES];
    [application setStatusBarHidden:YES];

    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:screenFrame];

    DemoViewController *demoViewControl = [[DemoViewController alloc] init];
    if (demoViewControl) {
        self.navControl = [[UINavigationController alloc] initWithRootViewController:demoViewControl];
        [self.navControl setNavigationBarHidden:YES];
    } else {
        NSLog(@"Error: DemoViewController Init Failed!");
        return NO;
    }

    UIImage *launchImage = nil;
    if (screenFrame.size.height >= 568) {
        launchImage = [UIImage imageNamed:@"funwish_welcome-568h@2x.png"];
    } else if ([UIScreen mainScreen].scale >= 2) {
        launchImage = [UIImage imageNamed:@"funwish_welcome@2x.png"];
    } else {
        launchImage = [UIImage imageNamed:@"funwish_welcome.png"];
    }

    UIImageView *launchImageView = [[UIImageView alloc] initWithImage:launchImage];
    CGRect launchFrame = screenFrame;
    [launchImageView setFrame:launchFrame];

    UIButton *launchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [launchButton setBackgroundColor:[UIColor clearColor]];
    [launchButton setFrame:screenFrame];
    [launchButton addTarget:self action:@selector(launchImageClicked) forControlEvents:UIControlEventTouchUpInside];

    UIViewController *launchViewControl = [[UIViewController alloc] init];
    [launchViewControl.view addSubview:launchImageView];
    [launchViewControl.view addSubview:launchButton];

    [self.window setRootViewController:launchViewControl];
    [self.window setBackgroundColor:[UIColor clearColor]];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
