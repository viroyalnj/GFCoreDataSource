//
//  NSManagedObject+GFCoreDataSource.m
//  Pods
//
//  Created by 熊国锋 on 2017/6/28.
//
//

#import "NSManagedObject+GFCoreDataSource.h"

@implementation NSManagedObject (GFCoreDataSource)

+ (NSString *)entityName {
    return [self entity].name;
}

@end
