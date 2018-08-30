//
//  ViewController.swift
//  CoreAnimation
//
//  Created by Robert Vaessen on 7/15/18.
//  Copyright © 2018 Robert Vaessen. All rights reserved.
//
// A layer's position is the location of its anchor point in its parent's bounds.
//

import UIKit

typealias Degrees = CGFloat
typealias Radians = CGFloat

func toRadians(_ degrees: Degrees) -> Radians { return degrees * .pi / 180.0 }

class View : UIView {
    override func layoutSublayers(of layer: CALayer) {
        print("Laying out sublayers")
    }
}

private enum Axis {
    case X, Y, Z

    static func draw(in: CALayer) {
        let shape = CAShapeLayer()
        shape.frame = `in`.bounds
        shape.strokeColor = UIColor(white: 1, alpha: 0.8).cgColor
        shape.lineWidth = 2
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: shape.bounds.midX, y: 0)) // Vertical axis
        path.addLine(to: CGPoint(x: shape.bounds.midX, y: shape.bounds.maxY))
        path.move(to: CGPoint(x: 0, y: shape.bounds.midY)) // Horizontal axis
        path.addLine(to: CGPoint(x: shape.bounds.maxX, y: shape.bounds.midY))
        path.close()
        
        shape.path = path.cgPath
        
        `in`.addSublayer(shape)
    }
}

private enum Quadrant : String {
    case NW, NE, SE, SW
    
    typealias Layout = (position: CGPoint, size: CGSize)
    
    static let all: [Quadrant] = [.NW, .NE, .SE, .SW]
    
    func layoutFor(plane: CGRect) -> Layout {

        var position: CGPoint
        let quaterWidth = plane.width / 4
        let quaterHeight = plane.height / 4
        switch self {
        case .NW: position = CGPoint(x: quaterWidth, y: quaterHeight)
        case .NE: position = CGPoint(x: 3 * quaterWidth, y: quaterHeight)
        case .SE: position = CGPoint(x: 3 * quaterWidth, y: 3 * quaterHeight)
        case .SW: position = CGPoint(x: quaterWidth, y: 3 * quaterHeight)
        }

        let size = CGSize(width: plane.width/2, height: plane.width/2)

        return (position, size)
    }

    var color: CGColor {
        switch self {
        case .NW: return UIColor.black.cgColor
        case .NE: return UIColor.red.cgColor
        case .SE: return UIColor.yellow.cgColor
        case .SW: return UIColor.white.cgColor
        }
    }

    func add(to: CALayer) {
        let layout = self.layoutFor(plane: to.bounds)

        let sublayer = CALayer()
        sublayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sublayer.quadrant = self
        sublayer.position = layout.position
        sublayer.bounds.size = layout.size
        sublayer.backgroundColor = color
        
        to.addSublayer(sublayer)
    }
}

private extension CALayer {

    var quadrant : Quadrant {
        set {
            name = newValue.rawValue
        }
        get {
            guard let quadrantName = name else { fatalError("Quadrant layer has no name") }
            guard let quadrant = Quadrant(rawValue: quadrantName)  else { fatalError("Invalid quadrant layer name: \(quadrantName)") }
            return quadrant
        }
    }
    
    func layoutIn(plane: CGRect) {
        let layout = quadrant.layoutFor(plane: plane)
        position = layout.position
        bounds.size = layout.size
    }
}

class ViewController : UIViewController {

    @IBOutlet weak var graphView: UIView!
    private var plane: CALayer!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var yButton: UIButton!
    @IBOutlet weak var zButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Axis.draw(in: graphView.layer)

        plane = CALayer()
        plane.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        plane.position = CGPoint(x: graphView.layer.bounds.width/2, y: graphView.layer.bounds.height/2)
        plane.bounds.size = CGSize(width: graphView.layer.bounds.width/4, height: graphView.layer.bounds.width/4)
        plane.backgroundColor = UIColor.white.cgColor
        plane.transform.m34 = -1.0 / 500;
       graphView.layer.addSublayer(plane)

        for quadrant in Quadrant.all { quadrant.add(to: plane) }
    }

    @IBAction func x(_ sender: UIButton) {
        xButton.isSelected = !xButton.isSelected
        rotation(on: .X, isActive: xButton.isSelected)
    }
    
    @IBAction func y(_ sender: UIButton) {
        yButton.isSelected = !yButton.isSelected
        rotation(on: .Y, isActive: yButton.isSelected)
    }
    
    @IBAction func z(_ sender: UIButton) {
        zButton.isSelected = !zButton.isSelected
        rotation(on: .Z, isActive: zButton.isSelected)
    }
    
    // *************************************************************************************

    private func rotate(layer: CALayer, around: Axis, by: Degrees) {

        let angle = toRadians(by)

        switch around {
        case .X:
            layer.transform = CATransform3DRotate(layer.transform, angle, 1, 0, 0)
        case .Y:
            layer.transform = CATransform3DRotate(layer.transform, angle, 0, 1, 0)
        case .Z:
            layer.transform = CATransform3DRotate(layer.transform, angle, 0, 0, 1)
        }
    }
    
    private func resetRotation(for: CALayer) {
        `for`.transform = CATransform3DIdentity
        `for`.transform.m34 = -1.0 / 500;
    }

    // *************************************************************************************
    // Animations
    // *************************************************************************************

    private func rotation(on: Axis, isActive: Bool) {
        
    }

    @IBAction func rotateContinuously(_ sender: UIButton) {
        
        let key = "rotate"
        
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            var keyPath = "transform.rotation.x"
            if yButton.isSelected { keyPath = "transform.rotation.y" }
            else if zButton.isSelected { keyPath = "transform.rotation.z" }
            let animation = CABasicAnimation(keyPath: keyPath)
            animation.fromValue = 0
            animation.toValue = 2.0 * .pi
            animation.repeatCount = .infinity
            animation.duration = 5
            
            plane.add(animation, forKey: key)
            
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 500;
            plane.transform = transform
        }
        else {
            plane.removeAnimation(forKey: key)
        }
    }

    @IBAction func growShrink(_ sender: UIButton) {

        let key = "breathe"

        func resize(from: CGSize, to: CGSize, original: CGSize) {
            CATransaction.begin()

            CATransaction.setCompletionBlock {
                guard self.plane.animation(forKey: key) != nil else {
                    // The user cancelled the animation. Restore to original dimensions
                    self.plane.bounds.size = original
                    let originalRect = CGRect(origin: CGPoint(x: 0, y: 0), size: original)
                    for sublayer in self.plane.sublayers! { sublayer.layoutIn(plane: originalRect) }
                    return
                }

                removeAnimations()
                resize(from: to, to: from, original: original) // Resize in the other direction
             }
            
            let duration: CFTimeInterval = 5
            let repeatCount: Float = 1

            let animation = CABasicAnimation(keyPath: "bounds.size")
            animation.fromValue = from
            animation.toValue = to
            animation.repeatCount = repeatCount
            animation.duration = duration
            animation.isRemovedOnCompletion = false
            plane.add(animation, forKey: key)

            for sublayer in self.plane.sublayers! {
                let start = sublayer.quadrant.layoutFor(plane: CGRect(origin: CGPoint(x: 0, y: 0), size: from))
                let end = sublayer.quadrant.layoutFor(plane: CGRect(origin: CGPoint(x: 0, y: 0), size: to))

                let positionAnimation = CABasicAnimation(keyPath: "position")
                positionAnimation.fromValue = start.position
                positionAnimation.toValue = end.position
                positionAnimation.repeatCount = repeatCount
                positionAnimation.duration = duration
                positionAnimation.isRemovedOnCompletion = false
                sublayer.add(positionAnimation, forKey: "position")

                let sizeAnimation = CABasicAnimation(keyPath: "bounds.size")
                sizeAnimation.fromValue = start.size
                sizeAnimation.toValue = end.size
                sizeAnimation.repeatCount = repeatCount
                sizeAnimation.duration = duration
                sizeAnimation.isRemovedOnCompletion = false
                sublayer.add(sizeAnimation, forKey: "size")
            }

            CATransaction.commit()
        }

        func removeAnimations() { // Removing the animations causes the completion block to be executed.
            for quadrant in plane.sublayers! { quadrant.removeAllAnimations() }
            plane.removeAnimation(forKey: key)
        }

        // ****************************************************************************

        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            let size = plane.bounds.size
            resize(from: size, to: CGSize(width: 1.5 * size.width, height: 1.5 * size.height), original: size)
        }
        else {
            removeAnimations()
        }
    }
}

