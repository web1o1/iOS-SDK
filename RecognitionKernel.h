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
- (void)setUser:(NSString*)name;                     // required
- (void)setLogLocation:(BOOL)enable;                 // default: no
- (void)setRecognizeSimilar:(BOOL)enable;            // default: no
- (void)setRecognizeMode:(KernelMode)mode;           // default: km_online
- (void)setRecognizePrefer:(KernelPrefer)option;     // default: kp_speed
- (void)setDelegate:(id<KernelDelegate>)kernelDelegate;  // default: nil

// recognition function, depends on kernel mode to run online or offline
- (RecognitionResult*)recognize:(UIImage*)image;
- (RecognitionResult*)recognize:(UIImage*)image withInterest:(CGRect)region;
@end
