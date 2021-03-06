//
//  DataSource.h
//  GFCoreDataSource
//
//  Created by 熊国锋 on 2016/12/19.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "VIDataSource.h"
#import "Model+CoreDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BoxData : NSObject

@property (nullable, nonatomic, copy) NSString *box;
@property (nullable, nonatomic, copy) NSDate *date;

- (instancetype)initWithBox:(NSString *)box;

@end

@interface ItemData : NSObject

@property (nullable, nonatomic, copy) NSString *box;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, copy) NSString *item;

- (instancetype)initWithItem:(NSString *)item box:(nullable NSString *)box;

@end

@interface NSManagedObject (Entity)

+ (NSString *)entityName;

@end

@interface DataSource : VIDataSource

@end

NS_ASSUME_NONNULL_END
