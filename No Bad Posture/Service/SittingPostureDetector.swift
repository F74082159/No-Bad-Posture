
import Foundation
import CoreGraphics

protocol PostureDetecting: AnyObject {
    func checkWrongPostures(_ body: Body) -> Set<WrongPosture>
}

class SittingPostureDetector: PostureDetecting {
    
    func checkWrongPostures(_ body: Body) -> Set<WrongPosture> {
        var wrongPostures = Set<WrongPosture>()
        if checkSlouching(body) { wrongPostures.insert(.Slouching) }
        if checkHeadDrop(body) { wrongPostures.insert(.HeadDrop)}
        if checkChinOnHand(body) { wrongPostures.insert(.ChinOnHand) }
        return wrongPostures
    }
    
    private func checkSlouching(_ body: Body) -> Bool{
        if let rightEar = body.rightEar, let rightShoulder = body.rightShoulder {
            let angle = findAngle(between: rightEar, ending: rightShoulder)
            print("駝背角度：\(angle)")
            if angle < 59 { return true }
        }
        return false
    }
    
    private func checkHeadDrop(_ body: Body) -> Bool{
        if let rightEye = body.rightEye, let rightEar = body.rightEar {
            let angle = findAngle(between: rightEye, ending: rightEar)
            print("頭角度：\(angle)")
            if angle < 0 { return true }
        }
        return false
    }
    
    private func checkChinOnHand(_ body: Body) -> Bool {
        if let rightHand = body.rightHand, let rightShoulder = body.rightShoulder{
            if rightHand.y - 20 < rightShoulder.y { return true }
        }
        return false
    }
    
    private func findAngle(between starting: CGPoint, ending: CGPoint) -> CGFloat {
        let center = CGPoint(x: ending.x - starting.x, y: ending.y - starting.y)
        let radians = atan2(center.y, center.x)
        let degrees = radians * 180 / .pi
        return degrees > 0 ? degrees : degrees + degrees
    }
}
