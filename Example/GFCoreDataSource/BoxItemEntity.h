//
//  BoxItemEntity.h
//  GFCoreDataSource
//
//  Created by 熊国锋 on 2016/12/19.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface BoxItemEntity : NSManagedObject

@property (nullable, nonatomic, retain) NSString    *box;
@property (nullable, nonatomic, retain) NSString    *item;
@property (nullable, nonatomic, retain) NSDate      *date;

+ (nonnull NSString *)entityName;

@end
