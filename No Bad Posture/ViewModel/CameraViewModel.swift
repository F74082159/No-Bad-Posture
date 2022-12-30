
import Foundation
import Combine
import AVFoundation

protocol HasSoundPlayer {
    var soundPlayer: SoundPlaying { get }
}

protocol HasPostureDetector {
    var postureDetector: PostureDetecting { get }
}

class CameraViewModel {

    struct Input {
        let mediaData: AnySubscriber<CMSampleBuffer,Never>
    }

    struct Output {
        let errorMessage: AnyPublisher<String?,Never>
        let bodyDots: AnyPublisher<[CGPoint?],Never>
        let bodyLines: AnyPublisher<[(CGPoint?,CGPoint?)],Never>
    }
    
    private(set) var input: Input!
    private(set) var output: Output!

    private let mediaDataSubject = PassthroughSubject<CMSampleBuffer,Never>()
    private let bodyPublisher = PassthroughSubject<Body,Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    typealias Dependencies = HasPostureDetector & HasSoundPlayer
    private let dependencies: Dependencies

    init(dependencies: Dependencies){
        self.dependencies = dependencies
        configureInputs()
        configureOutputs()
    }

    private func configureInputs(){
        
        mediaDataSubject.sink { [unowned self] in
            bodyPublisher.send(Body(sampleBuffer: $0, orientation: .up))
        }.store(in: &subscriptions)
        
        input = Input(mediaData: mediaDataSubject.eraseToAnySubscriber())
    }

    private func configureOutputs(){
        
        let errorMessagePublisher = bodyPublisher
            .map{ [unowned self] body in
                dependencies.postureDetector.checkWrongPostures(body)
            }
            .map{ [unowned self] wrongPostures -> String? in
                if wrongPostures.contains(.HeadDrop) {
                    dependencies.soundPlayer.play("HeadTooLow.wav")
                    return "❌頭太低 "
                }
                if wrongPostures.contains(.Slouching) {
                    dependencies.soundPlayer.play("LeanForward.wav")
                    return "❌駝背 "
                }
                if wrongPostures.contains(.ChinOnHand) {
                    dependencies.soundPlayer.play("ChinOnHead.wav")
                    return "❌手托下巴 "
                }
                dependencies.soundPlayer.stop()
                return nil
            }
        
        let bodyDotsPublisher = bodyPublisher
            .map { body -> [CGPoint?] in
                [   body.nose,
                    body.rightEar,
                    body.rightEar,
                    body.rightEye,
                    body.rightHand,
                    body.rightShoulder
                ]
            }
        
        let bodyLinesPublisher = bodyPublisher
            .map { body -> [(CGPoint?,CGPoint?)] in
                [   (body.nose,body.rightEye),
                    (body.rightEye,body.rightEar),
                    (body.rightEar,body.rightShoulder),
                ]
            }
          
        output = Output(errorMessage: errorMessagePublisher.eraseToAnyPublisher(),
                        bodyDots: bodyDotsPublisher.eraseToAnyPublisher(),
                        bodyLines: bodyLinesPublisher.eraseToAnyPublisher())
    }
}


