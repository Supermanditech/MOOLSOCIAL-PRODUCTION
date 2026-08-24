package com.moolsocial.app

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Bundle

/**
 * Validates the token-free YouTube completion result before restarting the
 * accepted Flutter host on the exact in-app route.
 *
 * Keeping this adapter outside MainActivity preserves the immutable
 * first-setup location bridge while still returning a cold or warm browser
 * consent flow to the same MoolSocial destination.
 */
class YouTubeConnectReturnActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val route = validatedRoute(intent?.data)
        if (route != null) {
            val mainActivity = ComponentName(this, MainActivity::class.java)
            val restartIntent = Intent.makeRestartActivityTask(mainActivity).apply {
                putExtra(FLUTTER_INITIAL_ROUTE, route)
            }
            startActivity(restartIntent)
        }
        finish()
    }

    private fun validatedRoute(data: Uri?): String? {
        if (data == null) return null
        val result = data.getQueryParameter("youtubeConnect")
        val isExactYouTubeReturn =
            data.scheme == "moolsocial" &&
                data.host == YOUTUBE_CONNECT_HOST &&
                data.path == YOUTUBE_CONNECT_EXTERNAL_PATH &&
                data.fragment == null &&
                data.queryParameterNames == setOf(YOUTUBE_CONNECT_RESULT) &&
                data.getQueryParameters(YOUTUBE_CONNECT_RESULT).size == 1 &&
                (result == "complete" || result == "failed")
        return if (isExactYouTubeReturn) {
            "$YOUTUBE_CONNECT_INTERNAL_ROUTE?$YOUTUBE_CONNECT_RESULT=$result"
        } else {
            null
        }
    }

    private companion object {
        const val YOUTUBE_CONNECT_HOST = "app"
        const val YOUTUBE_CONNECT_EXTERNAL_PATH = "/creator/youtube-connect"
        const val YOUTUBE_CONNECT_INTERNAL_ROUTE = "/app/creator/youtube-connect"
        const val YOUTUBE_CONNECT_RESULT = "youtubeConnect"
        const val FLUTTER_INITIAL_ROUTE = "route"
    }
}
