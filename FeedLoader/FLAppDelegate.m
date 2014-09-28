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

@property (strong) NSMutableArray *posts;   //  All of the posts

@property (strong) NSMutableArray *users;   //  All users

@property (strong) NSMutableDictionary *likesByPost;

@property (strong) NSMutableDictionary *commentsByPost;

@property (strong) NSMutableDictionary *sharesByPost;

@property (strong) NSMutableDictionary *postsByID;

@property (strong) NSMutableDictionary *usersByID;

@property (strong) NSString *initialURL;

@property (strong) NSString *nextPagingURL;

@property (nonatomic, strong) FLDownloader *downloader;


@property (weak) IBOutlet NSTextField *outputLabel;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSButton *analyzeButton;


#define kPostID @"10152800390984124"

#define kTokenID @"CAACEdEose0cBAIV7soPoBLQ4CoSKKXenW60TpYYAOzTy7ZA4nZB05JlzZAwDea9VUdgte9Ux9mvZCpyReTjubheeBYk8zrcVq8uEp3UzyQJ8DA7oB8cbtb9l0bx37Feyb0qBvFQTKeQeVgxzYtSxb8vCEYUDAZBYqgxOp8eSvQZCwCx4Debt9YFY3rM3E3ucjqA7iJZAs854pBoKBbjkOwU62lfcqJQe80ZD"

@end

@implementation FLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    //    self.nextPagingURL = @"https://graph.facebook.com/me/feed?since=1340323200&access_token=CAACuTTrtcLgBAGfHgqNCUb8qXqac1yhazwk1EZBADwZBdQZB7PIT1CGgiOmWmL86PxTWiSVY8yCQhAtZBYFel427s8SZBJZBimthz4aZCVlZCsRdtLiGPJQKwLNYYG2A4hzBJsWZCZBKS95csOa5H2csVavDB1eOiL5vjUTfPAnQSPjS67m6OtBCgUjCDcVQBmq64ZD";
    
    self.posts = [[NSMutableArray alloc] init];
    
    self.users = [[NSMutableArray alloc] init];
    
    self.commentsByPost = [[NSMutableDictionary alloc] init];
    
    self.sharesByPost = [[NSMutableDictionary alloc] init];
    
    self.postsByID = [[NSMutableDictionary alloc] init];
    
    self.usersByID = [[NSMutableDictionary alloc] init];
    
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
        NSArray *feed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if ([feed isKindOfClass:[NSDictionary class]]) {
            feed = ((NSDictionary *)feed)[@"data"];
        }
        
        /** If there's an error, alert. */
        if (error) {
            [self showErrorAlertWithError:error];
        }
        
        /** Else, analyze.*/
        else if([feed isKindOfClass:[NSArray class]])
        {
            
//            /** Count the friends by gender. */
//            
            NSMutableArray *males = [NSMutableArray new];
            NSMutableArray *females =  [NSMutableArray new];
            NSMutableArray *undeclared = [NSMutableArray new];
//
//            NSMutableSet *possibleKeys = [NSMutableSet set];
//            
//            for (NSDictionary *friendData in feed) {
//                if ([friendData[@"gender"] isEqualToString:@"male"]) {
//                    [males addObject:friendData[@"name"]];
//                }
//                else if([friendData[@"gender"] isEqualToString:@"female"])
//                {
//                    [females addObject:friendData[@"name"]];
//                }
//                else
//                {
//                    [undeclared addObject:friendData[@"name"]];
//                }
//                
//                for (NSString *key in [friendData allKeys]) {
//                    [possibleKeys addObject:key];
//                }
//            }
            
            /*
             *  Print results
             */
            
//            NSLog(@"Total friends: %li (%.2f%%)", (long)[feed count], (float)[feed count]/(float)[feed count]*100.0);
//            NSLog(@"Male friends: %li (%.2f%%)", (long)[males count], (float)[males count]/(float)[feed count]*100.0);
//            NSLog(@"Female friends: %li (%.2f%%)", (long)[females count], (float)females.count/(float)[feed count]*100.0);
//            NSLog(@"Friends who don't share their gender: %li (%.2f%%)", (long)[undeclared count], (float)undeclared.count/(float)[feed count]*100.0);
//            
//                        NSLog(@"Friend keys: %@", possibleKeys);

            
            for (NSDictionary *user in feed) {
                NSString *userID = user[@"id"];
                
                NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/?fields=gender,name,id&access_token=%@",userID, @"CAACEdEose0cBAHprAdRUywGCyUVbRsbZA6EzHKNW2m877GTLa4xSkZCEW3qZA2icRhOorKjU0hQoRQtQ3ccPJs6WY3y5NlIenMIqggYVQ8OnZBTiH1V9K0NzXZCgQERJnxlCem4qhovuGWyrDr62jf78GGDyd0TklSAy61mfz88O9sMZAgkKWFwgQDaSAzGK27prAwNgJZAdgZDZD"];
                NSURL *url = [NSURL URLWithString:urlString];
                
                [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response  , NSData *data, NSError *error) {
                    
                    if (data) {
                        

                        NSDictionary* responseData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        
                        
                        if ([responseData[@"gender"] isEqualToString:@"male"]) {
                            [males addObject:responseData];
                        }
                        else if([responseData[@"gender"] isEqualToString:@"female"])
                        {
                            [females addObject:responseData];
                        }
                        else
                        {
                            [undeclared addObject:responseData];
                        }
                    }
                    
                    NSInteger mCount = [males count];
                    NSInteger fCount = [females count];
                    NSInteger uCount = [undeclared count];
                    
                    NSInteger total = mCount + fCount + uCount;
                    
                    if (total == [feed count]) {
                        
                        NSLog(@"Males: %.2f,\nFemales: %.2f\nUndeclared:%2f",(double)mCount/(double)feed.count*100, (double)fCount/feed.count*100, (double)uCount/feed.count*100);
                        
                    }
                    
                }];
                
            }
            
//            /** Load up the followers */
//            NSString *pathToFollowers = [[[self pathToJSONFile] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"followers.json"];
//            data = [NSData dataWithContentsOfFile:pathToFollowers];
//            
//            if (data) {
//                NSArray *followers = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
//                
//                if (error) {
//                    NSLog(@"Error loading followers");
//                }
//                
//                else
//                {
//                    NSMutableSet *friendSet = [NSMutableSet setWithArray:feed];
//                    NSMutableSet *followSet = [NSMutableSet setWithArray:followers];
//                    [followSet intersectSet:friendSet];
//                    
//                    NSLog(@"Friends who also follow: %@", followSet );
//                }
//            }
        }
        
//        {
//            
//            /**
//             *  Here we set up some metrics to count up.
//             *
//             */
//            
//            /** Posts by key. */
//            NSMutableDictionary *postsByKey = [[NSMutableDictionary alloc] init];
//            
//            /** Find the status types. */
//            NSMutableSet *types = [[NSMutableSet alloc] init];
//            
//            /** Find the application types. */
//            NSMutableSet *applicationTypes = [[NSMutableSet alloc] init];
//            
//            /** Likers, using names as keys. We'll invert these and sort later. */
//            NSMutableDictionary *likersAndCounts = [[NSMutableDictionary alloc] init];
//            
//            /** Likers by number of likes */
//            NSMutableArray *likersByCount = [[NSMutableArray alloc] init];
//            
//            /** Count the total number of likes. */
//            NSInteger likeCount = 0;
//            
//            /**
//             *  Prepare the progress bar.
//             */
//            
//            self.progressBar.maxValue = (double)feed.count;
//            double currentObject = 0.0; //  Use this because we don't get an index with fast enumeration.
//            
//            /**
//             *  Grab start time.
//             */
//            
//            startTime = [NSDate date];
//            
//            /**
//             *  Iterate the posts.
//             *
//             */
//            for (NSDictionary *post in feed) {
//                
//                /** Check for post type. */
//                NSString *type = post[@"type"];
//                NSDictionary *app = post[@"application"];
//                NSDictionary *likes = post[@"likes"];
//                NSDictionary *comments = post[@"comments"];
//                NSString *postID = post[@"id"];
//                
//                /** Skip posts with no post ID */
//                if (!postID) {
//                    continue;
//                }
//                
//                /** Since by now we have a post with an ID, add it to the dictionary. */
//                postsByKey[postID] = post;
//                
//                /** If the type exists, add to the set. */
//                if (type) {
//                    [types addObject:type];
//                }
//                else {
//                    NSLog(@"Found a post with no type. Weird.");
//                }
//                
//                /** Try to parse out the application. */
//                if (app) {
//                    NSString *appName = app[@"name"];
//                    
//                    /** If there's an app name, add to the set.*/
//                    if (appName) {
//                        [applicationTypes addObject:appName];
//                    }
//                }
//                
//                /** Look for likes on a post*/
//                if (likes) {
//                    
//                    /** Ensure there's an array of "likers". */
//                    NSArray *likers = likes[@"data"];
//                    
//                    /** If we've got an array, do some things with the likers. */
//                    if ([likers isKindOfClass:[NSArray class]]) {
//                        
//                        /** Add the tally of likes to the post. */
//                        NSInteger likeCountForThisPost = [likers count];
//                        likeCount += likeCountForThisPost;
//                        
//                        /** Count likes per person. */
//                        for (NSDictionary *liker in likers) {
//                            
//                            NSString *name = liker[@"name"];
//                            
//                            /** If the liker is new, add them to the likersAndCounts dictionary. */
//                            if (!likersAndCounts[name]) {
//                                
//                                /**
//                                 *  Add the user by name with a count and an array of posts IDs.
//                                 */
//                                likersAndCounts[name] = [[NSMutableDictionary alloc] initWithObjects:@[@(0), [[NSMutableArray alloc] init]] forKeys:@[@"count", @"posts"]];
//                            }
//                            
//                            NSMutableDictionary *likeDataForUser = likersAndCounts[name];
//                            
//                            /** Increment the number of likes. */
//                            likeDataForUser[@"count"] = @([likeDataForUser[@"count"] integerValue]+1);
//                            
//                            /** Add the postID in to the user's like data. */
//                            [likeDataForUser[@"posts"] addObject:postID];
//                        }
//                    }
//                }
//                
//                /** Order likers by count. */
//                for (NSString *key in [likersAndCounts allKeys]) {
//                    
//                    /** Get the likes per key. */
//                    NSInteger likesPerKey = [likersAndCounts[key][@"count"] integerValue];
//                    
//                    /** Insert the first object by default. */
//                    if (![likersByCount count]) {
//                        [likersByCount addObject:key];
//                    }
//                    
//                    /** Else, add at the correct location.*/
//                    else {
//                        /** Avoid adding users twice. */
//                        if (![likersByCount containsObject:key]) {
//                            
//                            for (NSInteger i = 0; i < [likersByCount count]; i++) {
//                                
//                                NSDictionary *liker = likersByCount[i];
//                                
//                                if (i+1 < [likersByCount count]-1) {
//                                    
//                                    NSDictionary *nextLiker = likersByCount[i+1];
//                                    
//                                    NSInteger likeCountForLiker = [likersAndCounts[liker][@"count"] integerValue];
//                                    NSInteger likeCountForNextLiker = [likersAndCounts[nextLiker][@"count"] integerValue];
//                                    
//                                    /** If the new liker has more likes than the one
//                                     *  we're comparing, put the new liker in front.
//                                     */
//                                    if (likesPerKey > likeCountForLiker && likesPerKey < likeCountForNextLiker) {
//                                        [likersByCount insertObject:key atIndex:i];
//                                        break;
//                                    }
//                                }
//                                
//                            }
//                        }
//                    }
//                    
//                    /**
//                     *  If we've reached the end and the liker isn't in the post
//                     *  then we need to add the user.
//                     */
//                    
//                    if (![likersByCount containsObject:key]) {
//                        [likersByCount addObject:key];
//                    }
//                }
//                
//                /** Look for likes on the comments. */
//                if (comments) {
//                    
//                    /** Iterate the comments, looking for ones posted by me. */
//                    NSArray *commentContentsForPost = comments[@"data"];
//                    
//                    if ([commentContentsForPost isKindOfClass:[NSArray class]]) {
//                        /** Iterate the comments. */
//                        for (NSDictionary *comment in commentContentsForPost) {
//                            
//                            /** Read the commenter metadata. */
//                            NSDictionary *commenter = comment[@"from"];
//                            
//                            if(![commenter isEqual:[NSNull null]]){
//                                NSString *commenterName = commenter[@"name"];
//                                
//                                /** If we've found one of my own comments, count the likes. :-) */
//                                if ([commenterName isEqualToString:@"Avi Greenberger"]) {
//                                    NSNumber *numberOfLikesOnComment = comment[@"like_count"];
//                                    likeCount += [numberOfLikesOnComment integerValue];
//                                }
//                                
//                            }
//                            /** We can't get per user likes on a comment with the current data set. */
//                            
//                        }
//                    }
//                }
//                
//                /**
//                 *  Update progress bar.
//                 */
//                
//                currentObject += 1.0;
//                self.progressBar.doubleValue = currentObject;
//                self.outputLabel.stringValue = [NSString stringWithFormat:@"Processed %li of %li posts.", (long)currentObject, (long)feed.count];
//            }
//            
//            /**
//             *  Log the results.
//             */
//            
//            NSLog(@"Total likes: %li", likeCount);
//            NSLog(@"Application Types: %@", applicationTypes);
//            NSLog(@"Post Types: %@", types);
//            NSLog(@"Likers (Most to Least): %@", likersByCount);
//            NSLog(@"Likers and Like Counts: %@", likersAndCounts);
//            
//            /** Print likers by count. */
//            for (NSInteger i = 0; i < [likersByCount count]; i++) {
//                
//                NSString *liker = likersByCount[i]; //  Liker name
//                NSNumber *likes = likersAndCounts[liker][@"count"];   // Liker count
//                
//                NSString *summary = [NSString stringWithFormat:@"%@ : %li", liker, (long)[likes integerValue]];
//                NSLog(@"%@", summary);
//            }
//            
//            /**
//             *  Save some files...
//             */
//            
//            NSDictionary *summary = @{@"feed" : feed,
//                                      @"posts_by_key" : postsByKey,
//                                      @"like_count": @(likeCount),
//                                      @"likers_by_likes" : likersByCount,
//                                      @"likers_and_counts" : likersAndCounts};
//            
//            NSData *summaryData = [NSJSONSerialization dataWithJSONObject:summary options:9 error:nil];
//            
//            NSString *path = [[self pathToDesktop] stringByAppendingPathComponent:@"likes.json"];
//            
//            [summaryData writeToFile:path atomically:NO];
//            
//            /**
//             *  Calculate runtime.
//             */
//            
//            endTime = [NSDate date];
//            
//            NSTimeInterval runtime = [endTime timeIntervalSince1970] - [startTime timeIntervalSince1970];
//
//            
//        }
        
                    /**
                     *  Update the UI.
                     */
        
                    [[self startButton] setEnabled:YES];
                    [[self analyzeButton] setEnabled:YES];
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
