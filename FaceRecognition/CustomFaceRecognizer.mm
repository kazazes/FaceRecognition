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


- (id)initWithEigenFaceRecognizer
{
    self = [super init];
    _model = cv::createEigenFaceRecognizer();
    self.method = @"Eigen";
    return self;
}

- (id)initWithFisherFaceRecognizer
{
    self = [super init];
    _model = cv::createFisherFaceRecognizer();
    self.method = @"Fisher";

    return self;
}

- (id)initWithLBPHFaceRecognizer
{
    self = [super init];
    _model = cv::createLBPHFaceRecognizer();
    self.method = @"LBPH";

    return self;
}

-(NSString*)filePath:(NSString*)fn {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:fn];
}

-(void)saveModel {
    _model->save([[self filePath:self.method] cStringUsingEncoding:NSASCIIStringEncoding]);
}

-(BOOL)loadModel {
    NSString* fn = [self filePath:self.method];
    NSLog(@"LOADING MODEL %@", fn);
    if ([[NSFileManager defaultManager] fileExistsAtPath:fn]) {
        _model->load([fn cStringUsingEncoding:NSASCIIStringEncoding]);
        return YES;
    }
    return NO;
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

- (RecognitionResult *)recognizeFace:(cv::Rect)face inImage:(cv::Mat&)image
{
    int predictedLabel = -1;
    double confidence = 0.0;
    _model->predict([self pullStandardizedFace:face fromImage:image], predictedLabel, confidence);
    
    return [[RecognitionResult alloc] initWithPersonID:predictedLabel confidence:confidence method:self.method];
}

@end
