//
//  Bridged-Header.h
//  TaskDock
//
//  Created by Andrey Radchishin on 7/19/23.
//

#ifndef Bridged_Header_h
#define Bridged_Header_h

#import <AppKit/AppKit.h>
#import "CGSInternal/CGSSpace.h"
#import "CGSInternal/CGSWindow.h"

/// Additional Private APIs we use that weren't a part of CGSInternal

AXError _AXUIElementGetWindow(AXUIElementRef element, uint32_t *identifier);

/// Get the current active space for a given display
CG_EXTERN CGSSpaceID CGSManagedDisplayGetCurrentSpace(CGSConnectionID cid, CFStringRef display);

/// Move a window to a Space
CG_EXTERN void CGSMoveWindowsToManagedSpace(CGSConnectionID cid, CFArrayRef wids, CGSSpaceID sid);

/// Send notification to CoreDock, used for "Show Desktop"
void CoreDockSendNotification(CFStringRef);

#endif /* Bridged_Header_h */
