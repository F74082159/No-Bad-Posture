
import Foundation
import Vision

class Body {
    
    private(set) var nose: CGPoint?
    private(set) var rightEye: CGPoint?
    private(set) var rightEar: CGPoint?
    private(set) var rightShoulder: CGPoint?
    private(set) var rightHand: CGPoint?
    
    init(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
        guard let request = try? perform(request: bodyPoseRequest, on: sampleBuffer) else { return }
        guard let observation = request.results?.first as? VNHumanBodyPoseObservation else { return }
        markBodyLocations(with: observation)
    }
    
    private func perform(request: VNRequest, on sampleBuffer: CMSampleBuffer) throws -> VNRequest {
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,orientation: .up)
        try requestHandler.perform([request])
        return request
    }

    private func markBodyLocations(with observation: VNHumanBodyPoseObservation){
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else { return }
        
        if let point = recognizedPoints[.nose], point.confidence > 0.1 { nose = point.location }
        if let point = recognizedPoints[.rightEye], point.confidence > 0.1 { rightEye = point.location }
        if let point = recognizedPoints[.rightEar], point.confidence > 0.1 { rightEar = point.location }
        if let point = recognizedPoints[.rightWrist], point.confidence > 0.1 { rightHand = point.location }
        if let point = recognizedPoints[.rightShoulder], point.confidence > 0.1 { rightShoulder = point.location }
    }
}
