//
//  LeftSwipeTableView.m
//  LeftSwipeTableView
//
//  Created by Vols on 14-7-19.
//  Copyright (c) 2014年 vols. All rights reserved.
//

#import "LeftSwipeTableView.h"
#import <objc/runtime.h>

#define kSCREEN_SIZE  [[UIScreen mainScreen] bounds].size
#define kDELBUTTON_HEIGHT  80
#define kDELBUTTON_WIDTH   44

const static char * kLeftSwipeDeleteTableViewCellIndexPathKey = "LeftSwipeDeleteTableViewCellIndexPathKey";

@interface UIButton (NSIndexPath)

- (void)setIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPath;

@end

@implementation UIButton (NSIndexPath)

- (void)setIndexPath:(NSIndexPath *)indexPath {
  objc_setAssociatedObject(self, kLeftSwipeDeleteTableViewCellIndexPathKey, indexPath, OBJC_ASSOCIATION_RETAIN);
}

- (NSIndexPath *)indexPath {
  id obj = objc_getAssociatedObject(self, kLeftSwipeDeleteTableViewCellIndexPathKey);
  if([obj isKindOfClass:[NSIndexPath class]]) {
    return (NSIndexPath *)obj;
  }
  return nil;
}

@end

@interface LeftSwipeTableView (){
  UISwipeGestureRecognizer * _leftGestureRecognizer;
  UISwipeGestureRecognizer * _rightGestureRecognizer;
  UITapGestureRecognizer * _tapGestureRecognizer;
  
  UIButton * _deleteButton;
  
  NSIndexPath * _editingIndexPath;
}

@end


@implementation LeftSwipeTableView


- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
  self = [super initWithFrame:frame style:style];
  if (self) {
    _leftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiped:)];
    _leftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    _leftGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_leftGestureRecognizer];
    
    _rightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiped:)];
    _rightGestureRecognizer.delegate = self;
    _rightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:_rightGestureRecognizer];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    _tapGestureRecognizer.delegate = self;
    // Don't add this yet
    
    
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _deleteButton.frame = CGRectMake(kSCREEN_SIZE.width, 0, kDELBUTTON_WIDTH, kDELBUTTON_HEIGHT);
    _deleteButton.backgroundColor = [UIColor redColor];
    _deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_deleteButton setTitle:@"Del" forState:UIControlStateNormal];
    [_deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_deleteButton];
    
  }
  return self;
}


- (id)initWithFrame:(CGRect)frame
{
  return [self initWithFrame:frame style:UITableViewStylePlain];
}


#pragma mark - Actions

- (void)swiped:(UISwipeGestureRecognizer *)gestureRecognizer {

  NSIndexPath * indexPath = [self cellIndexPathForGestureRecognizer:gestureRecognizer];
  if(indexPath == nil)
    return;
  
  if(![self.dataSource tableView:self canEditRowAtIndexPath:indexPath]) {
    return;
  }
  
  if(gestureRecognizer == _leftGestureRecognizer && ![_editingIndexPath isEqual:indexPath]) {
    UITableViewCell * cell = [self cellForRowAtIndexPath:indexPath];
    [self setEditing:YES atIndexPath:indexPath cell:cell];
  } else if (gestureRecognizer == _rightGestureRecognizer && [_editingIndexPath isEqual:indexPath]){
    UITableViewCell * cell = [self cellForRowAtIndexPath:indexPath];
    [self setEditing:NO atIndexPath:indexPath cell:cell];
  }
  
}

- (void)tapped:(UIGestureRecognizer *)gestureRecognizer
{
  if(_editingIndexPath) {
    UITableViewCell * cell = [self cellForRowAtIndexPath:_editingIndexPath];
    [self setEditing:NO atIndexPath:_editingIndexPath cell:cell];
  }
}


- (void)deleteAction:(UIButton *)button{
  
  NSIndexPath * indexPath = button.indexPath;
  [self.dataSource tableView:self commitEditingStyle:UITableViewCellEditingStyleNone forRowAtIndexPath:indexPath];
  
  _editingIndexPath = nil;
  
  [UIView animateWithDuration:0.2f animations:^{
    CGRect frame = _deleteButton.frame;
    _deleteButton.frame = (CGRect){frame.origin, frame.size.width, 0};
  } completion:^(BOOL finished) {
    CGRect frame = _deleteButton.frame;
    _deleteButton.frame = (CGRect){kSCREEN_SIZE.width, frame.origin.y, frame.size.width, kDELBUTTON_HEIGHT};
  }];
}


#pragma mark - helper
- (NSIndexPath *)cellIndexPathForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
  UIView * view = gestureRecognizer.view;
  if(![view isKindOfClass:[UITableView class]]) {
    return nil;
  }
  
  CGPoint point = [gestureRecognizer locationInView:view];
  NSIndexPath * indexPath = [self indexPathForRowAtPoint:point];
  return indexPath;
}


- (void)setEditing:(BOOL)editing atIndexPath:indexPath cell:(UITableViewCell *)cell {
  
  if(editing) {
    
    if(_editingIndexPath) {
      UITableViewCell * editingCell = [self cellForRowAtIndexPath:_editingIndexPath];
      [self setEditing:NO atIndexPath:_editingIndexPath cell:editingCell];
    }
    
    [self addGestureRecognizer:_tapGestureRecognizer];
    
  } else {
    
    [self removeGestureRecognizer:_tapGestureRecognizer];
  }
  
  CGRect frame = cell.frame;
  
  CGFloat cellX;
  CGFloat deleteButtonOldX;
  CGFloat deleteButtonX;
  
  if(editing) {
    cellX = -kDELBUTTON_WIDTH;
    deleteButtonX = kSCREEN_SIZE.width - kDELBUTTON_WIDTH;
    deleteButtonOldX = kSCREEN_SIZE.width;
    _editingIndexPath = indexPath;
  } else {
    cellX = 0;
    deleteButtonX = kSCREEN_SIZE.width;
    deleteButtonOldX = kSCREEN_SIZE.width - kDELBUTTON_WIDTH;
    _editingIndexPath = nil;
  }
  
  CGFloat cellHeight = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
  _deleteButton.frame = (CGRect) {deleteButtonOldX, frame.origin.y, _deleteButton.frame.size.width, cellHeight};
  _deleteButton.indexPath = indexPath;
  
  [UIView animateWithDuration:0.2f animations:^{
    cell.frame = CGRectMake(cellX, frame.origin.y, frame.size.width, frame.size.height);
    _deleteButton.frame = (CGRect) {deleteButtonX, frame.origin.y, _deleteButton.frame.size.width, cellHeight};
  }];
}



#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return NO; // Recognizers of this class are the first priority
}




@end
