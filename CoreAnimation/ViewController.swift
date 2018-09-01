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

private enum Dimension : String {
    case X, Y, Z
}

private class Axis {
    let dimension: Dimension
    var angle: Radians

    init(dimension: Dimension, angle: Radians = 0) {
        self.dimension = dimension
        self.angle = angle
    }

    var animationKey: String {
        get { return "rotate" + dimension.rawValue }
    }
    
    var animationPath: String {
        get { return "transform.rotation." + dimension.rawValue.lowercased() }
    }

    func rotate(by: Radians) { angle = (angle + by).truncatingRemainder(dividingBy: 2 * .pi) }
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
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var yButton: UIButton!
    @IBOutlet weak var zButton: UIButton!
    @IBOutlet weak var continuouSwitch: UISwitch!
    
    private var plane: CALayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        func drawAxes(in: CGRect) -> CAShapeLayer {
            let shape = CAShapeLayer()

            shape.frame = `in`
            shape.strokeColor = UIColor(white: 1, alpha: 0.8).cgColor
            shape.lineWidth = 2
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: shape.bounds.midX, y: 0)) // Vertical axis
            path.addLine(to: CGPoint(x: shape.bounds.midX, y: shape.bounds.maxY))
            path.move(to: CGPoint(x: 0, y: shape.bounds.midY)) // Horizontal axis
            path.addLine(to: CGPoint(x: shape.bounds.maxX, y: shape.bounds.midY))
            path.close()
            
            shape.path = path.cgPath
            return shape
        }

        func makePlane(in: CGRect) -> CALayer {
            let plane = CALayer()
            plane.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            plane.position = CGPoint(x: `in`.midX, y: `in`.midY)
            plane.bounds.size = CGSize(width: `in`.width/4, height: `in`.width/4)
            plane.backgroundColor = UIColor.white.cgColor
            plane.transform.m34 = -1.0 / 500;
            return plane
        }

        // ***************************************************************

        graphView.layer.addSublayer(drawAxes(in: graphView.layer.bounds))

        plane = makePlane(in: graphView.layer.bounds)
        graphView.layer.addSublayer(plane)

        for quadrant in Quadrant.all { quadrant.add(to: plane) }
    }

    // *************************************************************************************
    // Rotate
    // *************************************************************************************

    private var xAxis = Axis(dimension: .X)
    private var yAxis = Axis(dimension: .Y)
    private var zAxis = Axis(dimension: .Z)

    @IBAction func handleAxisButton(_ sender: UIButton) {
        let axis: Axis

        switch sender {
        case xButton: axis = xAxis
        case yButton: axis = yAxis
        case zButton: axis = zAxis
        default: fatalError("Unrecognized axis button")
        }
        
        if continuouSwitch.isOn {
            sender.isSelected = !sender.isSelected
            continuousRotation(on: axis, isEnabled: sender.isSelected)
        }
        else {
            incrementallyRotate(axis: axis, by: toRadians(15))
        }
    }

    @IBAction func handleContinuousSwitch(_ sender: UISwitch) {

        if !continuouSwitch.isOn {
            xButton.isSelected = false
            continuousRotation(on: xAxis, isEnabled: false)
            yButton.isSelected = false
            continuousRotation(on: xAxis, isEnabled: false)
            zButton.isSelected = false
            continuousRotation(on: xAxis, isEnabled: false)
        }
    }

    @IBAction func handleResetButton(_ sender: UIButton) {
        resetIncrementalRotation()
    }

    private func continuousRotation(on: Axis, isEnabled: Bool) {

        if isEnabled {
            let animation = CABasicAnimation(keyPath: on.animationPath)
            animation.fromValue = on.angle
            animation.toValue = on.angle + 2.0 * .pi
            animation.repeatCount = .infinity
            animation.duration = 5
            
            plane.add(animation, forKey: on.animationKey)
        }
        else {
            plane.removeAnimation(forKey: on.animationKey)
        }
    }

    private func incrementallyRotate(axis: Axis, by angle: Radians) {

        axis.rotate(by: angle)
        switch axis.dimension {
        case .X:
            plane.transform = CATransform3DRotate(plane.transform, angle, 1, 0, 0)
        case .Y:
            plane.transform = CATransform3DRotate(plane.transform, angle, 0, 1, 0)
        case .Z:
            plane.transform = CATransform3DRotate(plane.transform, angle, 0, 0, 1)
        }
    }
    
    private func resetIncrementalRotation() {
        xAxis.angle = 0
        yAxis.angle = 0
        zAxis.angle = 0
        plane.transform = CATransform3DIdentity
        plane.transform.m34 = -1.0 / 500;
    }

    // *************************************************************************************
    // Expand and Contract
    // *************************************************************************************

    @IBAction func expandContract(_ sender: UIButton) {

        let key = "expandContract"

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

