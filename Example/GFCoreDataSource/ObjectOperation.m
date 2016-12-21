//
//  ObjectOperation.m
//  GFCoreDataSource
//
//  Created by 熊国锋 on 2016/12/21.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "ObjectOperation.h"
#import "BoxItemData.h"

@implementation ObjectOperation

- (void)onAddObject:(id)object {
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
    }
}

- (void)onDeleteObject:(NSManagedObject *)object {
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
