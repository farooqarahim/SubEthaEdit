//  SEESplitView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 10.04.14.

@import Cocoa;

@class SEESplitView;
@protocol SEESplitViewDelegate
@optional
- (NSColor *)dividerColorForSplitView:(SEESplitView *)aSplitView;
@end

@interface SEESplitView : NSSplitView
@end
