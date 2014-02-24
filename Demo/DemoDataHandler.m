//
//  DemoDataHandler.m
//
//  Created by linfish on 13/9/6.
//  Copyright (c) 2013 linfish. All rights reserved.
//

#import "DemoDataHandler.h"

#import "FileManager.h"
#import "ImageProcessing.h"
#import "data_handler.h"

@interface DemoDataHandler ()
@property (nonatomic, retain) NSString *tag;
@property (nonatomic, retain) NSString *directory;
@property (nonatomic, retain) NSMutableArray *imageList;
@end

@implementation DemoDataHandler
@synthesize tag;
@synthesize directory;
@synthesize imageList;

- (id)initWithUser:(NSString*)name
{
    self = [super init];
    if (self) {
        if (name == nil) {
            return nil;
        }

        self.tag = name;

        self.directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        self.directory = [self.directory stringByAppendingPathComponent:@"funwish"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:self.directory]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.directory withIntermediateDirectories:NO attributes:nil error:nil];
        }

        self.imageList = [[NSUserDefaults standardUserDefaults] objectForKey:@"demo_images"];
        if (self.imageList == nil) {
            self.imageList = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

- (UIImage*)getImage:(NSString*)name
{
    for (NSString *imageName in imageList) {
        if ([name isEqualToString:imageName]) {
            NSString *imagePath = [self.directory stringByAppendingPathComponent:[imageName stringByAppendingPathExtension:@"png"]];
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            return image;
        }
    }

    NSString *imagePath = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (image != nil)
        return image;

    imagePath = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
    image = [UIImage imageWithContentsOfFile:imagePath];
    if (image != nil)
        return image;

    imagePath = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    image = [UIImage imageWithContentsOfFile:imagePath];
    if (image != nil)
        return image;

    return nil;
}

- (void)addImage:(UIImage*)image withName:(NSString*)name
{
    CGFloat maxEdge = MAX(image.size.width, image.size.height);

    if (maxEdge > 640.0) {
        image = [ImageProcessing resizeImage:image withScale:640.0 / maxEdge];
    }

    // extract and append data
    const image_description image_desc = [ImageProcessing newGrayImageDescFromUIImage:image withName:name];
    data_handler *dataHandler = new data_handler([self.tag UTF8String], [[self.directory stringByAppendingFormat:@"/"] UTF8String], use_sf_module);
    dataHandler->extract_and_append_to_packed_data(image_desc);
    delete dataHandler;
    [ImageProcessing deleteImageDesc:image_desc];

    // store image files
    NSString *imageName = [name stringByAppendingPathExtension:@"png"];
    NSString *imagePath = [self.directory stringByAppendingPathComponent:imageName];
    [UIImagePNGRepresentation(image) writeToFile:imagePath atomically:YES];

    // add to imageList
    [self.imageList addObject:name];
    [[NSUserDefaults standardUserDefaults] setObject:self.imageList forKey:@"demo_images"];
}

- (void)clearData
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // clear added image files in list
    for (int i = 0; i < [self.imageList count]; i++) {
        NSString *imageName = [[self.imageList objectAtIndex:i] stringByAppendingPathExtension:@"png"];
        NSString *imagePath = [self.directory stringByAppendingPathComponent:imageName];
        if ([fileManager fileExistsAtPath:imagePath]) {
            [fileManager removeItemAtPath:imagePath error:nil];
        }
    }
    [self.imageList removeAllObjects];
    [[NSUserDefaults standardUserDefaults] setObject:self.imageList forKey:@"demo_images"];

    // remove data files
    NSArray *fileExt = [NSArray arrayWithObjects:@"info", @"desc", @"tree", nil];
    [FileManager clearData:self.tag inDir:self.directory withExt:fileExt deleteDir:NO];

    // recover data files
    [FileManager copyData:self.tag fromDir:nil toDir:self.directory withExt:fileExt overwrite:YES];
}

@end
