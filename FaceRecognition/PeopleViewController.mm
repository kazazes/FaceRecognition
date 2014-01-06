//
//  PeopleViewController.mm
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import "PeopleViewController.h"
#import "RecognizeViewController.h"

@interface PeopleViewController ()

@end

@implementation PeopleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.faceRecognizer = [[VotingFaceRecognizer alloc] init];
    NSLog(@"Passing self up");
    //[(RecognizeViewController*)[self parentViewController] pvc:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [(RecognizeViewController*)[self parentViewController] pvc:self];
    self.people = [self.faceRecognizer getAllPeople];
    [self.tableView reloadData];
}

- (void)reloadPeople {
    self.people = [NSMutableArray arrayWithArray:[self.faceRecognizer getAllPeople]];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.people count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    
    static NSString *CellIdentifier = @"PersonCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *person = [self.people objectAtIndex:row];
    cell.textLabel.text = [person objectForKey:@"name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    NSDictionary* selectedPerson = [self.people objectAtIndex:row];
    [(RecognizeViewController*)[self parentViewController]  learnFace:INT(selectedPerson[@"id"])];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    RecognizeViewController *destination = segue.destinationViewController;
    
    if (self.selectedPerson) {
        destination.learningPersonID = INT(self.selectedPerson[@"id"]);
        destination.learningMode = YES;
        destination.personName = self.selectedPerson[@"name"];
    }
}

- (IBAction)setEditMode:(UIBarButtonItem *)sender {
    if (self.editing) {
        sender.title = @"Edit";
        [super setEditing:NO animated:YES];
    } else {
        sender.title = @"Done";
        [super setEditing:YES animated:YES];
    }
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    NSDictionary* selectedPerson = [self.people objectAtIndex:row];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [(RecognizeViewController*)[self parentViewController] removeUser:INT(selectedPerson[@"id"])];
        [self.people removeObjectAtIndex:row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
