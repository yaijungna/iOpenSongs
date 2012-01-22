//
//  MasterViewController.m
//  OpenSongMasterDetail
//
//  Created by Andreas Böhrnsen on 1/1/12.
//  Copyright (c) 2012 Open iT Norge AS. All rights reserved.
//

#import "SongMasterViewController.h"

@interface SongMasterViewController ()

@property (strong, nonatomic) NSMutableArray *documentURLs;

- (NSString *)applicationDocumentsDirectory;
- (void)reloadFiles;
@end


@implementation SongMasterViewController

@synthesize documentURLs = _documentURLs;
@synthesize detailViewController = _detailViewController;


- (void)awakeFromNib
{
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
    
    self.detailViewController = (SongViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

    self.documentURLs = [NSMutableArray array];
    [self reloadFiles];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.documentURLs = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.documentURLs count] == 0) {
        return 1; //we will display a Demo file
    }
    return self.documentURLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"dyncamicCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }

    // display the DemoFile when there is no file transferred yet
    NSURL *fileUrl = nil;
    if ([self.documentURLs count] == 0) {
        fileUrl = [[NSBundle mainBundle] URLForResource:@"DemoFile" withExtension:@""];
    } else {
        fileUrl = (NSURL *) [self.documentURLs objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = fileUrl.lastPathComponent;
    
    return cell;
}

#pragma mark -
#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // display the DemoFile when there is no file transferred yet
    NSURL *fileUrl = nil;
    if ([self.documentURLs count] == 0) {
        fileUrl = [[NSBundle mainBundle] URLForResource:@"DemoFile" withExtension:@""];  
    } else {
        fileUrl = (NSURL *) [self.documentURLs objectAtIndex:indexPath.row];
    }
    
    [self.detailViewController parseSongFromUrl:fileUrl];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark File system support

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)reloadFiles
{
	[self.documentURLs removeAllObjects];    // clear out the old docs and start over
	
	NSString *documentsDirectoryPath = [self applicationDocumentsDirectory];
	
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];
    
	for (NSString* curFileName in [documentsDirectoryContents objectEnumerator]) {
		NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
		
        // proceed to add the document URL to our list (ignore the "Inbox" folder)
        if (!(isDirectory && [curFileName isEqualToString: @"Inbox"])) {
            [self.documentURLs addObject:fileURL];
        }
	}
	    
	[self.tableView reloadData];
}

- (IBAction)refreshList:(id)sender 
// Called when the user taps the Refresh button.
{
#pragma unused(sender)
    [self reloadFiles];
}

@end
