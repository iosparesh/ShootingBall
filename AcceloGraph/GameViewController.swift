//
//  GameViewController.swift
//  AcceloGraph
//
//  Created by Paresh Prajapati on 11/02/20.
//  Copyright © 2020 SolutionAnalysts. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion


class GameViewController: UIViewController {

    let motion = CMMotionManager()
    var timer:Timer?
    var sceneView: SCNView!
    var cameraNode: SCNNode!
    var wallNode: SCNNode!
    var lineNode: SCNNode!
    var gunNode: SCNNode!
    var pointNode: SCNNode!
    var bulletNode: SCNNode!
    var particleNode: SCNNode!
    var gunX:Float = 0
    var gunY:Float = 0
    var gunZ:Float = -28
    var movingNow = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = self.view as? SCNView
        setupScene()
        setupCamera()
        
        let box = SCNBox(width: 50, height: 50  , length: 0.2, chamferRadius: 0)
        wallNode = SCNNode(geometry: box)
        wallNode.name = "bubbleWall"
        wallNode.categoryBitMask = 5
        wallNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        wallNode.physicsBody?.collisionBitMask = 6
        wallNode.physicsBody?.isAffectedByGravity = false
        wallNode.physicsBody?.allowsResting = false
        wallNode.position = SCNVector3(0,0,-40)
        wallNode.physicsBody?.friction = 2
        wallNode.physicsBody?.mass = 0
        wallNode.geometry?.materials.first?.diffuse.contents = UIImage(named: "bga")
        
        
        sceneView.scene?.rootNode.addChildNode(wallNode)
        var ypos = wallNode.position.y + 22.5
        for _ in 0..<10 {
            var xpos = wallNode.position.x - 22.5
            for _ in 0..<10 {
                let box1 = SCNSphere(radius: 2.5)
                let node1 = SCNNode(geometry: box1)
                node1.name = "ball"
                node1.geometry?.materials.first?.diffuse.contents = UIColor.random()
                node1.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
                node1.physicsBody?.mass = 2
                node1.physicsBody?.restitution = 1.0
                node1.physicsBody?.isAffectedByGravity = false
//                node1.physicsBody?.allowsResting = false
                node1.position = SCNVector3(xpos ,ypos,-28)
                xpos = xpos + 5
                sceneView.scene?.rootNode.addChildNode(node1)
                node1.physicsBody?.categoryBitMask = 2
                node1.physicsBody?.collisionBitMask = 1
            }
            ypos = ypos - 5
        }
        let point = SCNBox(width: 5, height: 5, length: 0, chamferRadius: 2.5)
        let viewPoint = SCNNode(geometry: point)
        sceneView.pointOfView = viewPoint
        
        let box1 = SCNBox(width: 5, height: 5, length: 0, chamferRadius: 2.5)
        pointNode = SCNNode(geometry: box1)
        pointNode.name = "point"
        pointNode.geometry?.materials.first?.diffuse.contents = UIImage(named: "point")
        pointNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        pointNode.physicsBody?.categoryBitMask = 1
        pointNode.position = SCNVector3(0 ,0,-25)
        let loop = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: 5, duration: 10))
        pointNode.runAction(loop)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag))
        sceneView.addGestureRecognizer(panGesture)
        sceneView.scene?.rootNode.addChildNode(pointNode)
        if let subNodeScene = SCNScene(named: "art.scnassets/M24_Gun.scn") {
            gunNode = subNodeScene.rootNode.childNode(withName: "SMG", recursively: true)!
            gunNode.position = SCNVector3(0, -(gunNode.position.y + 5), -1)
            gunNode.name = "gun"
            let (minVec, maxVec) = gunNode.boundingBox
            gunNode.pivot = SCNMatrix4MakeTranslation((maxVec.x - minVec.x) / 2 + minVec.x, (maxVec.y - minVec.y) / 2 + minVec.y, 0)
            sceneView.scene?.rootNode.addChildNode(gunNode)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    func CGPointToSCNVector3(view: SCNView, depth: Float, point: CGPoint) -> SCNVector3 {
        let projectedOrigin = view.projectPoint(SCNVector3Make(0, 0, depth))
        let locationWithz   = SCNVector3Make(Float(point.x), Float(point.y), projectedOrigin.z)
        return view.unprojectPoint(locationWithz)
    }
    private var lastDragResult: SCNHitTestResult?
    @objc fileprivate func handleDrag(_ gesture: UIRotationGestureRecognizer) {
        
        let point = gesture.location(in: gesture.view!)
        let result = self.sceneView.hitTest(point, options: nil)
        if let lastDragResult = lastDragResult, let lastpoint = result.first {
            let z = lastpoint.worldCoordinates.z - lastDragResult.worldCoordinates.z
            let vector: SCNVector3 = SCNVector3(lastpoint.worldCoordinates.x - lastDragResult.worldCoordinates.x,
                                                lastpoint.worldCoordinates.y - lastDragResult.worldCoordinates.y,
                                                lastpoint.worldCoordinates.z - lastDragResult.worldCoordinates.z)
            let newposition = pointNode.position + vector
            pointNode.position = SCNVector3(newposition.x, newposition.y, pointNode.position.z)
            gunNode.look(at: newposition)
        }
        if result.last != nil {
            lastDragResult = result.last
        }
        

        if gesture.state == .ended {
            self.lastDragResult = nil
        }
    }
    
    func setupScene() {
        sceneView.delegate = self
        let scnScene = SCNScene()
        let node = SCNNode(geometry: SCNBox(width: sceneView.frame.size.width, height: sceneView.frame.size.height, length: 25, chamferRadius: 0))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        node.physicsBody?.type = .static
        node.geometry?.materials.first?.diffuse.contents = UIImage(named: "bga")
        scnScene.background.contents = UIColor.green
        sceneView.scene = scnScene
        sceneView.showsStatistics = true
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene?.physicsWorld.contactDelegate = self
        
    }
    
    func setupCamera() {
      // 1
      cameraNode = SCNNode()
      // 2
      cameraNode.camera = SCNCamera()
      // 3
      cameraNode.position = SCNVector3(x: 0, y: 0, z: 20)
      // 4
//      sceneView.scene?.rootNode.addChildNode(cameraNode)
    }
    func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)

        // Setup a translation matrix with the desired position
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = position.x
        translationMatrix.columns.3.y = position.y
        translationMatrix.columns.3.z = position.z

        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
        node.transform = SCNMatrix4(updatedTransform)
    }
    func startAccelerometere() {
        if self.motion.isAccelerometerAvailable {
            self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
            self.motion.startAccelerometerUpdates(to: .main) { [unowned self] (data, error) in
                    if let data = self.motion.accelerometerData {
                        let x = data.acceleration.x
                        let y = data.acceleration.y
                        let z = data.acceleration.z
                        print("X : \(x) Y : \(y) Z : \(z)")
                        self.sceneView.scene?.physicsWorld.gravity = SCNVector3(x * 10, y * 10, z * 10 )
                    }
            }
        }
    }
    func createLineNode(fromPos origin: SCNVector3, toPos destination: SCNVector3, color: UIColor) -> SCNNode {
        let line = lineFrom(vector: origin, toVector: destination)
        let lineNode = SCNNode(geometry: line)
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = color
        line.materials = [planeMaterial]

        return lineNode
    }

    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]

        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)

        return SCNGeometry(sources: [source], elements: [element])
    }


    func highlightNode(_ node: SCNNode) {
        let (min, max) = node.boundingBox
        let zCoord = node.position.z
        let topLeft = SCNVector3Make(min.x, max.y, zCoord)
        let bottomLeft = SCNVector3Make(min.x, min.y, zCoord)
        let topRight = SCNVector3Make(max.x, max.y, zCoord)
        let bottomRight = SCNVector3Make(max.x, min.y, zCoord)


        let bottomSide = createLineNode(fromPos: bottomLeft, toPos: bottomRight, color: .yellow)
        let leftSide = createLineNode(fromPos: bottomLeft, toPos: topLeft, color: .yellow)
        let rightSide = createLineNode(fromPos: bottomRight, toPos: topRight, color: .yellow)
        let topSide = createLineNode(fromPos: topLeft, toPos: topRight, color: .yellow)

        [bottomSide, leftSide, rightSide, topSide].forEach {
            $0.name = "H" // Whatever name you want so you can unhighlight later if needed
            node.addChildNode($0)
        }
    }

    func unhighlightNode(_ node: SCNNode) {
        let highlightningNodes = node.childNodes { (child, stop) -> Bool in
            child.name == "Y"
        }
        highlightningNodes.forEach {
            $0.removeFromParentNode()
        }
    }
    func updateLineNode(vector: SCNVector3) {
        lineNode.look(at: vector, up: vector, localFront: vector)
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            guard result.node.name != "bubbleWall" else { return }
            
            if result.node.name == "ball" {
                gunX = result.node.position.x
                gunY = result.node.position.y
                gunZ = result.node.position.z
                //material.emission.contents = UIColor.red
                //self.updateLineNode(vector: SCNVector3(gunX, gunY, gunZ))
                
                return }
            // highlight it
            if result.node.name == "gun" {
                self.createBulletandFire()
            }
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                material.emission.contents = UIColor.black
                SCNTransaction.commit()
            }
            
//            result.node.physicsBody?.applyForce(SCNVector3(0,5,0), at: SCNVector3(0,5,0), asImpulse: true)
            //create Node
            // move to direction
            // play sound
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    func createBulletandFire() {
//        if bulletNode != nil {
//            bulletNode.removeFromParentNode()
//        }
        let bullet = SCNSphere(radius: 1)
        bulletNode = SCNNode(geometry: bullet)
        bulletNode.name = "bullet"
        bulletNode.position = gunNode.position
        bulletNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        bulletNode.physicsBody?.isAffectedByGravity = false
        bulletNode.physicsBody?.contactTestBitMask = 3
        bulletNode.physicsBody?.categoryBitMask = 1
        bulletNode.physicsBody?.collisionBitMask = 2
        bulletNode.physicsBody?.mass = 0.5
        sceneView.scene?.rootNode.addChildNode(bulletNode)
        bulletNode.physicsBody?.applyForce(SCNVector3(pointNode.simdPosition.x, pointNode.simdPosition.y + 2, pointNode.simdPosition.z), asImpulse: true)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
      let trail = SCNParticleSystem(named: "art.scnassets/blast.scn", inDirectory: nil)!
      trail.particleColor = color
      trail.emitterShape = geometry
      return trail
    }
    func createExplosion(geometry: SCNGeometry, position: SCNVector3,
      rotation: SCNVector4) {
        let explosion =
        SCNParticleSystem(named: "art.scnassets/Explode.scnp", inDirectory:
      nil)!
        explosion.emitterShape = bulletNode.geometry
        let rotationMatrix =
        SCNMatrix4MakeRotation(rotation.w, rotation.x,
          rotation.y, rotation.z)
      let translationMatrix =
        SCNMatrix4MakeTranslation(position.x, position.y,
          position.z)
      let transformMatrix =
        SCNMatrix4Mult(rotationMatrix, translationMatrix)
        sceneView.scene?.addParticleSystem(explosion, transform:
        transformMatrix)
    }
    func blastTheBall(at : SCNNode) {
        if particleNode != nil {
            particleNode.position = at.position
            particleNode.isHidden = false
        }
        else if let subNodeScene = SCNScene(named: "art.scnassets/blast.scn") {
            particleNode = subNodeScene.rootNode.childNode(withName: "particles", recursively: true)!
            particleNode.position = at.position
            sceneView.scene?.rootNode.addChildNode(particleNode)
        }
    }

}
extension GameViewController: SCNPhysicsContactDelegate, SCNSceneRendererDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if contact.nodeA.physicsBody?.collisionBitMask == 1 && contact.nodeB.physicsBody?.collisionBitMask == 2 || contact.nodeA.physicsBody?.collisionBitMask == 2 && contact.nodeB.physicsBody?.collisionBitMask == 1 {
            createExplosion(geometry: bulletNode.geometry!, position: bulletNode.presentation.position,
                            rotation: bulletNode.presentation.rotation)
            let seconds = 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                contact.nodeB.removeFromParentNode()
                contact.nodeA.removeFromParentNode()
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        print(time)
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        
    }
}
