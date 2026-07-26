package com.moolsocial.youtube_embedded_player_private_dev

import io.flutter.embedding.engine.plugins.FlutterPlugin

class YouTubeEmbeddedPlayerPrivateDevPlugin : FlutterPlugin {
    override fun onAttachedToEngine(
        binding: FlutterPlugin.FlutterPluginBinding,
    ) {
        YouTubeEmbeddedPlayerPrivateDevRegistrar.register(binding)
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding,
    ) = Unit
}
