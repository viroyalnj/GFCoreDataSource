//
//  VIDataSource.m
//  VICoreDataSource
//
//  Created by guofengld on 16/12/12.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "VIDataSource.h"

@interface VIDataSource () < NSFetchedResultsControllerDelegate >

@property (nonatomic, strong)   NSManagedObjectContext          *managedObjectContext;
@property (nonatomic, strong)   NSPersistentStoreCoordinator    *persistentStoreCoordinator;

@property (nonatomic, strong)   NSMutableDictionary             *dicFetchedResultsController;
@property (nonatomic, strong)   NSMapTable                      *mapDelegate;

@property (nonatomic, strong)   dispatch_queue_t                ioQueue;
@property (nonatomic, strong)   NSManagedObjectContext          *queueContext;

@end

@implementation VIDataSource

+ (instancetype)sharedClient {
    NSAssert(NO, @"implement this method in your sub-class");
    return nil;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedContex coordinator:(NSPersistentStoreCoordinator *)coordinator {
    if (self = [self init]) {
        self.managedObjectContext = managedContex;
        self.persistentStoreCoordinator = coordinator;
        
        NSString *string = [NSString stringWithFormat:@"com.guofengld.%@.queue", NSStringFromClass([self class])];
        self.ioQueue = dispatch_queue_create(string.UTF8String, DISPATCH_QUEUE_SERIAL);
        dispatch_sync(self.ioQueue, ^{
            self.queueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            self.queueContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(editDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.queueContext];
    }
    
    return self;
}

- (NSMutableDictionary *)dicFetchedResultsController {
    if (_dicFetchedResultsController == nil) {
        _dicFetchedResultsController = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    return _dicFetchedResultsController;
}

- (NSMapTable *)mapDelegate {
    if (!_mapDelegate) {
        _mapDelegate = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                             valueOptions:NSPointerFunctionsWeakMemory];
    }
    
    return _mapDelegate;
}

- (void)registerDelegate:(id<VIDataSourceDelegate>)delegate
                  entity:(NSString *)entityName
               predicate:(NSPredicate *)predicate
         sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors
      sectionNameKeyPath:(NSString *)sectionNameKeyPath
                     key:(NSString *)key {
    
    NSFetchedResultsController *controller = [self fetchedResultsControllerForKey:key
                                                                           entity:entityName
                                                                  sortDescriptors:sortDescriptors
                                                               sectionNameKeyPath:sectionNameKeyPath];
    [controller.fetchRequest setPredicate:predicate];
    
    if (sortDescriptors) {
        [controller.fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    [self setDelegate:delegate forKey:key];
    [controller performFetch:nil];
}

- (NSFetchedResultsController *)fetchedResultsControllerForKey:(NSString *)key
                                                        entity:(NSString *)entityName
                                               sortDescriptors:(NSArray *)sortDescriptors
                                            sectionNameKeyPath:(NSString *)sectionNameKeyPath {
    NSFetchedResultsController *controller = [self fetchedResultsControllerForKey:key];
    if (!controller) {
        NSAssert(self.managedObjectContext, @"should be initialized on the main thread!");
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        // Create and initialize the fetch results controller.
        controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                         managedObjectContext:self.managedObjectContext
                                                           sectionNameKeyPath:sectionNameKeyPath
                                                                    cacheName:nil];
        controller.delegate = self;
        
        [self setFetchedResultsController:controller forKey:key];
        [controller performFetch:nil];
    }
    
    return controller;
}

#pragma mark - VIDataSource

- (NSInteger)numberOfSectionsForKey:(NSString *)key {
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForKey:key];
    return [[fetchedResultsController sections] count];
}

- (NSInteger)numberOfItemsForKey:(NSString *)key inSection:(NSInteger)section {
    NSArray *sections = [[self fetchedResultsControllerForKey:key] sections];
    if ([sections count] == 0) {
        return 0;
    }
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath forKey:(NSString *)key {
    NSInteger count = [self numberOfItemsForKey:key inSection:indexPath.section];
    if (indexPath.row >= count) {
        return nil;
    }
    
    return [[self fetchedResultsControllerForKey:key] objectAtIndexPath:indexPath];
}

- (id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section
                                                     key:(NSString *)key {
    NSArray *sections = [[self fetchedResultsControllerForKey:key] sections];
    if ([sections count] == 0) {
        return nil;
    }
    
    return [sections objectAtIndex:section];
}

- (NSArray *)allObjectsForKey:(NSString *)key {
    return [[self fetchedResultsControllerForKey:key] fetchedObjects];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forKey:(NSString *)key {
    [self.dicFetchedResultsController setObject:fetchedResultsController forKey:key];
}

- (void)setDelegate:(id <VIDataSourceDelegate>)delegate forKey:(NSString *)key {
    [self.mapDelegate setObject:delegate forKey:key];
}

- (NSFetchedResultsController *)fetchedResultsControllerForKey:(NSString *)key {
    return [self.dicFetchedResultsController objectForKey:key];
}

- (id <VIDataSourceDelegate>)delegateForKey:(NSString *)key {
    return [self.mapDelegate objectForKey:key];
}

- (NSString *)keyForController:(NSFetchedResultsController *)controller {
    for (NSString *key in [self.dicFetchedResultsController keyEnumerator]) {
        if ([self.self.dicFetchedResultsController objectForKey:key] == controller) {
            return key;
        }
    }
    
    return nil;
}

- (id <VIDataSourceDelegate>)delegateForController:(NSFetchedResultsController *)controller {
    NSString *key = [self keyForController:controller];
    id delegate;
    if (key) {
        delegate = [self.mapDelegate objectForKey:key];
        if (!delegate) {
            [self.dicFetchedResultsController removeObjectForKey:key];
            return nil;
        }
    }
    
    return delegate;
}

- (NSEnumerator <NSFetchedResultsController *> *)fetchedResultsControllerEnumerator {
    return [self.dicFetchedResultsController objectEnumerator];
}

- (void)addObject:(id)object
       entityName:(NSString *)entityName {
    [self addObjects:@[object]
          entityName:entityName
             syncAll:NO
       syncPredicate:nil];
}

- (void)addObjects:(NSArray *)array
        entityName:(NSString *)entityName
           syncAll:(BOOL)syncAll
     syncPredicate:(NSPredicate *)predicate {
    NSArray *objects = array.copy;
    dispatch_async(self.ioQueue, ^{
        NSManagedObjectContext *managedObjectContext = self.queueContext;
        
        BOOL syncFlag = NO;
        NSEntityDescription *desc = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
        for (NSPropertyDescription *item in desc.properties) {
            if ([item.name isEqualToString:@"refCount"]) {
                syncFlag = YES;
                break;
            }
        }
        
        // 同步前的标记
        NSArray *oldData = nil;
        if ((syncAll || predicate) && syncFlag) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
            request.predicate = predicate;
            oldData = [managedObjectContext executeFetchRequest:request error:nil];
            for (NSManagedObject *item in oldData) {
                [item setValue:@0 forKey:@"refCount"];
            }
        }
        
        for (id data in objects) {
            NSManagedObject *item = [self onAddObject:data managedObjectContext:managedObjectContext];
            
            // 添加同步标记
            if (syncFlag) {
                [item setValue:@1 forKey:@"refCount"];
            }
        }
        
        // 删除失效数据
        if (syncFlag) {
            for (NSManagedObject *item in oldData) {
                NSNumber *value = [item valueForKey:@"refCount"];
                if (![item isDeleted] && [value integerValue] == 0) {
                    [managedObjectContext deleteObject:item];
                }
            }
        }
        
        // 保存
        if ([managedObjectContext hasChanges]) {
            NSError *err;
            [managedObjectContext save:&err];
            if (err) {
                NSLog(@"error: %@", err);
            }
        }
    });
}

- (void)deleteObject:(id)object {
    [self deleteObjects:@[object]];
}

- (void)deleteObjects:(NSArray *)array {
    dispatch_async(self.ioQueue, ^{
        NSManagedObjectContext *managedObjectContext = self.queueContext;
        
        for (id data in array) {
            [self onDeleteObject:data managedObjectContext:managedObjectContext];
        }
        
        [managedObjectContext save:nil];
    });
}

- (NSManagedObject *)onAddObject:(id)object managedObjectContext:(NSManagedObjectContext *)managedObjectContex {
    NSAssert(NO, @"implement this method in your sub-class");
    
    return nil;
}

- (void)onDeleteObject:(id)object managedObjectContext:(NSManagedObjectContext *)managedObjectContex {
    NSAssert(NO, @"implement this method in your sub-class");
}

- (void)didReceiveMemoryWarning {
    
}

#pragma mark - ObjectProcessDelegate

- (void)editDidSave:(NSNotification *)saveNotification {
    if ([NSThread isMainThread]) {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification];
    }
    else {
        [self performSelectorOnMainThread:@selector(editDidSave:)
                               withObject:saveNotification
                            waitUntilDone:NO];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    NSString *key = [self keyForController:controller];
    id <VIDataSourceDelegate> delegate = [self delegateForController:controller];
    
    if ([delegate respondsToSelector:@selector(dataSource:willChangeContentForKey:)]) {
        [delegate dataSource:self willChangeContentForKey:key];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    NSString *key = [self keyForController:controller];
    id <VIDataSourceDelegate> delegate = [self delegateForController:controller];
    
    [delegate dataSource:self didChangeContentForKey:key];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
    NSString *key = [self keyForController:controller];
    id <VIDataSourceDelegate> delegate = [self delegateForController:controller];
    
    if ([delegate respondsToSelector:@selector(dataSource:didChangeSection:atIndex:forChangeType:forKey:)]) {
        [delegate dataSource:self
            didChangeSection:sectionInfo
                     atIndex:sectionIndex
               forChangeType:type
                      forKey:key];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    NSString *key = [self keyForController:controller];
    id <VIDataSourceDelegate> delegate = [self delegateForController:controller];
    
    if ([delegate respondsToSelector:@selector(dataSource:didChangeObject:atIndexPath:forChangeType:newIndexPath:forKey:)]) {
        [delegate dataSource:self
             didChangeObject:anObject
                 atIndexPath:indexPath
               forChangeType:type
                newIndexPath:newIndexPath
                      forKey:key];
    }
}

- (void)dealloc {
    NSAssert(NO, @"should not be released!");
}

@end
