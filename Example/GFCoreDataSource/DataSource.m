//
//  DataSource.m
//  GFCoreDataSource
//
//  Created by 熊国锋 on 2016/12/19.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "DataSource.h"
#import "AppDelegate.h"
#import "ObjectOperation.h"

@implementation DataSource

+ (instancetype)sharedClient {
    static dispatch_once_t onceToken;
    __block DataSource *client;
    dispatch_once(&onceToken, ^{
        client = [[DataSource alloc] initWithManagedObjectContext:[AppDelegate appDelegate].managedObjectContext];
    });
    
    return client;
}

- (ObjectOperation *)newProcessor {
    ObjectOperation *processor = [[ObjectOperation alloc] init];
    
    return processor;
}

- (void)removeItemsWithBox:(NSString *)box {
    NSDictionary *info = @{@"entity" : [ItemEntity entityName],
                           @"action" : @"Delete",
                           @"predicate" : [NSPredicate predicateWithFormat:@"box == %@", box]};
    
    [self editObject:info];
}

@end
