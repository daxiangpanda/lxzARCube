//
//  ViewController.m
//  lxzARCube
//
//  Created by 刘鑫忠 on 2017/11/23.
//  Copyright © 2017年 刘鑫忠. All rights reserved.
//

#import "ViewController.h"
#import "Plane.h"

typedef NS_OPTIONS(NSUInteger, CollisionCategory) {
    CollisionCategoryBottom  = 1 << 0,
    CollisionCategoryCube    = 1 << 1,
};

@interface ViewController () <ARSCNViewDelegate,UIGestureRecognizerDelegate,SCNPhysicsContactDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView        *sceneView;
@property (nonatomic, strong) NSTimer                   *timer;
@property (nonatomic, strong) SCNNode                   *boxNode;
@property (nonatomic, strong) SCNNode                   *lingerNode;
@property (nonatomic, strong) SCNLight                  *spotLight;
@property (nonatomic, assign) int                       cubeNum;

@property (nonatomic, strong) UILabel                   *xLabel;
@property (nonatomic, strong) UILabel                   *yLabel;
@property (nonatomic, strong) UILabel                   *zLabel;
@property (nonatomic, strong) UILabel                   *scaleLabel;


@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupScene];
    
    [self setupRecognizers];
    
    [self insertSpotLight:SCNVector3Make(0.0, 0.0, 0.0)];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupSession];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}


- (void)setupScene {
    // Setup the ARSCNViewDelegate - this gives us callbacks to handle new
    // geometry creation
    self.sceneView.delegate = self;
    
    // A dictionary of all the current planes being rendered in the scene
    self.planes = [NSMutableDictionary new];
    
    self.boxes = [NSMutableArray new];
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
//    self.sceneView.autoenablesDefaultLighting = NO;
    
//    self.sceneView.automaticallyUpdatesLighting = YES;
    // Turn on debug options to show the world origin and also render all
    // of the feature points ARKit is tracking
    self.sceneView.debugOptions =
    ARSCNDebugOptionShowWorldOrigin |
    ARSCNDebugOptionShowFeaturePoints;
    
//    SCNScene *scene = [SCNScene new];
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/AR_hongbao01.dae"];
    self.sceneView.scene = scene;
    
    SCNBox *bottomPlane = [SCNBox boxWithWidth:1000 height:0.5 length:1000 chamferRadius:0];
    SCNMaterial *bottomMaterial = [SCNMaterial new];
    bottomMaterial.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:0.0];
    bottomPlane.materials = @[bottomMaterial];
    
    SCNNode *bottomNode = [SCNNode nodeWithGeometry:bottomPlane];
    bottomNode.position = SCNVector3Make(0, -10, 0);
    bottomNode.physicsBody = [SCNPhysicsBody
                              bodyWithType:SCNPhysicsBodyTypeKinematic
                              shape: nil];
    bottomNode.physicsBody.categoryBitMask = CollisionCategoryBottom;
    bottomNode.physicsBody.contactTestBitMask = CollisionCategoryCube;
    [self.sceneView.scene.rootNode addChildNode:bottomNode];
    self.sceneView.scene.physicsWorld.contactDelegate = self;
    
    
    //
    _lingerNode = [scene.rootNode childNodeWithName:@"AR_Hongbao01" recursively:YES];
    

}
- (void)updateXYZ {
//    _lingerNode.position = SCNVector3Make(_lingerNode.position.x, _lingerNode.position.y+10, _lingerNode.position.z);
//    _lingerNode.scale = SCNVector3Make(_lingerNode.scale.x/1.5,_lingerNode.scale.y/1.5, _lingerNode.scale.z/1.5);
    NSLog(@"x:%f,y:%f,z:%f",_lingerNode.position.x,_lingerNode.position.y,_lingerNode.position.z);
    
    self.xLabel.text = [NSString stringWithFormat:@"x:%.3f,y:%.3f,z:%.3f",_lingerNode.position.x,_lingerNode.position.y,_lingerNode.position.z];
}

- (void)setupSession {
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    
//    configuration.lightEstimationEnabled = TRUE;
    // Specify that we do want to track horizontal planes. Setting this will cause the ARSCNViewDelegate
    // methods to be called when scenes are detected
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    
    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateXYZ) userInfo:nil repeats:YES];
}


- (void)setupRecognizers {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapFrom:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.sceneView addGestureRecognizer:tapGestureRecognizer];
}

- (void)handleTapFrom:(UITapGestureRecognizer*)recognizer {
    CGPoint tapPoint = [recognizer locationInView:self.sceneView];
    NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:tapPoint types:ARHitTestResultTypeExistingPlaneUsingExtent];
    
    if(result.count == 0) {
        return;
    }
    
    ARHitTestResult *hitResult = [result firstObject];
    [self insertNode:hitResult];
}

-(void)insertGeometry:(ARHitTestResult*)hitResult {
    _cubeNum+=1;
    float dimension = 0.1;
    SCNBox *cube = [SCNBox boxWithWidth:dimension height:dimension length:dimension chamferRadius:0];
    SCNNode *node = [SCNNode nodeWithGeometry:cube];
    
    node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
    node.physicsBody.mass = _cubeNum*10;
    node.physicsBody.categoryBitMask = CollisionCategoryCube;
    
    float insertionYOffset = 0.5;
    node.position = SCNVector3Make(hitResult.worldTransform.columns[3].x, hitResult.worldTransform.columns[3].y + insertionYOffset, hitResult.worldTransform.columns[3].z);
    [self.sceneView.scene.rootNode addChildNode:node];
    [self.boxes addObject:node];
}

- (void)insertNode:(ARHitTestResult*)hitResult {
    SCNScene *lingerScene = [SCNScene sceneNamed:@"art.scnassets/linger.dae"];
    
    SCNNode *lingerNode = _lingerNode;
    
    for(SCNNode *childNode in lingerScene.rootNode.childNodes) {
        [lingerNode addChildNode:childNode];
    }
    
//    lingerNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
//    lingerNode.physicsBody.mass = 100.0;
//    lingerNode.physicsBody.categoryBitMask = CollisionCategoryCube;
    
    float insertionYOffset = 0.5;
    lingerNode.position = SCNVector3Make(hitResult.worldTransform.columns[3].x, hitResult.worldTransform.columns[3].y + insertionYOffset, hitResult.worldTransform.columns[3].z);

    lingerNode.scale = SCNVector3Make(0.0001,0.0001,0.0001);
    
//    lingerNode.position = SCNVector3Make(0, -200.0, -800.0);
//    lingerNode.scale = SCNVector3Make(0.1,0.1,0.1);
    
    [self.sceneView.scene.rootNode addChildNode:lingerNode];
    
}

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    if(![anchor isKindOfClass:[ARPlaneAnchor class]]) {
        return ;
    }
    
    Plane *plane = [[Plane alloc]initWithAnchor:(ARPlaneAnchor*)anchor isHidden:NO];
    
    [node addChildNode:plane];
    
}

-(void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    Plane *plane = [self.planes objectForKey:anchor.identifier];
    if(plane == nil) {
        return;
    }
    [plane update:(ARPlaneAnchor *)anchor];
}

- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
//    ARLightEstimate *estimate = self.sceneView.session.currentFrame.lightEstimate;
//    
//    if(!estimate) {
//        return;
//    }
//    
////    NSLog(@"light estimate: %f",estimate.ambientIntensity);
//    self.sceneView.scene.lightingEnvironment.intensity = estimate.ambientIntensity/1000.0*3;
    
    
}

-(void)insertSpotLight:(SCNVector3)position {
    _spotLight = [SCNLight light];
    _spotLight.type = SCNLightTypeSpot;
    _spotLight.spotInnerAngle = 450;
    _spotLight.spotOuterAngle = 450;
    
//    spotLight.intensity
    SCNNode *spotNode = [SCNNode new];
    spotNode.light = _spotLight;
    
    spotNode.eulerAngles = SCNVector3Make(-M_PI / 2, 0, 0);
    [self.sceneView.scene.rootNode addChildNode:spotNode];
}

- (UILabel *)xLabel {
    if(!_xLabel) {
        _xLabel = [[UILabel alloc]init];
        _xLabel.frame = CGRectMake(0, 600, 400, 50);
        _xLabel.font = [UIFont systemFontOfSize:20.0f];
        _xLabel.textColor = [UIColor whiteColor];
        
        [self.view addSubview:_xLabel];
    }
    
    return _xLabel;
}

@end
