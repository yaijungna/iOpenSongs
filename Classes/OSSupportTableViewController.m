//
//  ExtrasTableViewController.m
//  iOpenSongs
//
//  Created by Andreas Böhrnsen on 2/5/12.
//  Copyright (c) 2012 Andreas Boehrnsen. All rights reserved.
//

#import "OSSupportTableViewController.h"
#import "OSHtmlViewController.h"

#import <UserVoice.h>
#import "OSDefines.h"
#import "OSUserVoiceStyleSheet.h"

#define INDEXPATH_USER_VOICE [NSIndexPath indexPathForRow:0 inSection:0]
#define INDEXPATH_GITHUB     [NSIndexPath indexPathForRow:0 inSection:1]
#define INDEXPATH_TWITTER    [NSIndexPath indexPathForRow:1 inSection:1]
#define INDEXPATH_ABOUT      [NSIndexPath indexPathForRow:0 inSection:2]

@interface OSSupportTableViewController ()
@end

@implementation OSSupportTableViewController

- (NSString*) version
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@ (%@)", version, build];
}

#pragma mark - UIViewController

- (NSString *)title
{
    return @"Support";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contentSizeForViewInPopover = CGSizeMake(320, 320);
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:CellIdentifier];
    }
    
    if ([indexPath isEqual:INDEXPATH_USER_VOICE]) {
        cell.textLabel.text = @"Feedback and Support";
        cell.imageView.image = [UIImage imageNamed:@"glyphicons_244_conversation"];
    } else if ([indexPath isEqual:INDEXPATH_GITHUB]) {
        cell.textLabel.text = @"Fork Me";
        cell.imageView.image = [UIImage imageNamed:@"glyphicons_381_github"];
    } else if ([indexPath isEqual:INDEXPATH_TWITTER]) {
        cell.textLabel.text = @"Follow Us";
        cell.imageView.image = [UIImage imageNamed:@"glyphicons_392_twitter"];
    } else if ([indexPath isEqual:INDEXPATH_ABOUT]) {
        cell.textLabel.text = @"About";
        cell.detailTextLabel.text = self.version;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 2;
        case 2:
            return 1;
    }
    return NSNotFound;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if ([indexPath isEqual:INDEXPATH_USER_VOICE]) {
#if defined IOPENSONGS_USERVOICE_CONFIG
        [UVStyleSheet setStyleSheet:[[OSUserVoiceStyleSheet alloc] init]];
        [UserVoice presentUserVoiceInterfaceForParentViewController:self andConfig:IOPENSONGS_USERVOICE_CONFIG];
#else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://iopensongs.uservoice.com"]];
#endif
    } else if ([indexPath isEqual:INDEXPATH_GITHUB]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.github.com/deepflame/iOpenSongs"]];
        
    } else if ([indexPath isEqual:INDEXPATH_TWITTER]) {
        // thanks to ChrisMaddern for providing this code
        // https://github.com/chrismaddern/Follow-Me-On-Twitter-iOS-Button
        NSArray *urls = [NSArray arrayWithObjects:
                         @"twitter://user?screen_name={handle}", // Twitter
                         @"tweetbot:///user_profile/{handle}", // TweetBot
                         @"echofon:///user_timeline?{handle}", // Echofon              
                         @"twit:///user?screen_name={handle}", // Twittelator Pro
                         @"x-seesmic://twitter_profile?twitter_screen_name={handle}", // Seesmic
                         @"x-birdfeed://user?screen_name={handle}", // Birdfeed
                         @"tweetings:///user?screen_name={handle}", // Tweetings
                         @"simplytweet:?link=http://twitter.com/{handle}", // SimplyTweet
                         @"icebird://user?screen_name={handle}", // IceBird
                         @"fluttr://user/{handle}", // Fluttr
                         @"http://twitter.com/{handle}",
                         nil];
        
        UIApplication *application = [UIApplication sharedApplication];
        
        for (NSString *candidate in urls) {
            NSURL *url = [NSURL URLWithString:[candidate stringByReplacingOccurrencesOfString:@"{handle}" withString:@"iOpenSongs"]];
            if ([application canOpenURL:url]) {
                [application openURL:url];
                break;
            }
        }
    } else if ([indexPath isEqual:INDEXPATH_ABOUT]) {
        OSHtmlViewController *htmlVC = [[OSHtmlViewController alloc] init];
        htmlVC.resourceURL = [[NSBundle mainBundle] URLForResource:@"about" withExtension:@"html"];
        htmlVC.title = @"About";
        
        [self.navigationController pushViewController:htmlVC animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
