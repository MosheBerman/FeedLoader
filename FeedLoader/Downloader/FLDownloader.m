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

- (void)downloadDataSegmentWithCompletion:(FLDowloadCompletionBlock)completion
{
    
    /** Ensure we have aURL before we try to load a segment. */
    if (!self.nextPagingURL)
    {
        if ([self.delegate respondsToSelector:@selector(downloader:failedWithError:)]) {
            [self.delegate downloader:self failedWithError:@{@"code":@"", @"message": @""}];
        }
        return;
    }
    
    NSLog(@"Next URL: %@",self.nextPagingURL);
    
    __weak FLDownloader *weakSelf = self;
    
    NSURL *url = [NSURL URLWithString:self.nextPagingURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
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
                if (self.delegate)
                {
                    [self.delegate downloader:self failedWithError:error.userInfo];
                }
                
                weakSelf.nextPagingURL = nil;
            }
            
            /** Else, let's check for nil data */
            else if (!responseDictionary)
            {
                NSDictionary *errorDictionary = @{@"code" : @(-1), @"message" : @"Failed to convert data into a dictionary."};

                if (self.delegate)
                {
                    [self.delegate downloader:self failedWithError:errorDictionary];
                }
                
                weakSelf.nextPagingURL = nil;
            }
            
            /** Else, let's parse the segment. */
            else
            {
                
                NSDictionary *feed = responseDictionary[@"data"];
                
                /** If there's no data, we've got an issue. */
                if (!feed) {
                    NSDictionary *errorDictionary = @{@"code" : @(-2), @"message" : @"There seems to be no data..."};
                
                    if (self.delegate)
                    {
                        [self.delegate downloader:self failedWithError:errorDictionary];
                    }
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
                        
                        _loadedPages++;

                        if ([self.delegate respondsToSelector:@selector(downloaderDidCompleteSegment:)])
                        {
                            [self.delegate downloaderDidCompleteSegment:self];
                        }
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
                    
                    if (self.delegate)
                    {
                        [self.delegate downloader:self failedWithError:errorDictionary];
                    }
                    
                    weakSelf.nextPagingURL = nil;
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
            [self downloadDataSegmentWithCompletion:completion];
            
            if ([self.delegate respondsToSelector:@selector(downloaderDidFinish:)])
            {
                [self.delegate downloaderDidFinish:self];
            }
        }
    }];
}


@end
