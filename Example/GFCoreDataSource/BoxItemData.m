//
//  BoxItemData.m
//  GFCoreDataSource
//
//  Created by 熊国锋 on 2016/12/21.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "BoxItemData.h"

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
