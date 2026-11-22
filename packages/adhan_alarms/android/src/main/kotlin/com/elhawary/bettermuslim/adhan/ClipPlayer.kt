package com.elhawary.bettermuslim.adhan

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.util.Log

// a notification's sound played by the app, colorOS mutes a channel's own sound (ADR 0006)
object ClipPlayer {
    // the phone's own notification sound instead of a raw clip
    const val PHONE = "phone"

    private const val TAG = "ClipPlayer"

    // notification volume, like the sound the channel would have made
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()

    fun play(context: Context, clip: String, done: () -> Unit) {
        val audio = context.getSystemService(AudioManager::class.java)
        val focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            .setAudioAttributes(attributes)
            .build()
        val player = MediaPlayer()
        val finish = {
            player.release()
            audio.abandonAudioFocusRequest(focus)
            done()
        }
        try {
            player.setAudioAttributes(attributes)
            if (clip == PHONE) {
                player.setDataSource(context, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            } else {
                val id = context.resources.getIdentifier(clip, "raw", context.packageName)
                context.resources.openRawResourceFd(id).use {
                    player.setDataSource(it.fileDescriptor, it.startOffset, it.length)
                }
            }
            player.setOnCompletionListener { finish() }
            player.setOnErrorListener { _, _, _ ->
                finish()
                true
            }
            player.prepare()
            audio.requestAudioFocus(focus)
            player.start()
        } catch (error: Exception) {
            Log.e(TAG, "the clip can't play", error)
            finish()
        }
    }
}
