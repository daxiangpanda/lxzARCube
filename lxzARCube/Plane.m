//
//  Plane.m
//  lxzARCube
//
//  Created by 刘鑫忠 on 2017/11/23.
//  Copyright © 2017年 刘鑫忠. All rights reserved.
//

#import "Plane.h"

@implementation Plane

-(instancetype)initWithAnchor:(ARPlaneAnchor*)anchor isHidden:(BOOL)isHidden{
    self = [super init];

    self.anchor = anchor;
    
    float planeHeight = 0.01;
    
    self.planeGeometry = [SCNBox boxWithWidth:anchor.extent.x height:planeHeight length:anchor.extent.z chamferRadius:0];
    
    SCNMaterial *material = [SCNMaterial new];
    UIImage *img = [UIImage imageNamed:@"tron_grid"];
    material.diffuse.contents = img;
    
    
    SCNMaterial *transparentMaterial = [SCNMaterial new];
    transparentMaterial.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:0.0];
    
    
    if (isHidden) {
        self.planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial];
    } else {
        self.planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material, transparentMaterial];
    }
    
    SCNNode *planeNode = [SCNNode nodeWithGeometry:self.planeGeometry];
    
    planeNode.position = SCNVector3Make(0, anchor.center.y, 0);
    
    planeNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:self.planeGeometry options:nil]];
    
    
    [self setTextureScale];
    
    [self addChildNode:planeNode];
    
    return self;
}

- (void)setTextureScale {
    CGFloat width = self.planeGeometry.width;
    CGFloat height = self.planeGeometry.height;
    
    // As the width/height of the plane updates, we want our tron grid material to
    // cover the entire plane, repeating the texture over and over. Also if the
    // grid is less than 1 unit, we don't want to squash the texture to fit, so
    // scaling updates the texture co-ordinates to crop the texture in that case
    SCNMaterial *material = self.planeGeometry.materials.firstObject;
    material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1);
    material.diffuse.wrapS = SCNWrapModeRepeat;
    material.diffuse.wrapT = SCNWrapModeRepeat;
}

- (void)update:(ARPlaneAnchor *)anchor {
    // As the user moves around the extend and location of the plane
    // may be updated. We need to update our 3D geometry to match the
    // new parameters of the plane.
    self.planeGeometry.width = anchor.extent.x;
    self.planeGeometry.height = anchor.extent.z;
    
    // When the plane is first created it's center is 0,0,0 and the nodes
    // transform contains the translation parameters. As the plane is updated
    // the planes translation remains the same but it's center is updated so
    // we need to update the 3D geometry position
    self.position = SCNVector3Make(anchor.center.x, anchor.center.y, anchor.center.z);
    [self setTextureScale];
}
@end
