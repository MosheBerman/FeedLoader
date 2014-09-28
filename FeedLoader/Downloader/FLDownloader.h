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

typedef void(^FLDowloadCompletionBlock)(BOOL success);

@interface FLDownloader : NSObject

/**
 *  The downloader's delegate.
 */

@property (nonatomic, strong) id<FLDownloaderDelegate> delegate;

/**
 *
 */

@property (nonatomic, assign) NSInteger loadedPages;

/**
 *
 */

- (void)downloadDataSegmentWithCompletion:(FLDowloadCompletionBlock)completion;

@end
