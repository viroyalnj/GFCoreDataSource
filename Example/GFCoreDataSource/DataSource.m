//
//  DataSource.m
//  GFCoreDataSource
//
//  Created by 熊国锋 on 2016/12/19.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "DataSource.h"
#import "AppDelegate.h"

@implementation BoxData

- (instancetype)initWithBox:(NSString *)box {
    if (self = [super init]) {
        self.box = box;
        self.date = [NSDate date];
    }
    
    return self;
}

@end

@implementation ItemData

- (instancetype)initWithItem:(NSString *)item box:(NSString *)box {
    if (self = [super init]) {
        self.item = item;
        self.date = [NSDate date];
        self.box = box;
    }
    
    return self;
}

@end

@implementation NSManagedObject (Entity)

+ (NSString *)entityName {
    return NSStringFromClass([self class]);
}

@end

@implementation DataSource

+ (instancetype)sharedClient {
    static dispatch_once_t onceToken;
    __block DataSource *client;
    dispatch_once(&onceToken, ^{
        client = [[DataSource alloc] initWithManagedObjectContext:[AppDelegate appDelegate].managedObjectContext
                                                      coordinator:[AppDelegate appDelegate].persistentStoreCoordinator];
    });
    
    return client;
}

- (NSManagedObject *)onAddObject:(id)object managedObjectContext:(NSManagedObjectContext *)managedObjectContex {
    if ([object isKindOfClass:[BoxData class]]) {
        BoxData *data = (BoxData *)object;
        
        NSFetchRequest *request = [BoxEntity fetchRequest];
        request.predicate = [NSPredicate predicateWithFormat:@"box == %@", data.box];
        NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:nil];
        BoxEntity *item = [objects firstObject];
        
        if (!item) {
            item = [NSEntityDescription insertNewObjectForEntityForName:[BoxEntity entityName]
                                                 inManagedObjectContext:self.managedObjectContext];
        }
        
        item.box = data.box;
        item.date = data.date;
        
        return item;
    }
    else if ([object isKindOfClass:[ItemData class]]) {
        ItemData *data = (ItemData *)object;
        
        NSFetchRequest *request = [ItemEntity fetchRequest];
        request.predicate = [NSPredicate predicateWithFormat:@"item == %@", data.item];
        NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:nil];
        ItemEntity *item = [objects firstObject];
        
        if (!item) {
            item = [NSEntityDescription insertNewObjectForEntityForName:[ItemEntity entityName]
                                                 inManagedObjectContext:self.managedObjectContext];
        }
        
        item.item = data.item;
        item.date = data.date;
        item.box = data.box;
        
        return item;
    }
    
    return nil;
}

- (void)onDeleteObject:(id)object managedObjectContext:(NSManagedObjectContext *)managedObjectContex {
    if ([object isKindOfClass:[ItemEntity class]]) {
        [self.managedObjectContext deleteObject:object];
    }
    else if ([object isKindOfClass:[BoxEntity class]]) {
        BoxEntity *box = (BoxEntity *)object;
        
        NSFetchRequest *request = [ItemEntity fetchRequest];
        request.predicate = [NSPredicate predicateWithFormat:@"box == %@", box.box];
        NSArray *arr = [self.managedObjectContext executeFetchRequest:request error:nil];
        for (ItemEntity *item in arr) {
            [self.managedObjectContext deleteObject:item];
        }
        
        [self.managedObjectContext deleteObject:box];
    }
    else {
        NSAssert(NO, @"type error");
    }
}

@end
