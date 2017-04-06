//
//  GFDataSource.h
//  GFCoreDataSource
//
//  Created by guofengld on 16/12/12.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GFObjectOperation.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^CommonBlock)(BOOL success, NSDictionary * _Nullable info);

@class GFDataSource;
@protocol GFDataSource;

@protocol GFDataSourceDelegate <NSObject>

//This method is needed
- (void)dataSource:(id<GFDataSource>)dataSource didChangeContentForKey:(nullable NSString *)key;

@optional

- (void)dataSource:(id<GFDataSource>)dataSource willChangeContentForKey:(nullable NSString *)key;

- (void)dataSource:(id<GFDataSource>)dataSource
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
            forKey:(nullable NSString *)key;

- (void)dataSource:(id<GFDataSource>)dataSource
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
            forKey:(nullable NSString *)key;

@end

@protocol GFDataSource <NSObject>

- (NSInteger)numberOfSectionsForKey:(NSString *)key;
- (NSInteger)numberOfItemsForKey:(NSString *)key inSection:(NSInteger)section;
- (nullable id)objectAtIndexPath:(NSIndexPath *)indexPath forKey:(NSString *)key;
- (nullable id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section key:(NSString *)key;
- (NSArray *)allObjectsForKey:(NSString *)key;

@end

@interface GFDataSource : NSObject < ObjectProcessDelegate, GFDataSource >

@property (nonatomic, weak)     id<GFDataSourceDelegate>        delegate;
@property (nonatomic, readonly) NSManagedObjectContext          *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator    *persistentStoreCoordinator;

+ (instancetype)sharedClient;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedContex
                                 coordinator:(nullable NSPersistentStoreCoordinator *)coordinator
                                       class:(Class)class;

- (void)registerDelegate:(id<GFDataSourceDelegate>)delegate
                  entity:(nonnull NSString *)entityName
               predicate:(nullable NSPredicate *)predicate
         sortDescriptors:(nonnull NSArray<NSSortDescriptor *>*)sortDescriptors
      sectionNameKeyPath:(nullable NSString *)sectionNameKeyPath
                     key:(NSString *)key;

- (NSFetchedResultsController *)fetchedResultsControllerForKey:(NSString *)key;
- (id<GFDataSourceDelegate>)delegateForKey:(NSString *)key;
- (nullable NSString *)keyForController:(NSFetchedResultsController *)controller;
- (id<GFDataSourceDelegate>)delegateForController:(NSFetchedResultsController *)controller;
- (NSEnumerator <NSFetchedResultsController *> *)fetchedResultsControllerEnumerator;

- (void)startSyncEntity:(NSString *)entity predicate:(nullable NSPredicate *)predicate;
- (void)finishSyncEntity:(NSString *)entity predicate:(nullable NSPredicate *)predicate;

- (NSOperation *)addObject:(id)data;
- (NSOperation *)addObject:(id)data block:(nullable CommonBlock)block;
- (void)addObjects:(NSArray *)array;
- (void)editObject:(id)data;
- (void)clearData:(id)data;
- (void)deleteObject:(id)data;
- (void)deleteObjects:(NSArray *)array;

- (void)didReceiveMemoryWarning;

@end

NS_ASSUME_NONNULL_END
