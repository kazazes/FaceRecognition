//
//  OpenCVData.h
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>

@interface OpenCVData : NSObject

+ (NSData *)serializeCvMat:(cv::Mat&)cvMat;
+ (void)writeCvMat:(cv::Mat&)cvMat toPath:(NSString*)path;
+ (cv::Mat)readImageToCvMat:(NSString*)path;
+ (cv::Mat)dataToMat:(NSData *)data width:(int)width height:(int)height;
+ (CGRect)faceToCGRect:(cv::Rect)face;
+ (UIImage *)UIImageFromMat:(cv::Mat)image;
//+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
//+ (cv::Mat)cvMatFromUIImage:(UIImage *)image usingColorSpace:(int)outputSpace;
+ (cv::Mat)cvImageNormalize:(cv::Mat)image;
+ (cv::Mat)pullStandardizedFace:(cv::Rect)face fromImage:(cv::Mat&)image;
@end
