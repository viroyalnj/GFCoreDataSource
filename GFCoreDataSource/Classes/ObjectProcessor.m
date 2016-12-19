//
//  ObjectProcessor.m
//  YuCloud
//
//  Created by 熊国锋 on 15/12/19.
//  Copyright © 2015年 VIROYAL-ELEC. All rights reserved.
//

#import "ObjectProcessor.h"

@interface ObjectProcessor ()

@property (nonatomic, strong) NSManagedObjectContext            *managedObjectContext;


@end

@implementation ObjectProcessor

+ (NSOperationQueue *)sharedOperationQueue
{
    static NSOperationQueue *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[NSOperationQueue alloc] init];
        _sharedClient.name = @"ObjectProcessor";
    });
    
    return _sharedClient;
}

- (void)main
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(editDidSave:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:self.delegate selector:@selector(editDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.managedObjectContext];
    }
    
    NSError *error;
    
    while ([self.startSyncDataInfo count]) {
        NSDictionary *dic = [self.startSyncDataInfo firstObject];
        [self.startSyncDataInfo removeObject:dic];
        
        NSString *entity = [dic valueForKey:@"entity"];
        NSPredicate *predicate = [dic valueForKey:@"predicate"];
        
        NSLog(@"ObjectProcessor start sync for: %@", entity);
        
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
        
        NSLog(@"ObjectProcessor clear objects for entities: %@", entities);
        
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
    
    while ([self.clearUnreadInfo count]) {
        NSDictionary *object = [self.clearUnreadInfo firstObject];
        [self.clearUnreadInfo removeObject:object];
        
        NSArray *entities = [object valueForKey:@"entities"];
        NSPredicate *predicate = [object valueForKey:@"predicate"];
        
        NSLog(@"ObjectProcessor clear unread for entities: %@", entities);
        
        for (NSString *entity in entities) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
            if (predicate) {
                [request setPredicate:predicate];
            }
            
            NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
            for (NSManagedObject *item in objects) {
                [item setValue:@NO forKey:@"unread"];
            }
        }
    }
    
    while ([self.insertDataInfo count]) {
        id object = [self.insertDataInfo firstObject];
        [self.insertDataInfo removeObject:object];
    }
    
    while ([self.editDataInfo count]) {
        NSDictionary *info  = [self.editDataInfo objectAtIndex:0];
        [self.editDataInfo removeObject:info];
        
        NSManagedObjectID *objectID = [info valueForKey:@"objectID"];
        NSManagedObject *item = [self.managedObjectContext objectWithID:objectID];
        
        if (item && ![item isDeleted]) {
            NSArray *allKeys = [info allKeys];
            for (NSString *key in allKeys) {
                if ([key isEqualToString:@"objectID"]) {
                    continue;
                }
                
                if ([key isEqualToString:@"remove"]) {
                    [self.managedObjectContext deleteObject:item];
                }
                else if ([key isEqualToString:@"edit"]) {
                    NSDictionary *edit = [info valueForKey:key];
                    NSArray *keys = [edit allKeys];
                    for (NSString *aa in keys) {
                        id bb = [edit valueForKey:aa];
                        [item setValue:bb forKey:aa];
                    }
                }
                else {
                    NSLog(@"ObjectProcessor error type for: %@", key);
                }
            }
        }
        else {
            NSLog(@"item was deleted: %@", item);
        }
    }
    
    while ([self.finishSyncDataInfo count]) {
        NSDictionary *dic = [self.finishSyncDataInfo firstObject];
        [self.finishSyncDataInfo removeObject:dic];
        
        NSString *entity = [dic valueForKey:@"entity"];
        NSPredicate *predicate = [dic valueForKey:@"predicate"];
        
        NSLog(@"ObjectProcessor end sync for: %@", entity);
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
        if (predicate) {
            [request setPredicate:predicate];
        }
        
        NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
        for (NSManagedObject *item in objects) {
            NSNumber *refCount = [item valueForKey:@"refCount"];
            if ([refCount integerValue] == 0) {
                NSLog(@"ObjectProcessor end sync delete item: %@", item);
                [self.managedObjectContext deleteObject:item];
            }
        }
    }
    
    if ([self.managedObjectContext hasChanges]) {
        NSError *error;
        [self.managedObjectContext save:&error];
        if (error) {
            NSLog(@"ObjectProcessor managedObjectContext save error: %@", [error localizedDescription]);
        }
    }
    
    [self.delegate processDidFinished:self];
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    
    return _managedObjectContext;
}

- (NSMutableArray *)editDataInfo
{
    if (_editDataInfo == nil) {
        _editDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _editDataInfo;
}

- (NSMutableArray *)editMessageDataInfo
{
    if (_editMessageDataInfo == nil) {
        _editMessageDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _editMessageDataInfo;
}

- (NSMutableArray *)insertDataInfo
{
    if (_insertDataInfo == nil) {
        _insertDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _insertDataInfo;
}

- (NSMutableArray *)clearDataInfo
{
    if (_clearDataInfo == nil) {
        _clearDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _clearDataInfo;
}

- (NSMutableArray *)clearUnreadInfo
{
    if (_clearUnreadInfo == nil) {
        _clearUnreadInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _clearUnreadInfo;
}

- (NSMutableArray *)startSyncDataInfo
{
    if (_startSyncDataInfo == nil) {
        _startSyncDataInfo = [NSMutableArray arrayWithCapacity:10];
    }
    
    return _startSyncDataInfo;
}

- (NSMutableArray *)finishSyncDataInfo
{
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.delegate
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:_managedObjectContext];
}

@end


