//
//  ObjectProcessor.h
//  YuCloud
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

@interface ObjectProcessor : NSOperation

+ (NSOperationQueue *)sharedOperationQueue;

@property (nonatomic, weak)   id <ObjectProcessDelegate>        delegate;
@property (nonatomic, strong) NSPersistentStoreCoordinator      *persistentStoreCoordinator;

@property (nonatomic, strong) NSMutableArray                    *startSyncDataInfo;
@property (nonatomic, strong) NSMutableArray                    *finishSyncDataInfo;
@property (nonatomic, strong) NSMutableArray                    *insertDataInfo;
@property (nonatomic, strong) NSMutableArray                    *editDataInfo;
@property (nonatomic, strong) NSMutableArray                    *editMessageDataInfo;
@property (nonatomic, strong) NSMutableArray                    *clearDataInfo;
@property (nonatomic, strong) NSMutableArray                    *clearUnreadInfo;



@property (nonatomic, copy)   NSString                          *identifier;

@end
