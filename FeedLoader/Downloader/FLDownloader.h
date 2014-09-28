//
//  FLDownloader.h
//  FeedLoader
//
//  Created by Moshe on 9/28/14.
//  Copyright (c) 2014 Moshe Berman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLDownloaderDelegate.h"

/**
 *  A completion block for when segments load.
 */

typedef void(^FLDownloadCompletionBlock)(BOOL success);

@interface FLDownloader : NSObject

/**
 *  The downloader's delegate.
 */

@property (nonatomic, strong) id<FLDownloaderDelegate> delegate;

/**
 *  The number of pages loaded.
 */

@property (nonatomic, assign) NSInteger loadedPages;

/**
 *  A Facebook API Key.
 */

@property (nonatomic, strong) NSString *token;

/**
 *  The post ID to load from.
 */

@property (nonatomic, strong) NSString *postID;

/**
 *
 */

@property (nonatomic, readonly) NSMutableArray *posts;

#pragma mark - Downloading Data

/** ---
 *  @name Downloading Data
 *  ---
 */

/**
 *  This method downloads data from the feed.
 */

- (void)downloadFeed;

#pragma mark - State

/** ---
 *  @name State
 *  ---
 */

/**
 *  @return YES if the loader is working, else NO.
 */

- (BOOL)working;

@end
