#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "GFCoreDataSource.h"
#import "GFDataSource.h"
#import "GFObjectOperation.h"
#import "NSManagedObject+GFCoreDataSource.h"

FOUNDATION_EXPORT double GFCoreDataSourceVersionNumber;
FOUNDATION_EXPORT const unsigned char GFCoreDataSourceVersionString[];

