//
//  DataSource.h
//  GFCoreDataSource
//
//  Created by 熊国锋 on 2016/12/19.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "GFDataSource.h"
#import "BoxItemData.h"

NS_ASSUME_NONNULL_BEGIN

@interface DataSource : GFDataSource

- (void)removeItemsWithBox:(NSString *)box;

@end

NS_ASSUME_NONNULL_END
