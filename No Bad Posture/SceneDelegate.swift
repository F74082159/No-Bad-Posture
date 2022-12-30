

import UIKit

class Dependency: HasPostureDetector, HasSoundPlayer {
    var postureDetector: PostureDetecting = SittingPostureDetector()
    var soundPlayer: SoundPlaying = AlertSoundPlayer()
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var dependency = Dependency()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene{
            window = UIWindow(windowScene: windowScene)
            let viewModel = CameraViewModel(dependencies: dependency)
            let viewController = CameraViewController(viewModel: viewModel)
            window!.rootViewController = viewController
            window!.makeKeyAndVisible()
        }
    }

}

