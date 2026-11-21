import UIKit
import Foundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var router: AppRouter?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Unit tests start the app too. They need no screen and no network calls.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }

        // The one place where the real network client is created.
        let apiClient = URLSessionAPIClient(baseURL: AppConfig.apiBaseURL)

        let navigationController = UINavigationController()
        let router = AppRouter(navigationController: navigationController, apiClient: apiClient)
        router.start()
        self.router = router

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
