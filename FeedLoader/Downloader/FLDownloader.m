//
//  FLDownloader.m
//  FeedLoader
//
//  Created by Moshe on 9/28/14.
//  Copyright (c) 2014 Moshe Berman. All rights reserved.
//

#import "FLDownloader.h"

/**
 *
 */

@interface FLDownloader ()

/**
 *  The inital URL to load data from.
 */

@property (strong) NSString *initialURL;

/**
 *  The next URL to load from.
 */

@property (strong) NSString *nextPagingURL;

/**
 *  The posts.
 */

@property (strong) NSMutableArray *posts;   //  All of the posts

@end

@implementation FLDownloader

/**
 *
 */

/**
 *  Downloads the segments.
 */

- (void)downloadFeedWithCompletion:(FLDowloadCompletionBlock)completion
{
    
    /** Ensure we have aURL before we try to load a segment. */
    if (!self.nextPagingURL)
    {
        self.initialURL = [self _URLFromSettings];
        self.nextPagingURL = [self _URLFromSettings];
    }
    
    NSLog(@"Next URL: %@",self.nextPagingURL);
    
    __weak FLDownloader *weakSelf = self;
    
    NSURL *url = [NSURL URLWithString:self.nextPagingURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    /**
     *  Start the load.
     */
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        /** If there's an error loading the data, fail. */
        if (error)
        {
            if (self.delegate)
            {
                [self.delegate downloader:self failedWithError:error.userInfo];
            }
        }
        
        /** Else, let's attempt to convert the data to a dictionary. */
        else {
            
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            
            /** If there was an error loading the data, show the error. */
            if (error)
            {
                weakSelf.nextPagingURL = nil;
                if (self.delegate)
                {
                    [self.delegate downloader:self failedWithError:error.userInfo];
                }
                

            }
            
            /** Else, let's check for nil data */
            else if (!responseDictionary)
            {
                NSDictionary *errorDictionary = @{@"code" : @(-1), @"message" : @"Failed to convert data into a dictionary."};
                weakSelf.nextPagingURL = nil;
                
                if (self.delegate)
                {
                    [self.delegate downloader:self failedWithError:errorDictionary];
                }
                

            }
            
            /** Else, let's parse the segment. */
            else
            {
                
                NSDictionary *feed = responseDictionary[@"data"];
                
                /** If there's no data, we've got an issue. */
                if (!feed) {
                    NSDictionary *errorDictionary = @{@"code" : @(-2), @"message" : @"There seems to be no data..."};
                    weakSelf.nextPagingURL = nil;
                    
                    if (self.delegate)
                    {
                        [self.delegate downloader:self failedWithError:errorDictionary];
                    }

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
                        
                        _loadedPages++;

                        if ([self.delegate respondsToSelector:@selector(downloaderDidCompleteSegment:)])
                        {
                            [self.delegate downloaderDidCompleteSegment:self];
                        }
                    }
                }
                
                /** Now check for paging information. */
                NSDictionary *paging = responseDictionary[@"paging"];
                
                /** If there's no paging, end the load. */
                if (!paging)
                {
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
                    weakSelf.nextPagingURL = nil;
                    
                    if (self.delegate)
                    {
                        [self.delegate downloader:self failedWithError:errorDictionary];
                    }
                }
            }
            
        }
        
        /** If nextPagingURL is nil by now, we're done. */
        if (!weakSelf.nextPagingURL) {
            
            /** Run the completion block. */
            if (completion) {
                completion(YES);
            }
            
            /** Reset the URL. */
            weakSelf.nextPagingURL = weakSelf.initialURL;
            _loadedPages = 0;
        }
        
        /** Else, continue... */
        else {
            [self downloadFeedWithCompletion:completion];
            
            if ([self.delegate respondsToSelector:@selector(downloaderDidFinish:)])
            {
                [self.delegate downloaderDidFinish:self];
            }
        }
    }];
}

#pragma mark - Create a URL from the Settings

/**
 *  Creates a FB Graph API URL from the downloader's settings.
 *
 *  @return A URL string with a post and API key.
 *
 */

- (NSString *)_URLFromSettings
{
    NSString *address = [NSString stringWithFormat:@"https://graph.facebook.com/v2.1/%@/comments/?limit=25&access_token=%@", self.postID, self.token];
    
    return address;
}

#pragma mark - Setters

/** ---
 *  @name Setters
 *  ---
 */

/**
 *  Sets the postID.
 *
 *  @discussion Will fail silently if the loader is working.
 *
 *  @param postID The new post ID.
 */

- (void)setPostID:(NSString *)postID
{
    if (!self.nextPagingURL)
    {
        
        _postID = postID;
        
        self.initialURL = [self _URLFromSettings];
    }
}

/**
 *  Sets the token.
 *
 *  @discussion Will fail silently if the loader is working.
 *
 *  @param token The new post ID.
 */

- (void)setToken:(NSString *)token
{
    if (!self.nextPagingURL)
    {
        _token = token;
        self.initialURL = [self _URLFromSettings];
    }
}


#pragma mark - State

/** ---
 *  @name State
 *  ---
 */

/**
 *  @return YES if the loader is working, else NO.
 */

- (BOOL)working
{
    return self.nextPagingURL != nil;
}


@end
