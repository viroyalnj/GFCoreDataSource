//
//  VIDataSource.h
//  VICoreDataSource
//
//  Created by guofengld on 16/12/12.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSManagedObject+VICoreDataSource.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^CommonBlock)(BOOL success, NSDictionary * _Nullable info);

@class VIDataSource;
@protocol VIDataSource;

@protocol VIDataSourceDelegate <NSObject>

//This method is needed
- (void)dataSource:(id<VIDataSource>)dataSource didChangeContentForKey:(nullable NSString *)key;

@optional

- (void)dataSource:(id<VIDataSource>)dataSource willChangeContentForKey:(nullable NSString *)key;

- (void)dataSource:(id<VIDataSource>)dataSource
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
            forKey:(nullable NSString *)key;

- (void)dataSource:(id<VIDataSource>)dataSource
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
            forKey:(nullable NSString *)key;

@end

@protocol VIDataSource <NSObject>

- (NSInteger)numberOfSectionsForKey:(NSString *)key;
- (NSInteger)numberOfItemsForKey:(NSString *)key inSection:(NSInteger)section;
- (nullable id)objectAtIndexPath:(NSIndexPath *)indexPath forKey:(NSString *)key;
- (nullable id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section key:(NSString *)key;
- (NSArray *)allObjectsForKey:(NSString *)key;

@end

@interface VIDataSource : NSObject < VIDataSource >

@property (nonatomic, weak)     id<VIDataSourceDelegate>        delegate;
@property (nonatomic, readonly) NSManagedObjectContext          *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator    *persistentStoreCoordinator;

+ (instancetype)sharedClient;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedContex
                                 coordinator:(nullable NSPersistentStoreCoordinator *)coordinator;

- (void)registerDelegate:(id<VIDataSourceDelegate>)delegate
                  entity:(nonnull NSString *)entityName
               predicate:(nullable NSPredicate *)predicate
         sortDescriptors:(nonnull NSArray<NSSortDescriptor *>*)sortDescriptors
      sectionNameKeyPath:(nullable NSString *)sectionNameKeyPath
                     key:(NSString *)key;

- (NSFetchedResultsController *)fetchedResultsControllerForKey:(NSString *)key;
- (id<VIDataSourceDelegate>)delegateForKey:(NSString *)key;
- (nullable NSString *)keyForController:(NSFetchedResultsController *)controller;
- (id<VIDataSourceDelegate>)delegateForController:(NSFetchedResultsController *)controller;
- (NSEnumerator <NSFetchedResultsController *> *)fetchedResultsControllerEnumerator;

- (void)addObject:(id)object
       entityName:(NSString *)entityName;

- (void)addObjects:(NSArray *)array
        entityName:(NSString *)entityName
          syncAll:(BOOL)syncAll
     syncPredicate:(nullable NSPredicate *)predicate;

- (void)deleteObject:(id)object;

- (void)deleteObjects:(NSArray *)array;

- (NSManagedObject *)onAddObject:(id)object managedObjectContext:(NSManagedObjectContext *)managedObjectContex;

- (void)onDeleteObject:(id)object managedObjectContext:(NSManagedObjectContext *)managedObjectContex;

- (void)didReceiveMemoryWarning;

@end

NS_ASSUME_NONNULL_END
