//
//  GFObjectOperation.h
//  GFCoreDataSource
//
//  Created by 熊国锋 on 15/12/19.
//  Copyright © 2015年 VIROYAL-ELEC. All rights reserved.
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
@property (nonatomic, strong)   NSPersistentStoreCoordinator    *persistentStoreCoordinator;

@property (nonatomic, strong) NSMutableArray                    *startSyncDataInfo;
@property (nonatomic, strong) NSMutableArray                    *finishSyncDataInfo;

@property (nonatomic, strong) NSMutableArray                    *insertDataInfo;
@property (nonatomic, strong) NSMutableArray                    *editDataInfo;

@property (nonatomic, strong) NSMutableArray                    *clearDataInfo;

@property (nonatomic, copy)   NSString                          *identifier;

- (void)onAddObject:(id)info;
- (void)onEditObject:(NSManagedObject *)object edit:(NSDictionary *)edit;
- (void)onDeleteObject:(NSManagedObject *)object;

@end
