//
//  Plane.h
//  lxzARCube
//
//  Created by 刘鑫忠 on 2017/11/23.
//  Copyright © 2017年 刘鑫忠. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>

@interface Plane : SCNNode

- (instancetype)initWithAnchor:(ARPlaneAnchor *)anchor isHidden:(BOOL)isHidden;
- (void)update:(ARPlaneAnchor *)anchor;
@property (nonatomic,retain) ARPlaneAnchor *anchor;
@property (nonatomic, retain) SCNBox *planeGeometry;

@end
