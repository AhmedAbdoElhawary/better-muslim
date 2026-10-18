package com.elhawary.bettermuslim.adhan

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaMetadataRetriever
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.media.app.NotificationCompat.MediaStyle
import com.elhawary.bettermuslim.R
import io.flutter.FlutterInjector
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject

// the full adhan with the app closed, as a media notification (5.2). one adhan at a time
class AdhanService : Service() {
    private var entry: JSONObject? = null
    private var player: MediaPlayer? = null
    private var session: MediaSessionCompat? = null
    private var focus: AudioFocusRequest? = null
    private var marked = false
    private val handler = Handler(Looper.getMainLooper())

    private val tick = object : Runnable {
        override fun run() {
            publish()
            handler.postDelayed(this, TICK_MILLIS)
        }
    }

    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        current = this
    }

    override fun onDestroy() {
        release()
        current = null
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PAUSE -> pause()
            ACTION_RESUME -> resume()
            ACTION_STOP -> stop()
            ACTION_PLAY -> {
                val next = JSONObject(intent.getStringExtra(EXTRA_ENTRY)!!)
                if (player != null && entry?.getInt("id") == next.getInt("id")) {
                    // startForegroundService needs a startForeground every time, even for the same adhan
                    startInForeground()
                } else {
                    start(next, intent.getIntExtra(EXTRA_FROM, 0))
                }
            }
            else -> if (player == null) stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun start(next: JSONObject, fromMillis: Int) {
        release()
        entry = next
        marked = false
        session = MediaSessionCompat(this, "adhan").apply {
            setCallback(callback)
            isActive = true
        }
        startInForeground()

        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(attributes)
            .setOnAudioFocusChangeListener { change ->
                // a call or another app taking the audio stops the adhan, it never resumes by itself
                if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) stop()
            }
            .build()
        focus = request
        val audio = getSystemService(AudioManager::class.java)
        if (audio.requestAudioFocus(request) != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) return stop()

        val media = MediaPlayer().apply {
            setAudioAttributes(attributes)
            openAsset(this@AdhanService, next.getString("asset")).use {
                setDataSource(it.fileDescriptor, it.startOffset, it.length)
            }
            setWakeMode(this@AdhanService, PowerManager.PARTIAL_WAKE_LOCK)
            setOnCompletionListener { finished() }
            prepare()
            seekTo(fromMillis)
            setVolume(0f, 0f)
            start()
        }
        player = media
        session?.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, next.getString("mediaTitle"))
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, next.getString("mediaSubtitle"))
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, media.duration.toLong())
                .build(),
        )
        fadeIn(media)
        handler.post(tick)
    }

    // 0 to full over 1.5 s (FR-024)
    private fun fadeIn(media: MediaPlayer) {
        val startedAt = SystemClock.elapsedRealtime()
        handler.post(object : Runnable {
            override fun run() {
                if (player !== media) return
                val volume = ((SystemClock.elapsedRealtime() - startedAt) / FADE_MILLIS.toFloat()).coerceAtMost(1f)
                media.setVolume(volume, volume)
                if (volume < 1f) handler.postDelayed(this, 16)
            }
        })
    }

    private fun pause() {
        player?.takeIf { it.isPlaying }?.pause()
        publish()
    }

    private fun resume() {
        player?.takeIf { !it.isPlaying }?.start()
        publish()
    }

    // silent at once, and the notification goes with it (FR-026)
    private fun stop() {
        val id = entry?.getInt("id")
        release()
        stopForeground(STOP_FOREGROUND_REMOVE)
        if (id != null) NotificationManagerCompat.from(this).cancel(id)
        emit(null, playing = false, position = 0, duration = 0, ended = false)
        stopSelf()
    }

    // the media notification turns into the plain one, still with mark prayed (FR-027)
    private fun finished() {
        val done = entry ?: return
        val duration = player?.duration ?: 0
        emit(done.getInt("id"), playing = false, position = duration, duration = duration, ended = true)
        release()
        stopForeground(STOP_FOREGROUND_DETACH)
        AdhanReceiver.postPlain(this, done, markPrayed = !marked)
        stopSelf()
    }

    fun markPrayed(id: Int) {
        if (entry?.getInt("id") != id) return
        marked = true
        publish()
    }

    private fun release() {
        handler.removeCallbacksAndMessages(null)
        player?.release()
        player = null
        session?.release()
        session = null
        focus?.let { getSystemService(AudioManager::class.java).abandonAudioFocusRequest(it) }
        focus = null
    }

    private fun startInForeground() {
        val id = entry?.getInt("id") ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(id, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(id, notification())
        }
    }

    @SuppressLint("MissingPermission")
    private fun publish() {
        val current = entry ?: return
        val media = player ?: return
        val playing = media.isPlaying
        val actions = current.getJSONObject("actions")
        session?.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or PlaybackStateCompat.ACTION_PAUSE or
                        PlaybackStateCompat.ACTION_PLAY_PAUSE or PlaybackStateCompat.ACTION_STOP,
                )
                .setState(
                    if (playing) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED,
                    media.currentPosition.toLong(),
                    if (playing) 1f else 0f,
                )
                .apply {
                    // android 13+ draws the media controls from the session, not the notification
                    if (!marked) addCustomAction(CUSTOM_MARK, actions.getString("markPrayed"), R.drawable.ic_adhan_check)
                    addCustomAction(CUSTOM_STOP, actions.getString("stop"), R.drawable.ic_adhan_stop)
                }
                .build(),
        )
        val manager = NotificationManagerCompat.from(this)
        if (manager.areNotificationsEnabled()) manager.notify(current.getInt("id"), notification())
        emit(current.getInt("id"), playing, media.currentPosition, media.duration, ended = false)
    }

    private fun notification(): android.app.Notification {
        val current = entry!!
        val actions = current.getJSONObject("actions")
        val playing = player?.isPlaying ?: true
        val builder = NotificationCompat.Builder(this, current.getString("channel"))
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(this, R.color.notification_accent))
            .setContentTitle(current.getString("mediaTitle"))
            .setContentText(current.getString("mediaSubtitle"))
            .setSubText(current.getString("subText"))
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSilent(true)
            .setShowWhen(false)
            .setOngoing(playing)
            .setContentIntent(AdhanReceiver.openIntent(this, current))
            .setDeleteIntent(serviceIntent(ACTION_STOP))
        if (playing) {
            builder.addAction(R.drawable.ic_adhan_pause, actions.getString("pause"), serviceIntent(ACTION_PAUSE))
        } else {
            builder.addAction(R.drawable.ic_adhan_play, actions.getString("play"), serviceIntent(ACTION_RESUME))
        }
        if (!marked) {
            builder.addAction(R.drawable.ic_adhan_check, actions.getString("markPrayed"), MarkPrayedReceiver.intent(this, current))
        }
        builder.addAction(R.drawable.ic_adhan_stop, actions.getString("stop"), serviceIntent(ACTION_STOP))
        val style = MediaStyle().setShowActionsInCompactView(*IntArray(if (marked) 2 else 3) { it })
        session?.let { style.setMediaSession(it.sessionToken) }
        return builder.setStyle(style).build()
    }

    private fun serviceIntent(action: String): PendingIntent = PendingIntent.getService(
        this,
        action.hashCode(),
        Intent(this, AdhanService::class.java).setAction(action),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private val callback = object : MediaSessionCompat.Callback() {
        override fun onPlay() = resume()

        override fun onPause() = pause()

        override fun onStop() = stop()

        override fun onCustomAction(action: String, extras: android.os.Bundle?) {
            val current = entry ?: return
            when (action) {
                CUSTOM_MARK -> MarkPrayedReceiver.intent(this@AdhanService, current).send()
                CUSTOM_STOP -> stop()
            }
        }
    }

    companion object {
        private const val ACTION_PLAY = "com.elhawary.bettermuslim.adhan.PLAY"
        private const val ACTION_PAUSE = "com.elhawary.bettermuslim.adhan.PAUSE"
        private const val ACTION_RESUME = "com.elhawary.bettermuslim.adhan.RESUME"
        private const val ACTION_STOP = "com.elhawary.bettermuslim.adhan.STOP"
        private const val EXTRA_ENTRY = "entry"
        private const val EXTRA_FROM = "fromMillis"
        private const val CUSTOM_MARK = "mark_prayed"
        private const val CUSTOM_STOP = "stop"
        private const val TICK_MILLIS = 500L
        private const val FADE_MILLIS = 1500L

        var current: AdhanService? = null
            private set

        // set by MainActivity while the app listens, the screen and the shade show one playback
        var stateSink: EventChannel.EventSink? = null

        fun play(context: Context, entry: JSONObject, fromMillis: Int) {
            ContextCompat.startForegroundService(
                context,
                Intent(context, AdhanService::class.java)
                    .setAction(ACTION_PLAY)
                    .putExtra(EXTRA_ENTRY, entry.toString())
                    .putExtra(EXTRA_FROM, fromMillis),
            )
        }

        fun send(context: Context, action: String) {
            if (current == null) return
            context.startService(Intent(context, AdhanService::class.java).setAction(action))
        }

        fun pause(context: Context) = send(context, ACTION_PAUSE)

        fun resume(context: Context) = send(context, ACTION_RESUME)

        fun stop(context: Context) = send(context, ACTION_STOP)

        fun playingId(): Int? = current?.takeIf { it.player != null }?.entry?.getInt("id")

        fun publishNow() = current?.publish()

        fun length(context: Context, asset: String): Int {
            val retriever = MediaMetadataRetriever()
            return try {
                openAsset(context, asset).use { retriever.setDataSource(it.fileDescriptor, it.startOffset, it.length) }
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toInt() ?: 0
            } finally {
                retriever.release()
            }
        }

        // the flutter asset itself, so the audio file is in the app once
        private fun openAsset(context: Context, asset: String): AssetFileDescriptor {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context.applicationContext)
            return context.assets.openFd(loader.getLookupKeyForAsset(asset))
        }

        private fun emit(id: Int?, playing: Boolean, position: Int, duration: Int, ended: Boolean) {
            stateSink?.success(
                mapOf(
                    "id" to id,
                    "playing" to playing,
                    "positionMillis" to position,
                    "durationMillis" to duration,
                    "ended" to ended,
                ),
            )
        }
    }
}
