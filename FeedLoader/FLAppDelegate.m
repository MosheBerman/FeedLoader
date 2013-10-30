//
//  FLAppDelegate.m
//  FeedLoader
//
//  Created by Moshe Berman on 10/30/13.
//  Copyright (c) 2013 Moshe Berman. All rights reserved.
//

#import "FLAppDelegate.h"

@interface FLAppDelegate () {
    NSInteger loadedPages;
    
    NSDate *startTime;
    NSDate *endTime;
}

@property (strong) NSMutableArray *posts;   //  All of the posts

@property (strong) NSMutableArray *users;   //  All users

@property (strong) NSMutableDictionary *likesByPost;

@property (strong) NSMutableDictionary *commentsByPost;

@property (strong) NSMutableDictionary *sharesByPost;

@property (strong) NSMutableDictionary *postsByID;

@property (strong) NSMutableDictionary *usersByID;

@property (strong) NSString *nextPagingURL;

@property (weak) IBOutlet NSTextField *outputLabel;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSButton *analyzeButton;

@end

typedef void(^FLDowloadCompletionBlock)(BOOL success);

@implementation FLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    self.nextPagingURL = @"https://graph.facebook.com/me/feed?since=1340323200&access_token=CAACuTTrtcLgBAGfHgqNCUb8qXqac1yhazwk1EZBADwZBdQZB7PIT1CGgiOmWmL86PxTWiSVY8yCQhAtZBYFel427s8SZBJZBimthz4aZCVlZCsRdtLiGPJQKwLNYYG2A4hzBJsWZCZBKS95csOa5H2csVavDB1eOiL5vjUTfPAnQSPjS67m6OtBCgUjCDcVQBmq64ZD";
    
    self.posts = [[NSMutableArray alloc] init];
    
    self.users = [[NSMutableArray alloc] init];
    
    self.commentsByPost = [[NSMutableDictionary alloc] init];
    
    self.sharesByPost = [[NSMutableDictionary alloc] init];
    
    self.postsByID = [[NSMutableDictionary alloc] init];
    
    self.usersByID = [[NSMutableDictionary alloc] init];
    
    loadedPages = 0;
    
    
    
}

- (void)downloadDataSegmentWithCompletion:(FLDowloadCompletionBlock)completion
{
    
    /** Ensure we have aURL before we try to load a segment. */
    if (!self.nextPagingURL) {
        return;
    }
    
    __weak FLAppDelegate *weakSelf = self;
    
    NSURL *url = [NSURL URLWithString:self.nextPagingURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        /** If there's an error loading the data, fail. */
        if (error) {
            [self showErrorAlertWithError:error];
        }
        
        /** Else, let's attempt to convert the data to a dictionary. */
        else {
            
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            
            /** If there was an error loading the data, show the error. */
            if (error)
            {
                [self showErrorAlertWithError:error];
                weakSelf.nextPagingURL = nil;
            }
            
            /** Else, let's check for nil data */
            else if (!responseDictionary)
            {
                NSDictionary *errorDictionary = @{@"code" : @(-1), @"message" : @"Failed to convert data into a dictionary."};
                [self showErrorAlertWithDictionary:errorDictionary];
                weakSelf.nextPagingURL = nil;
            }
            
            /** Else, let's parse the segment. */
            else
            {
                
                NSDictionary *feed = responseDictionary[@"data"];
                
                /** If there's no data, we've got an issue. */
                if (!feed) {
                    NSDictionary *errorDictionary = @{@"code" : @(-2), @"message" : @"There seems to be no data..."};
                    [self showErrorAlertWithDictionary:errorDictionary];
                    weakSelf.nextPagingURL = nil;
                }
                
                /** Otherwise, let's pull out the data, then check for the next page. */
                else
                {
                    
                    /** If the paged part of the stream is empty, finish. */
                    if (![feed count]) {
                        self.nextPagingURL = nil;
                    }
                    
                    
                    /** Else, process each post in the stream. */
                    
                    else {
                        /** Iterate each post. Nothing fancy yet. */
                        for (NSDictionary *post in feed) {
                            [weakSelf.posts addObject:post];
                        }
                        
                        loadedPages++;
                        [self updateUI];
                    }
                }
                
                /** Now check for paging information. */
                NSDictionary *paging = responseDictionary[@"paging"];
                
                /** If there's no paging, fail silently. */
                if (!paging) {
                    NSLog(@"There's no paging.");
                    weakSelf.nextPagingURL = nil;
                }
                
                /** Else, check for a next URL. */
                else if (paging[@"next"])
                {
                    weakSelf.nextPagingURL = paging[@"next"];
                }
                
                /** If it's not there, we've hit the end. */
                else
                {
                    NSDictionary *errorDictionary = @{@"code" : @(0), @"message" : @"Looks like we've hit the end of the stream."};
                    [self showErrorAlertWithDictionary:errorDictionary];
                    weakSelf.nextPagingURL = nil;
                }
            }
            
        }
        
        /** If nextPagingURL is nil by now, we're done. */
        if (!weakSelf.nextPagingURL) {
            
            /** Re-enable the button. */
            [weakSelf.startButton setEnabled:YES];
            
            /** Run the completion block. */
            if (completion) {
                completion(YES);
            }
            
            /** Reset the URL. */
            weakSelf.nextPagingURL = @"https://graph.facebook.com/me/feed?since=1340323200&access_token=CAACuTTrtcLgBAGfHgqNCUb8qXqac1yhazwk1EZBADwZBdQZB7PIT1CGgiOmWmL86PxTWiSVY8yCQhAtZBYFel427s8SZBJZBimthz4aZCVlZCsRdtLiGPJQKwLNYYG2A4hzBJsWZCZBKS95csOa5H2csVavDB1eOiL5vjUTfPAnQSPjS67m6OtBCgUjCDcVQBmq64ZD";
        }
        
        /** Else, continue... */
        else {
            [self downloadDataSegmentWithCompletion:completion];
            [self saveDataToDisk];
            
            [self updateUI];
        }
    }];
}

#pragma mark - Load Initialization

- (IBAction)start:(id)sender {
    
    [sender setEnabled:NO];
    
    startTime = [NSDate date];
    
    [self downloadDataSegmentWithCompletion:^(BOOL success) {
        
        /** Calculate the end time*/
        endTime = [NSDate date];
        
        /** Calculate the interval. (Time taken.) */
        NSTimeInterval interval = [endTime timeIntervalSince1970] - [startTime timeIntervalSince1970];
        
        /** Update the output. */
        self.outputLabel.stringValue = [NSString stringWithFormat: @"Loaded %li segments in total over %f seconds.", (long)loadedPages, interval];
        
        /** Save. */
        [self saveDataToDiskQuietly:NO];
        
    }];
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
    self.outputLabel.stringValue = [NSString stringWithFormat:@"Downloaded %li segments.", (long)loadedPages];
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
    
    
    /** Convert the dictionary to data. */
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.posts options:NSJSONWritingPrettyPrinted error:&error];
    
    
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

#pragma mark - Analyze

/**
 *  Loads data file from disk and does some
 *  analysis of it.
 */

- (IBAction)analyze:(id)sender {
    
    /**
     *  Update the UI.
     */
    
    [[self startButton] setEnabled:NO];
    [[self analyzeButton] setEnabled:NO];
    
    
    /** Load the data. */
    NSData *data = [NSData dataWithContentsOfFile:[self pathToJSONFile]];
    
    /** Check for data. If it exists, unpack it. */
    if (data) {
        
        /** An NSError to handle load failures. */
        NSError *error = nil;
        
        /** Convert to a dictionary. */
        NSDictionary *feed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        
        /** If there's an error, alert. */
        if (error) {
            [self showErrorAlertWithError:error];
        }
        
        /** Else, analyze.*/
        else if([feed isKindOfClass:[NSArray class]])
        {
            
            /**
             *  Here we set up some metrics to count up.
             *
             */
            
            /** Posts by key. */
            NSMutableDictionary *postsByKey = [[NSMutableDictionary alloc] init];
            
            /** Find the status types. */
            NSMutableSet *types = [[NSMutableSet alloc] init];
            
            /** Find the application types. */
            NSMutableSet *applicationTypes = [[NSMutableSet alloc] init];
            
            /** Likers, using names as keys. We'll invert these and sort later. */
            NSMutableDictionary *likersAndCounts = [[NSMutableDictionary alloc] init];
            
            /** Likers by number of likes */
            NSMutableArray *likersByCount = [[NSMutableArray alloc] init];
            
            /** Count the total number of likes. */
            NSInteger likeCount = 0;
            
            /**
             *  Prepare the progress bar.
             */
            
            self.progressBar.maxValue = (double)feed.count;
            double currentObject = 0.0; //  Use this because we don't get an index with fast enumeration.
            
            /**
             *  Grab start time.
             */
            
            startTime = [NSDate date];
            
            /**
             *  Iterate the posts.
             *
             */
            for (NSDictionary *post in feed) {
                
                /** Check for post type. */
                NSString *type = post[@"type"];
                NSDictionary *app = post[@"application"];
                NSDictionary *likes = post[@"likes"];
                NSDictionary *comments = post[@"comments"];
                NSString *postID = post[@"id"];
                
                /** Skip posts with no post ID */
                if (!postID) {
                    continue;
                }
                
                /** Since by now we have a post with an ID, add it to the dictionary. */
                postsByKey[postID] = post;
                
                /** If the type exists, add to the set. */
                if (type) {
                    [types addObject:type];
                }
                else {
                    NSLog(@"Found a post with no type. Weird.");
                }
                
                /** Try to parse out the application. */
                if (app) {
                    NSString *appName = app[@"name"];
                    
                    /** If there's an app name, add to the set.*/
                    if (appName) {
                        [applicationTypes addObject:appName];
                    }
                }
                
                /** Look for likes on a post*/
                if (likes) {
                    
                    /** Ensure there's an array of "likers". */
                    NSArray *likers = likes[@"data"];
                    
                    /** If we've got an array, do some things with the likers. */
                    if ([likers isKindOfClass:[NSArray class]]) {
                        
                        /** Add the tally of likes to the post. */
                        NSInteger likeCountForThisPost = [likers count];
                        likeCount += likeCountForThisPost;
                        
                        /** Count likes per person. */
                        for (NSDictionary *liker in likers) {
                            
                            NSString *name = liker[@"name"];
                            
                            /** If the liker is new, add them to the likersAndCounts dictionary. */
                            if (!likersAndCounts[name]) {
                                
                                /**
                                 *  Add the user by name with a count and an array of posts IDs.
                                 */
                                likersAndCounts[name] = [[NSMutableDictionary alloc] initWithObjects:@[@(0), [[NSMutableArray alloc] init]] forKeys:@[@"count", @"posts"]];
                            }
                            
                            NSMutableDictionary *likeDataForUser = likersAndCounts[name];
                            
                            /** Increment the number of likes. */
                            likeDataForUser[@"count"] = @([likeDataForUser[@"count"] integerValue]+1);
                            
                            /** Add the postID in to the user's like data. */
                            [likeDataForUser[@"posts"] addObject:postID];
                        }
                    }
                }
                
                /** Order likers by count. */
                for (NSString *key in [likersAndCounts allKeys]) {
                    
                    /** Get the likes per key. */
                    NSInteger likesPerKey = [likersAndCounts[key][@"count"] integerValue];
                    
                    /** Insert the first object by default. */
                    if (![likersByCount count]) {
                        [likersByCount addObject:key];
                    }
                    
                    /** Else, add at the correct location.*/
                    else {
                        /** Avoid adding users twice. */
                        if (![likersByCount containsObject:key]) {
                            
                            for (NSInteger i = 0; i < [likersByCount count]; i++) {
                                
                                NSDictionary *liker = likersByCount[i];
                                
                                if (i+1 < [likersByCount count]-1) {
                                    
                                    NSDictionary *nextLiker = likersByCount[i+1];
                                    
                                    NSInteger likeCountForLiker = [likersAndCounts[liker][@"count"] integerValue];
                                    NSInteger likeCountForNextLiker = [likersAndCounts[nextLiker][@"count"] integerValue];
                                    
                                    /** If the new liker has more likes than the one
                                     *  we're comparing, put the new liker in front.
                                     */
                                    if (likesPerKey > likeCountForLiker && likesPerKey < likeCountForNextLiker) {
                                        [likersByCount insertObject:key atIndex:i];
                                        break;
                                    }
                                }
                                
                            }
                        }
                    }
                    
                    /** 
                     *  If we've reached the end and the liker isn't in the post
                     *  then we need to add the user.
                     */
                    
                    if (![likersByCount containsObject:key]) {
                        [likersByCount addObject:key];
                    }
                }
                
                /** Look for likes on the comments. */
                if (comments) {
                    
                    /** Iterate the comments, looking for ones posted by me. */
                    NSArray *commentContentsForPost = comments[@"data"];
                    
                    if ([commentContentsForPost isKindOfClass:[NSArray class]]) {
                        /** Iterate the comments. */
                        for (NSDictionary *comment in commentContentsForPost) {
                            
                            /** Read the commenter metadata. */
                            NSDictionary *commenter = comment[@"from"];
                            NSString *commenterName = commenter[@"name"];
                            
                            /** If we've found one of my own comments, count the likes. :-) */
                            if ([commenterName isEqualToString:@"Moshe Berman"]) {
                                NSNumber *numberOfLikesOnComment = comment[@"like_count"];
                                likeCount += [numberOfLikesOnComment integerValue];
                            }
                            
                            /** We can't get per user likes on a comment with the current data set. */
                            
                        }
                    }
                }
                
                /**
                 *  Update progress bar.
                 */
                
                currentObject += 1.0;
                self.progressBar.doubleValue = currentObject;
                self.outputLabel.stringValue = [NSString stringWithFormat:@"Processed %li of %li posts.", (long)currentObject, (long)feed.count];
            }
            
            /**
             *  Log the results.
             */
            
            NSLog(@"Total likes: %li", likeCount);
            NSLog(@"Application Types: %@", applicationTypes);
            NSLog(@"Post Types: %@", types);
            NSLog(@"Likers (Most to Least): %@", likersByCount);
            NSLog(@"Likers and Like Counts: %@", likersAndCounts);
            
            /** Print likers by count. */
            for (NSInteger i = 0; i < [likersByCount count]; i++) {
                
                NSString *liker = likersByCount[i]; //  Liker name
                NSNumber *likes = likersAndCounts[liker][@"count"];   // Liker count
               
                NSString *summary = [NSString stringWithFormat:@"%@ : %li", liker, (long)[likes integerValue]];
                NSLog(@"%@", summary);
            }
            
            /**
             *  Save some files...
             */
            
            NSDictionary *summary = @{@"feed" : feed,
                                      @"posts_by_key" : postsByKey,
                                      @"like_count": @(likeCount),
                                      @"likers_by_likes" : likersByCount,
                                      @"likers_and_counts" : likersAndCounts};
            
            NSData *summaryData = [NSJSONSerialization dataWithJSONObject:summary options:9 error:nil];
            
            NSString *path = [[self pathToDesktop] stringByAppendingPathComponent:@"likes.json"];
            
            [summaryData writeToFile:path atomically:NO];
            
            /**
             *  Calculate runtime.
             */
            
            endTime = [NSDate date];
            
            NSTimeInterval runtime = [endTime timeIntervalSince1970] - [startTime timeIntervalSince1970];
            
            /**
             *  Update the UI.
             */
            
            [[self startButton] setEnabled:YES];
            [[self analyzeButton] setEnabled:YES];
            
            self.outputLabel.stringValue = [NSString stringWithFormat:@"Took %f seconds.", (double)runtime];
             
        }
    }
}


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
