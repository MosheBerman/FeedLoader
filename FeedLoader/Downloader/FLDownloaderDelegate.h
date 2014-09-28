//
//  FLDownloaderDelegate.h
//  FeedLoader
//
//  Created by Moshe on 9/28/14.
//  Copyright (c) 2014 Moshe Berman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FLDownloader;

@protocol FLDownloaderDelegate <NSObject>

/**
 *  Called when the downloader fails.
 *
 *  @param downloader The downloader that failed.
 *  @param error The error message.
 *
 */

- (void)downloader:(FLDownloader *)downloader failedWithError:(NSDictionary *)errorData;

@optional

/**
 *  Called after a segment has loaded. 
 *
 *  @param The downloader that loaded a segment.
 */

- (void)downloaderDidCompleteSegment:(FLDownloader *)downloader;

/**
 *  Called when a downloader finishes.
 *
 *  @param The downloader that finished.
 */

- (void)downloaderDidFinish:(FLDownloader *)downloader;

@end
