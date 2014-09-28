//
//  FLAppDelegate.m
//  FeedLoader
//
//  Created by Moshe Berman on 10/30/13.
//  Copyright (c) 2013 Moshe Berman. All rights reserved.
//

#import "FLAppDelegate.h"
#import "FLDownloader.h"

@interface FLAppDelegate () <FLDownloaderDelegate> {
    NSDate *startTime;
    NSDate *endTime;
}

@property (nonatomic, strong) FLDownloader *downloader;

@property (weak) IBOutlet NSTextField *outputLabel;
@property (weak) IBOutlet NSButton *startButton;


#define kPostID @"" // A Facebook Post ID

#define kTokenID @""    //  A facebook token, providing access to the post specified above.

@end

@implementation FLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    self.downloader = [[FLDownloader alloc] init];
    self.downloader.delegate = self;
    self.downloader.token = kTokenID;
    self.downloader.postID = kPostID;
    
}

#pragma mark - Load Initialization

- (IBAction)start:(id)sender {
    
    [sender setEnabled:NO];
    
    startTime = [NSDate date];
    
    [self.downloader downloadFeed];
}

#pragma mark - FLDownloaderDelegate

- (void)downloader:(FLDownloader *)downloader failedWithError:(NSDictionary *)errorData
{
    [self showErrorAlertWithDictionary:errorData];
    [self updateUI];
}

- (void)downloaderDidCompleteSegment:(FLDownloader *)downloader
{
    [self updateUI];
}

- (void)downloaderDidFinish:(FLDownloader *)downloader
{
    
    /** Calculate the end time*/
    endTime = [NSDate date];
    
    /** Calculate the interval. (Time taken.) */
    NSTimeInterval interval = [endTime timeIntervalSince1970] - [startTime timeIntervalSince1970];
    
    /** Update the output. */
    self.outputLabel.stringValue = [NSString stringWithFormat: @"Loaded %li segments in total over %f seconds.", (long)self.downloader.loadedPages, interval];
    
    /** Save. */
    [self saveDataToDiskQuietly:NO];
}

#pragma mark - Errors.

/**
 *  Show an error from a dictionary.
 */

- (void)showErrorAlertWithDictionary:(NSDictionary *)dictionary
{
    
    NSInteger code = [dictionary[@"code"] integerValue];
    NSString *message = dictionary[@"message"];
    NSError *error = [NSError errorWithDomain:message code:code userInfo:dictionary];
    
    [self showErrorAlertWithError:error];
}

/**
 *  Show an akert from an error.
 */

- (void)showErrorAlertWithError:(NSError *)error
{
    /** Inform the user that login failed.  */
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
}

#pragma mark - UI

- (void)updateUI
{
    self.outputLabel.stringValue = [NSString stringWithFormat:@"Downloaded %li segments.", (long)self.downloader.loadedPages];
    
    [[self startButton] setEnabled:!self.downloader.working];
}

#pragma mark - Save

-(void)saveDataToDisk
{
    [self saveDataToDiskQuietly:YES];
}

-(void)saveDataToDiskQuietly:(BOOL)quietly
{
    
    /** Create an error container. */
    NSError *error = nil;
    
    NSArray *posts = self.downloader.posts;
    
    
    /** Convert the dictionary to data. */
    NSData *data = [NSJSONSerialization dataWithJSONObject:posts options:NSJSONWritingPrettyPrinted error:&error];
    
    
    /** Get the save path. */
    NSString *savePath = [self pathToJSONFile];
    
    /** Attempt to save. */
    if (![data writeToFile:savePath atomically:YES]) {
        NSLog(@"Failed to save data.");
    }
    /** If the quietly parameter is NO, show an alert. */
    else if(!quietly)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = NSLocalizedString(@"Saved the data as JSON.", @"Saved");
    }
    else
    {
        // Do nothing, save succeeded.
    }
}

//

#pragma mark -

/**
 *  Path to desktop
 */

- (NSString *)pathToDesktop
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES );
    return [paths objectAtIndex:0];
}

/**
 *  Path to the downloaded facebook feed.
 */

- (NSString *)pathToJSONFile
{
    NSString* theDesktopPath = [self pathToDesktop];
    return [theDesktopPath stringByAppendingPathComponent:@"facebook.json"];
}
@end
