//
//  OpenCVData.mm
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import "OpenCVData.h"

@implementation OpenCVData

+ (NSData *)serializeCvMat:(cv::Mat&)cvMat
{
    return [[NSData alloc] initWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
}

+ (cv::Mat)dataToMat:(NSData *)data width:(int)width height:(int)height
{
    cv::Mat output = cv::Mat(width, height, CV_8UC1);
    output.data = (unsigned char*)data.bytes;
    
    return output;
}

+ (void)writeCvMat:(cv::Mat&)cvMat toPath:(NSString*)path {
    cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], cvMat);
}

+ (cv::Mat)readImageToCvMat:(NSString*)path {
    return cv::imread([path cStringUsingEncoding:NSUTF8StringEncoding], CV_LOAD_IMAGE_GRAYSCALE);
}

+ (CGRect)faceToCGRect:(cv::Rect)face
{
    CGRect faceRect;
    faceRect.origin.x = face.x;
    faceRect.origin.y = face.y;
    faceRect.size.width = face.width;
    faceRect.size.height = face.height;
    
    return faceRect;
}

+ (UIImage *)UIImageFromMat:(cv::Mat)image
{
    NSData *data = [NSData dataWithBytes:image.data length:image.elemSize()*image.total()];
    CGColorSpaceRef colorSpace;
    
    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(
                                        image.cols,                                 //width
                                        image.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * image.elemSize(),                       //bits per pixel
                                        image.step.p[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    // Create UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

//+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
//{
//    return [OpenCVData cvMatFromUIImage:image usingColorSpace:CV_RGB2GRAY];
//}

//+ (cv::Mat)cvMatFromUIImage:(UIImage *)image usingColorSpace:(int)outputSpace
//{
//    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
//    CGFloat cols = image.size.width;
//    CGFloat rows = image.size.height;
//    
//    cv::Mat cvMat(rows, cols, CV_8UC4);
//    
//    CGContextRef contextRef = CGBitmapContextCreate(
//                                                    cvMat.data,                 // Pointer to  data
//                                                    cols,                       // Width of bitmap
//                                                    rows,                       // Height of bitmap
//                                                    8,                          // Bits per component
//                                                    cvMat.step[0],              // Bytes per row
//                                                    colorSpace,                 // Colorspace
//                                                    kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault // Bitmap info flags
//                                                    );
//    
//    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
//    CGContextRelease(contextRef);
//    //CGColorSpaceRelease(colorSpace);
//    
//    cv::Mat finalOutput;
//    cvtColor(cvMat, finalOutput, outputSpace);
//    
//    return finalOutput;
//}


+ (cv::Mat)cvImageNormalizeGray:(cv::Mat)image {
    cv::Mat normImage;
    cv::equalizeHist(image, normImage);
    return normImage;
}


+ (cv::Mat)cvImageNormalize:(cv::Mat)image {
    cv::Mat grayImage;
    cv::Mat normImage;
    cvtColor(image, grayImage, CV_RGB2GRAY);
    cv::equalizeHist(grayImage, normImage);
    return normImage;
}

+ (cv::Mat)pullStandardizedFace:(cv::Rect)face fromImage:(cv::Mat&)image
{
    // Pull the grayscale face ROI out of the captured image
    cv::Mat onlyTheFace;
    //cv::cvtColor(image(face), onlyTheFace, CV_RGB2GRAY);
    cv::resize(image(face), onlyTheFace, cv::Size(128, 128), 0, 0, cv::INTER_LANCZOS4);
    
    return [OpenCVData cvImageNormalize:onlyTheFace];
}

@end
