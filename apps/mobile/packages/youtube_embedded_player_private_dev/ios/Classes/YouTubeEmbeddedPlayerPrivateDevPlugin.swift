import Flutter
import UIKit

public final class YouTubeEmbeddedPlayerPrivateDevPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if DEBUG
      registrar.register(
        YouTubeEmbeddedPlayerPlatformViewFactory(
          messenger: registrar.messenger()
        ),
        withId: YouTubeEmbeddedPlayerPlatformViewFactory.viewType
      )
    #endif
  }
}
