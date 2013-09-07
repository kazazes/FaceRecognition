//
//  PeopleViewController.h
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import <UIKit/UIKit.h>
#import "VotingFaceRecognizer.h"

@interface PeopleViewController : UITableViewController

@property (nonatomic, strong) VotingFaceRecognizer *faceRecognizer;
@property (nonatomic, strong) NSArray *people;
@property (nonatomic, strong) NSDictionary *selectedPerson;

@end
