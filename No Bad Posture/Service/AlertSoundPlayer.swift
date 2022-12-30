

import Foundation
import AVFoundation

protocol SoundPlaying: AnyObject {
    func play(_ soundFile: String)
    func stop()
}

protocol AlertSoundPlayerDelegate: AnyObject {
    func soundDidFinishPlaying(_ sender: Any)
}

class AlertSoundPlayer: NSObject, SoundPlaying {
    private var soundPlayer: AVAudioPlayer!
    weak var delegate: AlertSoundPlayerDelegate?
    
    func play(_ soundFile: String){
        soundPlayer?.delegate = nil
        soundPlayer?.stop()
    
        guard let range = soundFile.range(of: ".", options: .backwards) else {return}
        let soundFileName = String(soundFile[..<range.lowerBound])
        let soundFileType = String(soundFile[range.upperBound...])
        guard let fileURL = Bundle.main.url(forResource: soundFileName, withExtension: soundFileType) else {return}
        guard let player = try? AVAudioPlayer(contentsOf: fileURL) else {return}
        
        soundPlayer = player
        soundPlayer.prepareToPlay()
        soundPlayer.delegate = self
        soundPlayer.play()
    }
    
    func stop(){
        
    }
}

extension AlertSoundPlayer: AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.soundDidFinishPlaying(self)
    }
}
