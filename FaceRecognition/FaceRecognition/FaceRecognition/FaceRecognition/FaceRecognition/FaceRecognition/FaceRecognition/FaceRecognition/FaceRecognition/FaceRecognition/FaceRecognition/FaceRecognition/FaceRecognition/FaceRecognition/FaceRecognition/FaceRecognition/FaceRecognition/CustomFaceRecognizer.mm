//
//  CustomFaceRecognizer.mm
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import "CustomFaceRecognizer.h"
#import "OpenCVData.h"

@implementation CustomFaceRecognizer

- (id)init
{
    self = [super init];
    
    return self;
}

- (id)initWithEigenFaceRecognizer
{
    self = [self init];
    _model = cv::createEigenFaceRecognizer();
    
    return self;
}

- (id)initWithFisherFaceRecognizer
{
    self = [self init];
    _model = cv::createFisherFaceRecognizer();
    
    return self;
}

- (id)initWithLBPHFaceRecognizer
{
    self = [self init];
    _model = cv::createLBPHFaceRecognizer();
    
    return self;
}


- (BOOL)trainModel:(std::vector<cv::Mat>)images withLabels:(std::vector<int>)labels
{
    if (images.size() > 0 && labels.size() > 0) {
        _model->train(images, labels);
        return YES;
    }
    else {
        return NO;
    }
}


- (cv::Mat)pullStandardizedFace:(cv::Rect)face fromImage:(cv::Mat&)image
{
    // Pull the grayscale face ROI out of the captured image
    cv::Mat onlyTheFace;
    cv::cvtColor(image(face), onlyTheFace, CV_RGB2GRAY);
    
    // Standardize the face to 100x100 pixels
    cv::resize(onlyTheFace, onlyTheFace, cv::Size(100, 100), 0, 0);
    
    return onlyTheFace;
}

- (NSDictionary *)recognizeFace:(cv::Rect)face inImage:(cv::Mat&)image
{
    int predictedLabel = -1;
    double confidence = 0.0;
    _model->predict([self pullStandardizedFace:face fromImage:image], predictedLabel, confidence);
    
    return @{
        @"personID": [NSNumber numberWithInt:predictedLabel],
        @"confidence": [NSNumber numberWithDouble:confidence]
    };
}

@end
