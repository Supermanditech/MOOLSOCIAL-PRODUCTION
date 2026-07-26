package com.moolsocial.app.youtube

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class YouTubeEmbeddedPlayerPlatformViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?,
    ): PlatformView = YouTubeEmbeddedPlayerPlatformView(
        context = context,
        viewId = viewId,
        messenger = messenger,
    )

    companion object {
        const val VIEW_TYPE = "com.moolsocial.app/youtube_embedded_player"
    }
}
