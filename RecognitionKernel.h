//
//  RecognitionKernel.h
//
//  Created by linfish on 13/8/26.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "KernelDefinition.h"
#import "RecognitionResult.h"

@protocol KernelDelegate <NSObject>
@optional
// notify errors, please check KernelDefinition.h to get error defines
- (void)notifyError:(KernelError)error;
@end

@interface RecognitionKernel : NSObject

// general
- (void)setUser:(NSString*)name;                     // required, please set account name
- (void)setLogLocation:(BOOL)enable;                 // default: NO, set to YES to enable logging user location
- (void)setDecodeBarCode:(BOOL)enable;               // default: NO, set to YES to decode barcode and QRcode
- (void)setRecognizeSimilar:(BOOL)enable;            // default: NO, set to YES to enable similar recogniiton
- (void)setRecognizeMode:(KernelMode)mode;           // default: km_online, please check KernelDefinition.h for more details
- (void)setRecognizePrefer:(KernelPrefer)option;     // default: kp_speed, please check KernelDefinition.h for more details
- (void)setDelegate:(id<KernelDelegate>)kernelDelegate;  // default: nil, implement the delegate to get kernel error notification

// recognition function, depends on kernel mode to run online or offline
- (RecognitionResult*)recognize:(UIImage*)image;
- (RecognitionResult*)recognize:(UIImage*)image withInterest:(CGRect)region;

// following methods are only for offline recognition
- (KernelError)loadKernelData;  // let offline kernel start checking update and load
                                // large image database may take few seconds loading

- (BOOL)isKernelReady;          // check if offline kernel finished loading data and ready for recognition


- (void)unloadKernelData;       // not necessary but to reduce memory usage when offline kernel not in use
                                // usually called when user will not recongize in a short time, view switching

- (void)resetSimilarity;        // this function will reset similar recognize history
                                // usually called when user change focus to another item, maybe large motion, view switching
@end
