//
//  VotingFaceRecognizer.m
//  FaceRecognition
//
//  Created by Justin Van Winkle on 9/6/13.
//
//

#import "VotingFaceRecognizer.h"
#import "OpenCVData.h"
#include "glob.h"

#define PERSON_DIR ([self combinePath:[self docPath] with:@"persons"])

@implementation VotingFaceRecognizer

- (id)init
{
    self = [super init];
    if (self) {
        [self makeDirectory:PERSON_DIR];
        self.lastID = -1;
        
        self.faceRecognizers = [[NSMutableArray alloc] init];
        NSLog(@"Creating Recognizers");
        //[self.faceRecognizers addObject: [[CustomFaceRecognizer alloc] initWithMethod:@"Eigen"]];
        [self.faceRecognizers addObject: [[CustomFaceRecognizer alloc] initWithMethod:@"Fisher"]];
        //[self.faceRecognizers addObject: [[CustomFaceRecognizer alloc] initWithMethod:@"LBPH"]];
        NSLog(@"CREATED %@", self.faceRecognizers);
    }
    return self;
}

- (NSString*)docPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

- (NSString*)combinePath:(NSString*)path with:(NSString*)path2 {
    return [path stringByAppendingPathComponent:path2];
}

-(NSArray *)listFileAtPath:(NSString *)path
{
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    return directoryContent;
}

- (NSString*)personImagePath:(int)personID {
    return [PERSON_DIR stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", personID]];
}

- (NSString*)personNameFilePath:(int)personID {
    return [[self personImagePath:personID] stringByAppendingPathComponent:@"name"];
}

- (NSString*)personName:(int)personID {
    return [NSString stringWithContentsOfFile:[self personNameFilePath:personID] encoding:NSUTF8StringEncoding error:nil];
}

- (NSArray*)globListing:(NSString*)pattern {
    NSMutableArray* files = [NSMutableArray array];
    glob_t gt;
    const char* g_pattern = [pattern cStringUsingEncoding:NSUTF8StringEncoding];
    if (glob(g_pattern, 0, NULL, &gt) == 0) {
        int i;
        for (i=0; i<gt.gl_matchc; i++) {
            [files addObject: [NSString stringWithCString:gt.gl_pathv[i] encoding:NSUTF8StringEncoding]];
        }
    }
    globfree(&gt);
    return [NSArray arrayWithArray: files];
}

- (BOOL)pathExists:(NSString*)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (NSArray*)globListing:(NSString*)pattern inPath:(NSString*)path {
    return [self globListing:[path stringByAppendingPathComponent:pattern]];
}

- (BOOL)makeDirectory:(NSString*)path {
    return [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error: NULL];
}

- (BOOL)deleteFile:(NSString*)path {
    return [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
}

- (int)newPersonWithName:(NSString *)name
{
    NSString* person_path;
    int i = 1;
    while (YES) {
        person_path = [self personImagePath:i];
        if (![self pathExists:person_path]) {
            break;
        }
        i++;
    }
    [self makeDirectory:person_path];
    [name writeToFile:[self personNameFilePath:i] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return i;
}

- (NSMutableArray *)getAllPeople {
    NSLog(@"%@", [self globListing:@"*" inPath:PERSON_DIR]);
    NSMutableArray *results = [[NSMutableArray alloc] init];
    for (NSString* person_image_path in [self globListing:@"*" inPath:PERSON_DIR]) {
        int personID = [[person_image_path lastPathComponent] intValue];
        NSString* personName = [self personName:personID];
        [results addObject:@{@"id": @(personID), @"name": personName}];
    }
    
    return results;
}


- (BOOL)trainModel
{
//    if (!self.loaded) {
//        BOOL did_load = NO;
//        
//        for (CustomFaceRecognizer* recognizer in self.faceRecognizers) {
//            did_load = [recognizer loadModel];
//            if (!did_load) {
//                break;
//            }
//        }
//        if (did_load) {
//            self.loaded = YES;
//            return YES;
//        }
//    }
    NSLog(@"Training Models from images");
    
    std::vector<cv::Mat> images;
    std::vector<int> labels;
    
    NSArray* people = [self getAllPeople];
    
    for (NSDictionary* person in people) {
        int personID = INT(person[@"id"]);
        NSArray* personName = person[@"name"];
        NSArray* personImages = [self globListing:@"*.png" inPath:[self personImagePath:personID]];
        NSLog(@"%@ %@", personName, personImages);
        for (NSString* pic_fn in personImages) {
            //NSData* imageData = [NSData dataWithContentsOfFile:pic_fn];
            cv::Mat faceData = [OpenCVData readImageToCvMat:pic_fn];

            images.push_back(faceData);
            labels.push_back(personID);
        }
        
    }
    
    if (images.size() > 0 && labels.size() > 0) {
        dispatch_group_t training_group = dispatch_group_create();
        for (CustomFaceRecognizer* faceRecognizer in self.faceRecognizers) {
            dispatch_group_async(training_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [faceRecognizer trainModel:images withLabels:labels];
                [faceRecognizer saveModel];
            });
            
        }
        dispatch_group_wait(training_group, DISPATCH_TIME_FOREVER);
        self.loaded = YES;
        return YES;
    }
    else {
        return NO;
    }
}

- (void)forgetAllFacesForPersonID:(int)personID
{
    [self deleteFile:[self personImagePath:personID]];
}

- (void)learnFace:(cv::Rect)face ofPersonID:(int)personID fromImage:(cv::Mat&)image
{
    cv::Mat faceData = [self pullStandardizedFace:face fromImage:image];
    cv::Mat normalizedFaceData;
    cv::normalize(faceData, normalizedFaceData, 0, 255, cv::NORM_MINMAX, CV_8UC1);
    //NSData *serialized = [OpenCVData serializeCvMat:normalizedFaceData];
    
    NSString* timestamp = [[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]
                           stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString* fn = [[[self personImagePath:personID] stringByAppendingPathComponent:timestamp] stringByAppendingPathExtension:@"png"];
    NSLog(@"Saving file: %@", fn);
    [OpenCVData writeCvMat:normalizedFaceData toPath:fn];
    //[serialized writeToFile:fn atomically:YES];
}

- (cv::Mat)pullStandardizedFace:(cv::Rect)face fromImage:(cv::Mat&)image
{
    // Pull the grayscale face ROI out of the captured image
    cv::Mat onlyTheFace;
    cv::cvtColor(image(face), onlyTheFace, CV_RGB2GRAY);
    
    // Standardize the face to 100x100 pixels
    cv::resize(onlyTheFace, onlyTheFace, cv::Size(128, 128), 0, 0, cv::INTER_LANCZOS4);
    
    return onlyTheFace;
}

- (MultiResult *)recognizeFace:(cv::Rect)face inImage:(cv::Mat&)image
{
    MultiResult *results = [[MultiResult alloc] init];
    
    dispatch_group_t recognize_group = dispatch_group_create();
    for (CustomFaceRecognizer* faceRecognizer in self.faceRecognizers) {
        dispatch_group_async(recognize_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            RecognitionResult *res = [faceRecognizer recognizeFace:face inImage:image];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [results addResult:res];
            });
        });
        
    }
    
    dispatch_group_wait(recognize_group, DISPATCH_TIME_FOREVER);

    int personID = -1;
    if (results.personID == self.lastID) {
        personID = results.personID;
    } else if (results.personID != self.lastID && self.lastID != -1) {
        personID = self.lastID;
    }
    
    // If a match was found, lookup the person's name
    if (personID != -1) {
        results.personName = [self personName:personID];
    }
    
    self.lastID = results.personID;
    return results;
}



@end
