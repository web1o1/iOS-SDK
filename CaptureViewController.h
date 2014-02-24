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

// barcode or QR code detected, with decoded strings and query image
- (void)barcodeDecoded:(NSArray*)names withImage:(UIImage*)image;

// report kernel errors
- (void)notifyError:(KernelError)error;
@end

@interface CaptureViewController : UIViewController

// RecognitionKernel API general
// general setting function, please set before recognition process start
- (void)setUser:(NSString*)name;                     // required, please set account name
- (void)setLogLocation:(BOOL)enable;                 // default: NO, set to YES to enable logging user location
- (void)setDecodeBarCode:(BOOL)enable;               // default: NO, set to YES to decode barcode and QRcode
- (void)setRecognizeSimilar:(BOOL)enable;            // default: NO, set to YES to enable similar recogniiton
- (void)setRecognizeMode:(KernelMode)mode;           // default: km_online, please check KernelDefinition.h for more details
- (void)setRecognizePrefer:(KernelPrefer)option;     // default: kp_speed, please check KernelDefinition.h for more details

// RecognitionKernel API for offline mode
- (KernelError)loadKernelData;  // let offline kernel start checking update and load
                                // large image database may take few seconds loading

- (BOOL)isKernelReady;          // check if offline kernel finished loading data and ready for recognition


- (void)unloadKernelData;       // not necessary but to reduce memory usage when offline kernel not in use
                                // usually called when user will not recongize in a short time, view switching

// CaptureViewController API
- (void)setDelegate:(id<CaptureDelegate>)scanDelegate;
- (void)setInterest:(CGRect)region withBorder:(UIColor*)color;  // default CGRectZero, set non CGRectZero will only recognize in region and add visual effect
- (void)recognizeCapture:(CGRect)region;    // capture next frame to do recognition inside region
- (void)recognizeCapture;   // capture next frame to do recognition
@end
