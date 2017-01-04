//
//  ViewController.m
//  GFCoreDataSource
//
//  Created by guofengld on 12/19/2016.
//  Copyright (c) 2016 guofengld. All rights reserved.
//

#import "ViewController.h"
#import "DataSource.h"

@interface ViewController () < UITableViewDataSource, UITableViewDelegate, GFDataSourceDelegate >

@property (nonatomic, strong)   UITableView     *boxView;
@property (nonatomic, strong)   UITableView     *itemView;

@property (nonatomic, strong)   DataSource      *dataSource;
@property (nonatomic, copy)     NSString        *boxDataKey;
@property (nonatomic, copy)     NSString        *itemDataKey;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Data test";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add box"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(addBox)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add item"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(addItem)];
    
    UIView *superView = self.view;
    
    self.boxView = [[UITableView alloc] init];
    [superView addSubview:self.boxView];
    [self.boxView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(superView);
        make.top.equalTo(superView);
        make.width.equalTo(superView).multipliedBy(0.5);
        make.bottom.equalTo(superView);
    }];
    
    self.itemView = [[UITableView alloc] init];
    [superView addSubview:self.itemView];
    [self.itemView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.boxView.mas_right).offset(2);
        make.top.equalTo(self.boxView);
        make.right.equalTo(superView);
        make.bottom.equalTo(superView);
    }];
    
    self.boxView.tableFooterView = [[UIView alloc] init];
    self.boxView.dataSource = self;
    self.boxView.delegate = self;
    
    self.itemView.tableFooterView = [[UIView alloc] init];
    self.itemView.dataSource = self;
    self.itemView.delegate = self;
    
    self.dataSource = [DataSource sharedClient];
    self.boxDataKey = @"boxData";
    self.itemDataKey = @"itemData";
    
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    [self.dataSource registerDelegate:self
                               entity:[BoxEntity entityName]
                            predicate:nil
                      sortDescriptors:@[dateDescriptor]
                   sectionNameKeyPath:nil
                                  key:self.boxDataKey];
    
    [self.dataSource registerDelegate:self
                               entity:[ItemEntity entityName]
                            predicate:nil
                      sortDescriptors:@[dateDescriptor]
                   sectionNameKeyPath:nil
                                  key:self.itemDataKey];
    
}

- (void)addBox {
    NSUUID *uuid = [NSUUID UUID];
    BoxData *data = [[BoxData alloc] initWithBox:[[uuid UUIDString] substringToIndex:4]];
    
    [self.dataSource addObject:data];
}

- (void)addItem {
    NSIndexPath *indexPath = [self.boxView indexPathForSelectedRow];
    BoxEntity *box = [self.dataSource objectAtIndexPath:indexPath forKey:self.boxDataKey];
    if (box) {
        NSUUID *uuid = [NSUUID UUID];
        ItemData *data = [[ItemData alloc] initWithItem:[[uuid UUIDString] substringToIndex:6] box:box.box];
        
        [self.dataSource addObject:data];
    }
}

- (void)tableView:(UITableView *)tableView
       configcell:(UITableViewCell *)cell
      atIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.boxView) {
        BoxEntity *object = [self.dataSource objectAtIndexPath:indexPath forKey:self.boxDataKey];
        cell.textLabel.text = object.box;
    }
    else {
        ItemEntity *object = [self.dataSource objectAtIndexPath:indexPath forKey:self.itemDataKey];
        cell.textLabel.text = object.item;
    }
}

- (void)tableView:(UITableView *)tableView
         deleteAt:(NSIndexPath *)indexPath {
    if (tableView == self.boxView) {
        BoxEntity *object = [self.dataSource objectAtIndexPath:indexPath forKey:self.boxDataKey];
        [self.dataSource removeObjectWithObjectID:object.objectID];
    }
    else {
        ItemEntity *object = [self.dataSource objectAtIndexPath:indexPath forKey:self.itemDataKey];
        [self.dataSource removeObjectWithObjectID:object.objectID];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIRectEdge)edgesForExtendedLayout {
    return UIRectEdgeNone;
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.boxView) {
        return [self.dataSource numberOfSectionsForKey:self.boxDataKey];
    }
    else {
        return [self.dataSource numberOfSectionsForKey:self.itemDataKey];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.boxView) {
        return [self.dataSource numberOfItemsForKey:self.boxDataKey inSection:section];
    }
    else {
        return [self.dataSource numberOfItemsForKey:self.itemDataKey inSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseableIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:reuseableIdentifier];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self tableView:tableView configcell:cell atIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.boxView) {
        BoxEntity *box = [self.dataSource objectAtIndexPath:indexPath forKey:self.boxDataKey];
        NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        
        [self.dataSource registerDelegate:self
                                   entity:[ItemEntity entityName]
                                predicate:[NSPredicate predicateWithFormat:@"box == %@", box.box]
                          sortDescriptors:@[dateDescriptor]
                       sectionNameKeyPath:nil
                                      key:self.itemDataKey];
        
        [self.itemView reloadData];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                      title:@"Delete"
                                                                    handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                        [self tableView:tableView deleteAt:indexPath];
                                                                    }];
    
    return @[delete];
}

#pragma mark - GFDataSourceDelegate

- (void)dataSource:(id<GFDataSource>)dataSource willChangeContentForKey:(NSString *)key {
    UITableView *tableView = [key isEqualToString:self.boxDataKey]?self.boxView:self.itemView;
    [tableView beginUpdates];
}

- (void)dataSource:(id<GFDataSource>)dataSource didChangeContentForKey:(NSString *)key {
    UITableView *tableView = [key isEqualToString:self.boxDataKey]?self.boxView:self.itemView;
    [tableView endUpdates];
}

- (void)dataSource:(id<GFDataSource>)dataSource
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
            forKey:(NSString *)key {
    UITableView *tableView = [key isEqualToString:self.boxDataKey]?self.boxView:self.itemView;
    
    switch (type) {
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        default:
            break;
    }
}

- (void)dataSource:(id<GFDataSource>)dataSource
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
            forKey:(NSString *)key {
    UITableView *tableView = [key isEqualToString:self.boxDataKey]?self.boxView:self.itemView;
    
    switch (type) {
        case NSFetchedResultsChangeUpdate:
            [self tableView:tableView configcell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}

@end
