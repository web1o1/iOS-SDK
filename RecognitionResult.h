//
//  RecognitionResult.h
//
//  Created by linfish on 13/9/12.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KernelDefinition.h"

typedef enum {
    rs_error = -1,     // [offline][online]          something wrong, please check error, error definitions are in KernelDefinition.h
    rs_failed = 0,     // [offline][online]          no matched image in database
    rs_matched,        // [offline][online]          recognized matched image, result with matched image names
    rs_similar,        // [offline][online][similar] recognized similar image, result with similar image names
    rs_need_more,      // [offline]        [similar] need more image input to get similar result
} RecognizeStatus;

@interface RecognitionResult : NSObject
@property (nonatomic, assign) RecognizeStatus status;
@property (nonatomic, assign) KernelError error;
@property (nonatomic, retain) NSArray *names;
@end
