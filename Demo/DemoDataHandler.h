//
//  DemoDataHandler.h
//
//  Created by linfish on 13/9/6.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DemoDataHandler : NSObject

- (id)initWithUser:(NSString*)name;

- (UIImage*)getImage:(NSString*)name;
- (void)addImage:(UIImage*)image withName:(NSString*)name;
- (void)clearData;
@end
