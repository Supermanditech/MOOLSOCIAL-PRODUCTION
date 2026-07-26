#if DEBUG
  import Flutter
  import UIKit

  final class YouTubeEmbeddedPlayerPlatformViewFactory:
    NSObject, FlutterPlatformViewFactory
  {
    static let viewType = "com.moolsocial.app/youtube_embedded_player"

    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
      self.messenger = messenger
      super.init()
    }

    func create(
      withFrame frame: CGRect,
      viewIdentifier viewId: Int64,
      arguments args: Any?
    ) -> FlutterPlatformView {
      YouTubeEmbeddedPlayerPlatformView(
        frame: frame,
        viewId: viewId,
        messenger: messenger
      )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
      FlutterStandardMessageCodec.sharedInstance()
    }
  }
#endif
