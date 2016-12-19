//
//  BoxItemEntity.m
//  GFCoreDataSource
//
//  Created by 熊国锋 on 2016/12/19.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "BoxItemEntity.h"

@implementation BoxItemEntity

@dynamic box, item, date;

+ (NSString *)entityName {
    return NSStringFromClass([self class]);
}

@end
