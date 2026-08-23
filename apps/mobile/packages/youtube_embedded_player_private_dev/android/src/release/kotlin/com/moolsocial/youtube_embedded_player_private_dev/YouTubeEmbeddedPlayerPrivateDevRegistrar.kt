package com.moolsocial.youtube_embedded_player_private_dev

import com.moolsocial.app.youtube.YouTubeEmbeddedPlayerPlatformViewFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin

internal object YouTubeEmbeddedPlayerPrivateDevRegistrar {
    fun register(binding: FlutterPlugin.FlutterPluginBinding) {
        check(
            binding.platformViewRegistry.registerViewFactory(
                YouTubeEmbeddedPlayerPlatformViewFactory.VIEW_TYPE,
                YouTubeEmbeddedPlayerPlatformViewFactory(
                    binding.binaryMessenger,
                ),
            ),
        ) {
            "The release-review YouTube player view type is already registered."
        }
    }
}
