//
//  MasterViewController.m
//  iOpenSongs
//
//  Created by Andreas Böhrnsen on 1/1/12.
//  Copyright (c) 2012 Andreas Boehrnsen. All rights reserved.
//

#import "SongMasterViewController.h"
#import "Song+OpenSong.h"

#import "RevealSidebarController.h"

@interface SongMasterViewController () <UISearchBarDelegate>
- (NSString *)applicationDocumentsDirectory;
@end


@implementation SongMasterViewController

@synthesize songDatabase = _songDatabase;
@synthesize delegate = _delegate;


- (NSArray *)openSongInfos
{
    NSMutableArray *infos =[NSMutableArray arrayWithCapacity:0];
    NSMutableArray *errors = [NSMutableArray arrayWithCapacity:0];
    
    NSString *documentsDirectoryPath = [self applicationDocumentsDirectory];
    NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];
    
    for (NSString* curFileName in [documentsDirectoryContents objectEnumerator]) {
        NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        // proceed to add the document URL to our list (ignore the "Inbox" folder)
        if (!(isDirectory || [curFileName isEqualToString:@"Inbox"] || [curFileName isEqualToString:@".DS_Store"])) {
            NSDictionary *info = [Song openSongInfoWithOpenSongFileUrl:fileURL];
            if (info) {
                [infos addObject:info];
            } else {
                [errors addObject:curFileName];
            }
        }
    }
    
    // process errors
    if (errors.count) {
        NSString *fileList = [errors componentsJoinedByString:@"\n"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleError:[NSString stringWithFormat:@"%@\n\nMake sure the files are in the OpenSong format.", fileList] 
                    withTitle:[NSString stringWithFormat:@"Issue importing %d file(s):", errors.count]];
        });
    }
    
    // add a demo file if nothing is present
    if ([infos count] == 0) {
        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"DemoFile" withExtension:@""];
        NSDictionary *info = [Song openSongInfoWithOpenSongFileUrl:fileURL];
        if (info) {
            [infos addObject:info];
        }
    }
    return infos;
}

// 4. Stub this out (we didn't implement it at first)
// 13. Create an NSFetchRequest to get all Photographers and hook it up to our table via an NSFetchedResultsController
// (we inherited the code to integrate with NSFRC from CoreDataTableViewController)

- (void)setupFetchedResultsController // attaches an NSFetchRequest to this UITableViewController
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    // no predicate because we want ALL the Songs
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.songDatabase.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

// 5. Create a Q to fetch Flickr photo information to seed the database
// 6. Take a timeout from this and go create the database model (Photomania.xcdatamodeld)
// 7. Create custom subclasses for Photo and Photographer
// 8. Create a category on Photo (Photo+Flickr) to add a "factory" method to create a Photo
// (go to Photo+Flickr for next step)
// 12. Use the Photo+Flickr category method to add Photos to the database (table will auto update due to NSFRC)

- (void)importSongFilesIntoDocument:(UIManagedDocument *)document
{
    dispatch_queue_t importQ = dispatch_queue_create("Song import", NULL);
    dispatch_async(importQ, ^{
        NSArray *songInfos = [self openSongInfos];
        [document.managedObjectContext performBlock:^{ // perform in the NSMOC's safe thread (main thread)
            for (NSDictionary *info in songInfos) {
                [Song songWithOpenSongInfo:info inManagedObjectContext:document.managedObjectContext];
                // table will automatically update due to NSFetchedResultsController's observing of the NSMOC
            }
            // should probably saveToURL:forSaveOperation:(UIDocumentSaveForOverwriting)completionHandler: here!
            // we could decide to rely on UIManagedDocument's autosaving, but explicit saving would be better
            // because if we quit the app before autosave happens, then it'll come up blank next time we run
            // this is what it would look like (ADDED AFTER LECTURE) ...
            [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:NULL];
            // note that we don't do anything in the completion handler this time
        }];
    });
    dispatch_release(importQ);
}

-(void)deleteAllSongsFromDocument:(UIManagedDocument *)document
{
    NSFetchRequest * allSongs = [[NSFetchRequest alloc] init];
    [allSongs setEntity:[NSEntityDescription entityForName:@"Song" inManagedObjectContext:document.managedObjectContext]];
    [allSongs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *songs = [document.managedObjectContext executeFetchRequest:allSongs error:&error];
    //error handling goes here
    for (NSManagedObject* song in songs) {
        [document.managedObjectContext deleteObject:song];
    }
    NSError *saveError = nil;
    [document.managedObjectContext save:&saveError];
    //more error handling here
}

// 3. Open or create the document here and call setupFetchedResultsController

- (void)useDocument
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.songDatabase.fileURL path]]) {
        // does not exist on disk, so create it
        [self.songDatabase saveToURL:self.songDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [self setupFetchedResultsController];
            [self importSongFilesIntoDocument:self.songDatabase];
        }];
    } else if (self.songDatabase.documentState == UIDocumentStateClosed) {
        // exists on disk, but we need to open it
        [self.songDatabase openWithCompletionHandler:^(BOOL success) {
            [self setupFetchedResultsController];
        }];
    } else if (self.songDatabase.documentState == UIDocumentStateNormal) {
        // already open and ready to use
        [self setupFetchedResultsController];
    }
}

// 2. Make the photoDatabase's setter start using it

- (void)setSongDatabase:(UIManagedDocument *)songDatabase
{
    if (_songDatabase != songDatabase) {
        _songDatabase = songDatabase;
        [self useDocument];
    }
}

// 0. Create full storyboard and drag in CDTVC.[mh], FlickrFetcher.[mh] and ImageViewController.[mh]
// (0.5 would probably be "add a UIManagedDocument, photoDatabase, as this Controller's Model)
// 1. Add code to viewWillAppear: to create a default document (for demo purposes)

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.songDatabase) {  
        // for demo purposes, we'll create a default database if none is set
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"Default Song Database"];
        // configure auto migration
        NSDictionary *storeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        // create managed document
        UIManagedDocument *doc = [[UIManagedDocument alloc] initWithFileURL:url];
        doc.persistentStoreOptions = storeOptions;
        self.songDatabase = doc; // setter will create this for us on disk
    }
}

// -------------

- (SongViewController *)songDetailViewController
{
    id svc = [self.slidingViewController topViewController];
    
    if ([svc isKindOfClass:[UINavigationController class]]) {
        svc = ((UINavigationController *) svc).topViewController;
    }
    
    if (![svc isKindOfClass:[SongViewController class]]) {
        svc = nil;
    }
    return svc;
}

#pragma mark - View lifecycle

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
    // fix scope bar on iPad (with unofficial API... bug in SDK)
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([self.searchDisplayController.searchBar respondsToSelector:@selector(setCombinesLandscapeBars:)]) {
            objc_msgSend(self.searchDisplayController.searchBar, @selector(setCombinesLandscapeBars:), NO );
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Song Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
    }

    Song *song = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = song.title;
    cell.detailTextLabel.text = song.author;
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Song *song = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // setting the song url
    if ([self songDetailViewController]) {
        [self songDetailViewController].song = song;
    } else {
        [self.delegate songMasterViewControllerDelegate:self choseSong:song];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UISearchBarDelegate

-(void)filterSongs:(UISearchBar*)searchBar
{    
    // We use an NSPredicate combined with the fetchedResultsController to perform the search
    if (searchBar.text.length == 0) {
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"1=1"];
        [self.fetchedResultsController.fetchRequest setPredicate:predicate];
    } else {
        NSPredicate *predicate = nil;
        // 0 is title, 1 author, 2 lyrics
        if (searchBar.selectedScopeButtonIndex == 0) {
            predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@", searchBar.text];
        } else if (searchBar.selectedScopeButtonIndex == 1) {
            predicate = [NSPredicate predicateWithFormat:@"author contains[cd] %@", searchBar.text];
        } else {
            predicate = [NSPredicate predicateWithFormat:@"lyrics contains[cd] %@", searchBar.text];
        }
        [self.fetchedResultsController.fetchRequest setPredicate:predicate];
    }
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    
    [self.tableView reloadData];
}

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    [self filterSongs:searchBar];
}

-(void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    searchBar.text = @"";
    [self filterSongs:searchBar];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [self filterSongs:searchBar];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    //TODO dismiss searchbar when first responder is dismissed
}

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (IBAction)refreshList:(id)sender 
// Called when the user taps the Refresh button.
{
#pragma unused(sender)

    [self deleteAllSongsFromDocument:self.songDatabase];
    [self importSongFilesIntoDocument:self.songDatabase];
}

#pragma mark -

- (void)handleError:(NSString *)errorMessage withTitle:(NSString *)errorTitle {
    if (!errorTitle) {
        errorTitle = NSLocalizedString(@"Error Title",
                                        @"Title for alert displayed when download or parse error occurs.");
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorTitle
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
