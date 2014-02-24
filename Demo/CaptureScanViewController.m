//
//  CaptureScanViewController.m
//
//  Created by linfish on 13/8/26.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import "CaptureScanViewController.h"

#import <libkern/OSAtomic.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>
#import "ImageProcessing.h"

typedef enum {
    ss_idle = 0,
    ss_process,
    ss_need_more, // for similar recognize need_more result
    ss_recognize
} CaptureScanState;

@interface CaptureScanViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, KernelDelegate>
@property (nonatomic, retain) AVCaptureDevice *device;
@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) CMMotionManager *motion;
@property (nonatomic, retain) RecognitionKernel *kernel;
@property (nonatomic, retain) UIImageView *overlay;
@property (nonatomic, assign) id<CaptureScanDelegate> delegate;
@property (nonatomic, assign) CGRect interestRegion;
@property (nonatomic, assign) CGRect captureRegion;
@property (nonatomic, assign) CGRect cropRegion;
@property (nonatomic, assign) CGPoint focusPoint;
@property (assign) CaptureScanState state;
@property (assign) BOOL pause;
@property (assign) BOOL capture;
@end

@implementation CaptureScanViewController
@synthesize device;
@synthesize session;
@synthesize motion;
@synthesize kernel;
@synthesize overlay;
@synthesize delegate;
@synthesize interestRegion;
@synthesize captureRegion;
@synthesize cropRegion;
@synthesize focusPoint;
@synthesize state;
@synthesize pause;
@synthesize capture;

#pragma mark - UIViewController
- (id)initCaptureScanViewController
{
    // check if device avliable
    self.device = nil;
    self.focusPoint = CGPointMake(0.5, 0.5);
    for (AVCaptureDevice *available_device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([available_device position] == AVCaptureDevicePositionBack) {
            self.device = available_device;
            [self setDeviceContinuous3A:self.focusPoint];
            break;
        }
    }
    // no device avaliable
    if (!self.device) {
        NSLog(@"[Scan] Initial failed, no support device");
        return nil;
    }

    self.motion = [[CMMotionManager alloc] init];
    if (self.motion.deviceMotionAvailable) {
        self.motion.deviceMotionUpdateInterval = 0.1;
    }

    self.kernel = [[RecognitionKernel alloc] init];
    [self.kernel setDelegate:self];

    self.delegate = nil;
    self.interestRegion = CGRectZero;
    self.captureRegion = CGRectZero;
    self.cropRegion = CGRectZero;
    self.state = ss_idle;
    self.pause = YES;
    self.capture = NO;
    NSLog(@"[Scan] Initial success");
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self = [self initCaptureScanViewController];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self = [self initCaptureScanViewController];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        // for iphone 4 or above
        self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    } else if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        // for iphone 3gs
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
    } else {
        self.session.sessionPreset = AVCaptureSessionPreset352x288;
    }

    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    if (input == nil || ![self.session canAddInput:input]) {
        NSLog(@"[Scan] No avaliable input device");
        return;
    }
    [self.session addInput:input];

    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.alwaysDiscardsLateVideoFrames = YES;
    output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.session addOutput:output];

    dispatch_queue_t queue = dispatch_queue_create("video_handle", NULL);
    [output setSampleBufferDelegate:self queue:queue];
#if !__has_feature(objc_arc)
    dispatch_release(queue);
#endif

    // Display camera view
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    previewLayer.frame = self.view.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    UIView *preview = [[UIView alloc] initWithFrame:self.view.bounds];
    preview.backgroundColor = [UIColor clearColor];
    [preview.layer addSublayer:previewLayer];
    [self.view addSubview:preview];

    self.overlay = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.overlay];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.motion startDeviceMotionUpdates];
    [self.session startRunning];
    [self setDeviceContinuous3A:self.focusPoint];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self recognizeContinue];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.capture = NO;
    [self recognizePause];
    [self.session stopRunning];
    [self.kernel resetSimilarity];
    [self.motion stopDeviceMotionUpdates];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self recognizePause];
    for (UITouch *touch in touches) {
        CGPoint touchPoint = [touch locationInView:self.view];
        touchPoint = CGPointMake(touchPoint.y / self.view.bounds.size.height, 1.0 - touchPoint.x / self.view.bounds.size.width);

        float previewWidth = 352.0;
        float previewHeight = 288.0;
        if ([self.session.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
            previewWidth = 1280.0;
            previewHeight = 720.0;
        } else if ([self.session.sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
            previewWidth = 640.0;
            previewHeight = 480.0;
        }
        float scale = (previewWidth * self.view.bounds.size.width) / (previewHeight * self.view.bounds.size.height);
        if (scale < 1.0) {
            touchPoint.y = (touchPoint.y - 0.5) * scale + 0.5;
        } else if (scale > 1.0) {
            touchPoint.x = (touchPoint.x - 0.5) / scale + 0.5;
        }
        NSLog(@"[Scan] focus at point (%f, %f)", touchPoint.x, touchPoint.y);

        [self setDeviceContinuous3A:touchPoint];
        break;
    }
    [self recognizeContinue];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.delegate == nil) {
        return;
    }

    if (self.device.adjustingFocus || self.device.adjustingExposure || self.device.adjustingWhiteBalance) {
        return;
    }

    if (self.pause) {
        if (self.capture) {
            self.capture = NO;
            UIImage *image = [ImageProcessing makeImageFromSampleBuffer:sampleBuffer];
            if (!CGRectEqualToRect(self.captureRegion, CGRectZero)) {
                image = [ImageProcessing cropImage:image withRect:self.captureRegion];
            }
            if ([self hasDelegate:@selector(capturedFrame:)]) {
                image = [ImageProcessing rotateImage:image withOrientation:UIImageOrientationRight];
                dispatch_async(dispatch_get_main_queue(), ^{ [self.delegate capturedFrame:image]; });
            }
        }
        return;
    }

    if (self.motion.deviceMotionAvailable) {
        CMAcceleration acc = self.motion.deviceMotion.userAcceleration;
        float moving = acc.x * acc.x + acc.y * acc.y + acc.z * acc.z;
        if (moving > 0.25) {
            [self.kernel resetSimilarity];
            return;
        }
    }

    if ([self.kernel isKernelReady]) {
        if (OSAtomicCompareAndSwapInt(ss_idle, ss_process, (int*)&state) ||
            OSAtomicCompareAndSwapInt(ss_need_more, ss_recognize, (int*)&state)) {
            @autoreleasepool {
                UIImage *image = [ImageProcessing makeImageFromSampleBuffer:sampleBuffer];
                [NSThread detachNewThreadSelector:@selector(recognize:) toTarget:self withObject:image];
            }
        }
    }
}

#pragma mark - KernelDelegate
- (void)notifyKernelError:(KernelError)error
{
    if ([self hasDelegate:@selector(notifyError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self.delegate notifyError:error]; });
    }
}

#pragma mark - RecognitionKernel API
- (void)setUser:(NSString*)name
{
    [self.kernel setUser:name];
}

- (void)setLogLocation:(BOOL)enable
{
    [self.kernel setLogLocation:enable];
}

- (void)setDecodeBarCode:(BOOL)enable
{
    [self.kernel setDecodeBarCode:enable];
}

- (void)setRecognizeSimilar:(BOOL)enable
{
    [self.kernel setRecognizeSimilar:enable];
}

- (void)setRecognizeMode:(KernelMode)mode
{
    [self.kernel setRecognizeMode:mode];
}

- (void)setRecognizePrefer:(KernelPrefer)option
{
    [self.kernel setRecognizePrefer:option];
}

- (KernelError)loadKernelData
{
    return [self.kernel loadKernelData];
}

- (void)unloadKernelData
{
    [self.kernel unloadKernelData];
}

- (BOOL)isKernelReady
{
    return [self.kernel isKernelReady];
}

#pragma ScanViewController API
- (void)setInterest:(CGRect)region withBorder:(UIColor*)color
{
    self.interestRegion = region;
    if (CGRectEqualToRect(region, CGRectZero)) {
        self.focusPoint = CGPointMake(0.5, 0.5);
        [self setDeviceContinuous3A:self.focusPoint];
        self.overlay.hidden = YES;
        self.cropRegion = CGRectZero;
    } else {
        self.focusPoint = CGPointMake((region.size.width / 2.0 + region.origin.x) / self.view.bounds.size.width,
                                      (region.size.height / 2.0 + region.origin.y) / self.view.bounds.size.height);
        [self setDeviceContinuous3A:self.focusPoint];

        UIGraphicsBeginImageContext(self.view.bounds.size);
        CGContextRef ctx = UIGraphicsGetCurrentContext();

        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5].CGColor);
        [[UIBezierPath bezierPathWithRect:self.view.bounds] fill];

        CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        UIBezierPath *rect = [UIBezierPath bezierPathWithRect:region];
        rect.lineWidth = 2.0;
        [rect fillWithBlendMode:kCGBlendModeClear alpha:1.0];
        [rect stroke];

        UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        self.overlay.image = overlayImage;
        self.overlay.hidden = NO;

        // rotate and scale to adapt with video frame size
        self.cropRegion = [self mappingRegionFromViewToVideo:region];
    }
    NSLog(@"[Scan] Interest region %@", NSStringFromCGRect(region));
}

- (void)recognizeContinue
{
    self.pause = NO;
    NSLog(@"[Scan] Recognize continue");
}

- (void)recognizePause
{
    self.pause = YES;
    NSLog(@"[Scan] Recognize paused");
}

- (void)captureNextFrame:(CGRect)region
{
    if (self.pause && [self.session isRunning]) {
        if (CGRectEqualToRect(region, CGRectZero)) {
            self.captureRegion = self.cropRegion;
        } else {
            // rotate and scale to adapt with video frame size
            region = [self mappingRegionFromViewToVideo:region];
            if (CGRectEqualToRect(self.cropRegion, CGRectZero)) {
                self.captureRegion = region;
            } else {
                self.captureRegion = CGRectIntersection(region, self.cropRegion);
            }
        }
        self.capture = YES;
        NSLog(@"[Scan] Capture next frame");
    } else if (!self.pause) {
        NSLog(@"[Scan] Capture only supported when paused");
    } else if (![self.session isRunning]) {
        NSLog(@"[Scan] Capture need running session");
    }
}

- (void)captureNextFrame
{
    [self captureNextFrame:CGRectZero];
}

#pragma ScanViewController private
- (CGRect)mappingRegionFromViewToVideo:(CGRect)viewRegion
{
    CGAffineTransform t1, t2;
    if ([self.session.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        // rotate and scale to adapt with video frame size
        const float scale = 720.0 / self.view.bounds.size.width;
        t1 = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI / 2.0), scale, scale);
        // add offset from the part that video frame out of screen
        const float offset = (1280.0 - self.view.bounds.size.height * scale) / 2.0;
        t2 = CGAffineTransformMakeTranslation(offset, 720.0);
    } else if ([self.session.sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        // rotate and scale to adapt with video frame size
        const float scale = 640.0 / self.view.bounds.size.height;
        t1 = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI / 2.0), scale, scale);
        // add offset from the part that video frame out of screen
        const float offset = 480.0 - (480.0 - self.view.bounds.size.width * scale) / 2.0;
        t2 = CGAffineTransformMakeTranslation(0.0, offset);
    } else {
        // rotate and scale to adapt with video frame size
        const float scale = 352.0 / self.view.bounds.size.height;
        t1 = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI / 2.0), scale, scale);
        // add offset from the part that video frame out of screen
        const float offset = 288.0 - (288.0 - self.view.bounds.size.width * scale) / 2.0;
        t2 = CGAffineTransformMakeTranslation(0.0, offset);
    }
    return CGRectApplyAffineTransform(viewRegion, CGAffineTransformConcat(t1, t2));
}

- (void)setDeviceContinuous3A:(CGPoint)point
{
    if ([self.device lockForConfiguration:nil]) {
        if ([self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        } else if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            self.device.focusMode = AVCaptureFocusModeAutoFocus;
        }
        if ([self.device isFocusPointOfInterestSupported]) {
            self.device.focusPointOfInterest = point;
        }
        if ([self.device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            self.device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        } else if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            self.device.exposureMode = AVCaptureExposureModeAutoExpose;
        }
        if ([self.device isExposurePointOfInterestSupported]) {
            self.device.exposurePointOfInterest = point;
        }
        if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            self.device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        } else if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            self.device.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
        }
        [self.device unlockForConfiguration];
    }
}

- (void)notifyRecognizeBegin
{
    if (OSAtomicCompareAndSwapInt(ss_process, ss_recognize, (int*)&state)) {
        if ([self hasDelegate:@selector(recognizeBegin)]) {
            dispatch_async(dispatch_get_main_queue(), ^{ [self.delegate recognizeBegin]; });
        }
    }
}

- (void)notifyRecognizeEnd
{
    if (OSAtomicCompareAndSwapInt(ss_recognize, ss_process, (int*)&state)) {
        if ([self hasDelegate:@selector(recognizeEnd)]) {
            dispatch_async(dispatch_get_main_queue(), ^{ [self.delegate recognizeEnd]; });
        }
    }
}

- (BOOL)hasDelegate:(SEL)function
{
    return [self.delegate respondsToSelector:function];
}

- (void)recognize:(UIImage*)image
{
    if (!CGRectEqualToRect(self.cropRegion, CGRectZero)) {
        image = [ImageProcessing cropImage:image withRect:self.cropRegion];
    }

    [self notifyRecognizeBegin];

    RecognitionResult *result = [self.kernel recognize:image];

    if (self.pause) {
        [self.kernel resetSimilarity];
        [self notifyRecognizeEnd];
    } else if (result.error != ke_no_error) {
        [self notifyRecognizeEnd];
        [self notifyKernelError:result.error];
        [NSThread sleepForTimeInterval:1.0];
    } else if (result.status == rs_need_more) {
        self.state = ss_need_more;
        return;
    } else {
        [self notifyRecognizeEnd];
        if (result.status == rs_matched && [self hasDelegate:@selector(recognizeMatched:withImage:)]) {
            [self recognizePause];
            image = [ImageProcessing rotateImage:image withOrientation:UIImageOrientationRight];
            dispatch_async(dispatch_get_main_queue(), ^{ [self.delegate recognizeMatched:result.names withImage:image]; });
        } else if (result.status == rs_similar && [self hasDelegate:@selector(recognizeSimilar:withImage:)]) {
            [self recognizePause];
            image = [ImageProcessing rotateImage:image withOrientation:UIImageOrientationRight];
            dispatch_async(dispatch_get_main_queue(), ^{ [self.delegate recognizeSimilar:result.names withImage:image]; });
        } else if (result.status == rs_failed && [self hasDelegate:@selector(recognizeFailed:)]) {
            image = [ImageProcessing rotateImage:image withOrientation:UIImageOrientationRight];
            dispatch_async(dispatch_get_main_queue(), ^{ [self.delegate recognizeFailed:image]; });
            [NSThread sleepForTimeInterval:1.0];
        } else if (result.status == rs_barcode && [self hasDelegate:@selector(barcodeDecoded:withImage:)]) {
            [self recognizePause];
            image = [ImageProcessing rotateImage:image withOrientation:UIImageOrientationRight];
            dispatch_async(dispatch_get_main_queue(), ^{ [self.delegate barcodeDecoded:result.names withImage:image]; });
        }
    }
    self.state = ss_idle;
}
@end
