//
//  GFObjectOperation.h
//  GFCoreDataSource
//
//  Created by guofengld on 16/12/12.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol ObjectProcessDelegate <NSObject>

- (void)editDidSave:(NSNotification *)saveNotification;
- (void)processDidFinished:(id)process;

@end

@interface GFObjectOperation : NSOperation

@property (nonatomic, weak)     id <ObjectProcessDelegate>      delegate;
@property (nonatomic, readonly) NSManagedObjectContext          *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator    *persistentStoreCoordinator;

@property (nonatomic, strong) NSMutableArray                    *startSyncDataInfo;
@property (nonatomic, strong) NSMutableArray                    *finishSyncDataInfo;

@property (nonatomic, strong) NSMutableArray                    *insertDataInfo;
@property (nonatomic, strong) NSMutableArray                    *deleteDataInfo;
@property (nonatomic, strong) NSMutableArray                    *editDataInfo;

@property (nonatomic, strong) NSMutableArray                    *clearDataInfo;

@property (nonatomic, copy)   NSString                          *identifier;

- (instancetype)initWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;

- (void)onAddObject:(id)object;
- (void)onDeleteObject:(id)object;
- (void)onEditObject:(NSManagedObject *)object edit:(NSDictionary *)edit;

@end
