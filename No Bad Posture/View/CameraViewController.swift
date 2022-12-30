
import UIKit
import AVFoundation
import Combine

class CameraViewController: UIViewController{

    private var captureSession: AVCaptureSession!
    private var frontFacingCamera: AVCaptureDevice!
    private var dataOutput: AVCaptureVideoDataOutput!
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedOutput",qos: .userInteractive)
    private var screenDots = [CAShapeLayer]()
    private var screenLines = [CAShapeLayer]()
    
    private let viewModel: CameraViewModel
    private let sampleBufferSubject = PassthroughSubject<CMSampleBuffer,Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    
    @IBOutlet private weak var alertLabel: UILabel!
    
    init(viewModel: CameraViewModel){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {fatalError("Error in SimpleCameraController.swift")}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCaptureSession()
        configureCameraView()
        bindViewModelInputs()
        bindViewModelOutputs()
        captureSession.startRunning()
    }
    
    private func configureCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
   
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        
        frontFacingCamera = deviceDiscoverySession.devices.first{ $0.position == .front }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: frontFacingCamera) else {
            fatalError("Could not add video device input to the session")
        }
        captureSession.addInput(deviceInput)
        //. The data output will take samples of images from the camera feed and provide them in a delegate on a defined dispatch queue, which you set up earlier.
        dataOutput = AVCaptureVideoDataOutput()
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            fatalError("Could not add video data output to the session")
        }
        captureSession.commitConfiguration()
    }

    func configureCameraView(){
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = .resizeAspectFill
        cameraPreviewLayer?.frame.size = view.layer.frame.size
        view.bringSubviewToFront(alertLabel)   // Bring the camera button to front
    }

   
    private func bindViewModelInputs(){
        sampleBufferSubject
            .bind(to: viewModel.input.mediaData)
            .store(in: &subscriptions)
    }
    
    private func bindViewModelOutputs(){
        
        viewModel.output.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                alertLabel.text = $0
            }.store(in: &subscriptions)
        
        viewModel.output.bodyDots
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                drawDots($0)
            }.store(in: &subscriptions)
        
        viewModel.output.bodyLines
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                drawLines($0)
            }.store(in: &subscriptions)
    }
        
    private func drawDots(_ points: [CGPoint?]) {
        screenDots.forEach{ $0.removeFromSuperlayer() }
        screenDots = []
        let avpoints = points.compactMap{$0}.map{ CGPoint(x: $0.x, y: 1 - $0.y) }
        let drawPoints = avpoints.map{ cameraPreviewLayer!.layerPointConverted(fromCaptureDevicePoint: $0) }
        drawPoints.forEach {
            let dotPath = UIBezierPath(ovalIn: CGRect(x: $0.x - 8, y: $0.y - 8, width: 16, height: 16))
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = dotPath.cgPath
            shapeLayer.fillColor = UIColor.green.cgColor
            screenDots.append(shapeLayer)
            cameraPreviewLayer?.addSublayer(shapeLayer)
        }
    }
    
    private func drawLines(_ lines: [(CGPoint?,CGPoint?)]){
        screenLines.forEach{ $0.removeFromSuperlayer() }
        screenLines = []
        lines.forEach {
            guard let startPoint = $0.0 else { return }
            guard let endPoint = $0.1 else { return }
            let line = CAShapeLayer()
            line.path = {
                let linePath = UIBezierPath()
                linePath.move(to: startPoint)
                linePath.addLine(to: endPoint)
                return linePath.cgPath
            }()
            line.strokeColor = UIColor.green.cgColor
            line.lineWidth = 5
            screenLines.append(line)
            cameraPreviewLayer?.addSublayer(line)
        }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,didOutput sampleBuffer: CMSampleBuffer,from connection: AVCaptureConnection) {
        sampleBufferSubject.send(sampleBuffer)
    }
}
