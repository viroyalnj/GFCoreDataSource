//
//  GFObjectOperation.m
//  GFCoreDataSource
//
//  Created by guofengld on 16/12/12.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "GFObjectOperation.h"

@interface GFObjectOperation ()

@property (nonatomic, strong) NSManagedObjectContext            *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator      *persistentStoreCoordinator;

@end

@implementation GFObjectOperation

- (instancetype)initWithCoordinator:(NSPersistentStoreCoordinator *)coordinator {
    if (self = [super init]) {
        self.persistentStoreCoordinator = coordinator;
    }
    
    return self;
}

- (void)main {
    if (self.delegate && [self.delegate respondsToSelector:@selector(editDidSave:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:self.delegate
                                                 selector:@selector(editDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.managedObjectContext];
    }
    
    NSError *error;
    
    while ([self.startSyncDataInfo count]) {
        NSDictionary *dic = [self.startSyncDataInfo firstObject];
        [self.startSyncDataInfo removeObject:dic];
        
        NSString *entity = [dic valueForKey:@"entity"];
        NSPredicate *predicate = [dic valueForKey:@"predicate"];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
        if (predicate) {
            [request setPredicate:predicate];
        }
        
        NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
        for (NSManagedObject *item in objects) {
            [item setValue:@0 forKey:@"refCount"];
        }
    }
    
    while ([self.clearDataInfo count]) {
        NSDictionary *object = [self.clearDataInfo firstObject];
        [self.clearDataInfo removeObject:object];
        
        NSArray *entities = [object valueForKey:@"entities"];
        NSPredicate *predicate = [object valueForKey:@"predicate"];
        
        for (NSString *entity in entities) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
            if (predicate) {
                [request setPredicate:predicate];
            }
            
            NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
            for (NSManagedObject *item in objects) {
                [self.managedObjectContext deleteObject:item];
            }
        }
    }
    
    while ([self.insertDataInfo count]) {
        id object = [self.insertDataInfo firstObject];
        [self.insertDataInfo removeObject:object];
        
        [self onAddObject:object];
    }
    
    while ([self.deleteDataInfo count]) {
        id object = [self.deleteDataInfo firstObject];
        [self.deleteDataInfo removeObject:object];
        
        [self onDeleteObject:object];
    }
    
    while ([self.editDataInfo count]) {
        NSDictionary *info  = [self.editDataInfo firstObject];
        [self.editDataInfo removeObject:info];
        
        NSPredicate *predicate = info[@"predicate"];
        NSManagedObjectID *objectID = info[@"objectID"];
        NSString *entityName = info[@"entity"];
        
        NSArray *objects;
        if (objectID) {
            NSManagedObject *item = [self.managedObjectContext objectWithID:objectID];
            objects = @[item];
        }
        else {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
            request.predicate = predicate;
            objects = [self.managedObjectContext executeFetchRequest:request error:nil];
        }
        
        for (NSManagedObject *item in objects) {
            if (item && ![item isDeleted]) {
                NSDictionary *edit = info[@"Edit"];
                [self onEditObject:item edit:edit];
            }
            else {
                NSLog(@"item was deleted: %@", item);
            }
        }
    }
    
    while ([self.finishSyncDataInfo count]) {
        NSDictionary *dic = [self.finishSyncDataInfo firstObject];
        [self.finishSyncDataInfo removeObject:dic];
        
        NSString *entity = [dic valueForKey:@"entity"];
        NSPredicate *predicate = [dic valueForKey:@"predicate"];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
        if (predicate) {
            [request setPredicate:predicate];
        }
        
        NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
        for (NSManagedObject *item in objects) {
            NSNumber *refCount = [item valueForKey:@"refCount"];
            if ([refCount integerValue] == 0) {
                [self.managedObjectContext deleteObject:item];
            }
        }
    }
    
    if ([self.managedObjectContext hasChanges]) {
        NSError *error;
        [self.managedObjectContext save:&error];
        if (error) {
            NSLog(@"GFObjectOperation managedObjectContext save error: %@", [error localizedDescription]);
        }
    }
    
    [self.delegate processDidFinished:self];
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    
    return _managedObjectContext;
}

- (NSMutableArray *)editDataInfo {
    if (_editDataInfo == nil) {
        _editDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _editDataInfo;
}

- (NSMutableArray *)insertDataInfo {
    if (_insertDataInfo == nil) {
        _insertDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _insertDataInfo;
}

- (NSMutableArray *)deleteDataInfo {
    if (!_deleteDataInfo) {
        _deleteDataInfo = [NSMutableArray array];
    }
    
    return _deleteDataInfo;
}

- (NSMutableArray *)clearDataInfo {
    if (_clearDataInfo == nil) {
        _clearDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _clearDataInfo;
}

- (NSMutableArray *)startSyncDataInfo {
    if (_startSyncDataInfo == nil) {
        _startSyncDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _startSyncDataInfo;
}

- (NSMutableArray *)finishSyncDataInfo {
    if (_finishSyncDataInfo == nil) {
        _finishSyncDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _finishSyncDataInfo;
}

- (NSString *)identifier {
    if (!_identifier) {
        _identifier = [[NSUUID UUID] UUIDString];
    }
    
    return _identifier;
}

- (void)onAddObject:(id)object {
    NSAssert(NO, @"implement this in your sub class");
}

- (void)onDeleteObject:(id)object {
    NSAssert(NO, @"implement this in your sub class");
}

- (void)onEditObject:(NSManagedObject *)object edit:(NSDictionary *)edit {
    for (NSString *aa in [edit allKeys]) {
        id bb = [edit valueForKey:aa];
        [object setValue:bb forKey:aa];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.delegate
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:_managedObjectContext];
}

@end


