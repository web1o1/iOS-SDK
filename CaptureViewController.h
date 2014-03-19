//
//  CaptureViewController.h
//
//  Created by linfish on 13/9/4.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KernelDefinition.h"
#import "RecognitionKernel.h"

@protocol CaptureDelegate <NSObject>
@optional
// recognize matched images, with matched image names and query image
- (void)recognizeMatched:(NSArray*)names withImage:(UIImage*)image;

// recognize similar images, with similar image names and query image
- (void)recognizeSimilar:(NSArray*)names withImage:(UIImage*)image;

// need more images for recognize similar images, with query image
- (void)recognizeNeedMore:(UIImage*)image;

// recognize failed, with query image
- (void)recognizeFailed:(UIImage*)image;

// one recognize process begin, use this function to start scan animation
- (void)recognizeBegin;

// one recognize process ended, use this function to stop scan animation
- (void)recognizeEnd;

// report kernel errors
- (void)notifyError:(KernelError)error;
@end

@interface CaptureViewController : UIViewController

// RecognitionKernel API general
// general setting function, please set before recognition process start
- (void)setUser:(NSString*)name;                     // required, please set account name
- (void)setLogLocation:(BOOL)enable;                 // default: NO, set to YES to enable logging user location
- (void)setRecognizeSimilar:(BOOL)enable;            // default: NO, set to YES to enable similar recogniiton
- (void)setRecognizeMode:(KernelMode)mode;           // default: km_online, please check KernelDefinition.h for more details
- (void)setRecognizePrefer:(KernelPrefer)option;     // default: kp_speed, please check KernelDefinition.h for more details

// CaptureViewController API
- (void)setDelegate:(id<CaptureDelegate>)scanDelegate;
- (void)setInterest:(CGRect)region withBorder:(UIColor*)color;  // default CGRectZero, set non CGRectZero will only recognize in region and add visual effect
- (void)recognizeCapture:(CGRect)region;    // capture next frame to do recognition inside region
- (void)recognizeCapture;   // capture next frame to do recognition
@end
