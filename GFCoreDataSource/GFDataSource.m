//
//  GFDataSource.m
//  GFCoreDataSource
//
//  Created by guofengld on 16/12/12.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "GFDataSource.h"

@interface GFDataSource () < NSFetchedResultsControllerDelegate >

@property (nonatomic, strong)   NSManagedObjectContext          *managedObjectContext;
@property (nonatomic, strong)   NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (nonatomic, copy)     Class                           objectClass;

@property (nonatomic, strong)   NSMutableDictionary             *operations;

@property (nonatomic, strong)   NSMutableDictionary             *dicFetchedResultsController;
@property (nonatomic, strong)   NSMapTable                      *mapDelegate;

@property (nonatomic, strong)   NSOperationQueue                *operationQueue;

@end

@implementation GFDataSource

+ (instancetype)sharedClient {
    NSAssert(NO, @"implement this method in your sub-class");
    return nil;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedContex
                                 coordinator:(NSPersistentStoreCoordinator *)coordinator
                                       class:(Class)class {
    if (self = [super init]) {
        self.managedObjectContext = managedContex;
        self.persistentStoreCoordinator = coordinator;
        self.objectClass = class;
    }
    
    return self;
}

- (GFObjectOperation *)newOperation {
    NSAssert(self.objectClass, @"must not be null");
    return [[self.objectClass alloc] initWithCoordinator:self.persistentStoreCoordinator];
}

- (NSMutableDictionary *)operations {
    if (_operations == nil) {
        _operations = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    return _operations;
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

- (void)registerDelegate:(id<GFDataSourceDelegate>)delegate
                  entity:(NSString *)entityName
               predicate:(NSPredicate *)predicate
         sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors
      sectionNameKeyPath:(NSString *)sectionNameKeyPath
                     key:(NSString *)key {
    
    NSFetchedResultsController *controller = [self fetchedResultsControllerForKey:key
                                                                           entity:entityName
                                                                  sortDescriptors:sortDescriptors
                                                               sectionNameKeyPath:sectionNameKeyPath];
    if (predicate) {
        [controller.fetchRequest setPredicate:predicate];
    }
    
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

#pragma mark - GFDataSource

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

- (void)setDelegate:(id <GFDataSourceDelegate>)delegate forKey:(NSString *)key {
    [self.mapDelegate setObject:delegate forKey:key];
}

- (NSFetchedResultsController *)fetchedResultsControllerForKey:(NSString *)key {
    return [self.dicFetchedResultsController objectForKey:key];
}

- (id <GFDataSourceDelegate>)delegateForKey:(NSString *)key {
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

- (id <GFDataSourceDelegate>)delegateForController:(NSFetchedResultsController *)controller {
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

- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.name = [NSString stringWithFormat:@"%@ queue", NSStringFromClass([self class])];
    }
    
    return _operationQueue;
}

- (NSOperation *)addOperation:(GFObjectOperation *)processor wait:(BOOL)wait {
    processor.delegate = self;
    
    return [self addOperation:processor
                         wait:wait
                  finishBlock:nil];
}

- (NSOperation *)addOperation:(GFObjectOperation *)processor
                         wait:(BOOL)wait
                  finishBlock:(CommonBlock)block {
    processor.delegate = self;
    
    [self.operationQueue addOperations:@[processor] waitUntilFinished:wait];
    if (block) {
        [self.operations setObject:block forKey:processor.identifier];
    }
    
    return processor;
}

- (void)processDidFinished:(GFObjectOperation *)processor {
    if ([NSThread isMainThread]) {
        CommonBlock block = [self.operations objectForKey:processor.identifier];
        if (block) {
            block(YES, nil);
        }
        [self.operations removeObjectForKey:processor.identifier];
    }
    else {
        [self performSelectorOnMainThread:@selector(processDidFinished:)
                               withObject:processor
                            waitUntilDone:NO];
    }
}

- (void)startSyncEntity:(NSString *)entity predicate:(NSPredicate *)predicate {
    GFObjectOperation *process = [self newOperation];
    if (predicate) {
        [process.startSyncDataInfo addObject:@{@"entity" : entity, @"predicate" : predicate}];
    }
    else {
        [process.startSyncDataInfo addObject:@{@"entity" : entity}];
    }
    
    [self addOperation:process wait:YES];
}

- (void)finishSyncEntity:(NSString *)entity predicate:(NSPredicate *)predicate {
    GFObjectOperation *process = [self newOperation];
    if (predicate) {
        [process.finishSyncDataInfo addObject:@{@"entity" : entity, @"predicate" : predicate}];
    }
    else {
        [process.finishSyncDataInfo addObject:@{@"entity" : entity}];
    }
    
    [self addOperation:process wait:YES];
}

- (NSOperation *)addObject:(id)data {
    GFObjectOperation *process = [self newOperation];
    [process.insertDataInfo addObject:data];
    
    return [self addOperation:process wait:YES];
}

- (NSOperation *)addObject:(id)data block:(CommonBlock)block {
    GFObjectOperation *process = [self newOperation];
    [process.insertDataInfo addObject:data];
    
    return [self addOperation:process wait:YES finishBlock:block];
}

- (void)addObjects:(NSArray *)array {
    GFObjectOperation *process = [self newOperation];
    [process.insertDataInfo addObjectsFromArray:array];
    
    [self addOperation:process wait:YES];
}

- (void)editObject:(id)data {
    [self editObject:data block:nil];
}

- (void)editObject:(id)data block:(CommonBlock)block {
    GFObjectOperation *process = [self newOperation];
    [process.editDataInfo addObject:data];
    
    [self addOperation:process wait:YES finishBlock:block];
}

- (void)clearData:(id)data {
    GFObjectOperation *process = [self newOperation];
    [process.clearDataInfo addObject:data];
    
    [self addOperation:process wait:YES];
}

- (void)deleteObject:(id)data {
    GFObjectOperation *process = [self newOperation];
    [process.deleteDataInfo addObject:data];
    
    [self addOperation:process wait:YES];
}

- (void)deleteObjects:(NSArray *)array {
    GFObjectOperation *process = [self newOperation];
    [process.deleteDataInfo addObjectsFromArray:array];
    
    [self addOperation:process wait:YES];
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
    id <GFDataSourceDelegate> delegate = [self delegateForController:controller];
    
    if ([delegate respondsToSelector:@selector(dataSource:willChangeContentForKey:)]) {
        [delegate dataSource:self willChangeContentForKey:key];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    NSString *key = [self keyForController:controller];
    id <GFDataSourceDelegate> delegate = [self delegateForController:controller];
    
    [delegate dataSource:self didChangeContentForKey:key];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
    NSString *key = [self keyForController:controller];
    id <GFDataSourceDelegate> delegate = [self delegateForController:controller];
    
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
    id <GFDataSourceDelegate> delegate = [self delegateForController:controller];
    
    if ([delegate respondsToSelector:@selector(dataSource:didChangeObject:atIndexPath:forChangeType:newIndexPath:forKey:)]) {
        [delegate dataSource:self
             didChangeObject:anObject
                 atIndexPath:indexPath
               forChangeType:type
                newIndexPath:newIndexPath
                      forKey:key];
    }
}

@end
