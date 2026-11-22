package com.elhawary.bettermuslim.adhan

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.content.res.AssetFileDescriptor
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
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
import android.provider.Settings
import android.util.Log
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.media.VolumeProviderCompat
import androidx.media.app.NotificationCompat.MediaStyle
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

    // do not disturb waits for the adhan to end or stop
    private var silenceUntil = 0L
    private var startedAt = 0L
    private var screenOnAt = 0L
    private var faceDownAt = 0L

    // flipping is turning it over, a phone already face down at the adhan's start has to come up first
    private var seenUp = false

    // the shade and the session only redraw when this changes
    private var shown: String? = null
    private val handler = Handler(Looper.getMainLooper())

    private val tick = object : Runnable {
        override fun run() {
            publish()
            handler.postDelayed(this, TICK_MILLIS)
        }
    }

    // media volume, the volume keys only reach the media session's stream while it plays
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
        shown = null
        silenceUntil = 0L
        startedAt = SystemClock.elapsedRealtime()
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
        if (audio.requestAudioFocus(request) != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) return failed("no audio focus")

        val media = try {
            MediaPlayer().apply {
                setAudioAttributes(attributes)
                setSource(this@AdhanService, next.getString("asset"))
                setWakeMode(this@AdhanService, PowerManager.PARTIAL_WAKE_LOCK)
                setOnCompletionListener { finished() }
                prepare()
                seekTo(fromMillis)
                setVolume(0f, 0f)
                start()
            }
        } catch (error: Exception) {
            Log.e(TAG, "the adhan can't play", error)
            return failed("no playback")
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
        if (AdhanAlarms.flipStops(this)) watchFlip()
        if (AdhanAlarms.buttonsStop(this)) watchButtons()
    }

    // face down for half a second stops it, the sensor runs only while it plays
    private fun watchFlip() {
        val sensors = getSystemService(SensorManager::class.java)
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return
        seenUp = false
        faceDownAt = 0L
        sensors.registerListener(flip, sensor, SensorManager.SENSOR_DELAY_NORMAL, handler)
    }

    private val flip = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            val z = event.values[2]
            if (z > -FACE_UP_Z) {
                seenUp = true
                faceDownAt = 0L
                return
            }
            if (!seenUp || z > -FACE_DOWN_Z) {
                faceDownAt = 0L
                return
            }
            val now = SystemClock.elapsedRealtime()
            if (faceDownAt == 0L) faceDownAt = now else if (now - faceDownAt >= FLIP_MILLIS) stop()
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    // the volume keys reach a remote session's volume instead of the stream's, so they stop it.
    // android only tells the power key through the screen going off or on
    private fun watchButtons() {
        session?.setPlaybackToRemote(object : VolumeProviderCompat(VOLUME_CONTROL_RELATIVE, 1, 1) {
            override fun onAdjustVolume(direction: Int) {
                if (direction != 0) stop()
            }
        })
        screenOnAt = 0L
        ContextCompat.registerReceiver(
            this,
            screen,
            IntentFilter(Intent.ACTION_SCREEN_ON).apply { addAction(Intent.ACTION_SCREEN_OFF) },
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    private val screen = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val now = SystemClock.elapsedRealtime()
            when (intent.action) {
                // the adhan's own notification can light the screen in its first moment
                Intent.ACTION_SCREEN_ON -> {
                    screenOnAt = now
                    if (now - startedAt > POWER_GRACE_MILLIS) stop()
                }
                // off sooner than the screen timeout is the power key, later it may be the timeout
                Intent.ACTION_SCREEN_OFF -> {
                    val timeout = Settings.System.getLong(contentResolver, Settings.System.SCREEN_OFF_TIMEOUT, 30_000L)
                    if (now - maxOf(startedAt, screenOnAt) < timeout) stop()
                }
            }
        }
    }

    // false when nothing plays, the receiver turns it on itself
    fun silenceAfter(until: Long): Boolean {
        if (player == null) return false
        silenceUntil = until
        return true
    }

    private fun silence() {
        if (silenceUntil > 0) Silence.start(this, silenceUntil)
        silenceUntil = 0L
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

    // the adhan screen is already open and nothing will ever end it, so it ends here
    private fun failed(reason: String) {
        Log.e(TAG, reason)
        entry?.let { emit(it.getInt("id"), playing = false, position = 0, duration = 0, ended = true) }
        stop()
    }

    // silent at once, the prayer stays to answer until it is marked (FR-026)
    private fun stop() {
        silence()
        release()
        stopForeground(STOP_FOREGROUND_REMOVE)
        leave()
        emit(null, playing = false, position = 0, duration = 0, ended = false)
        stopSelf()
    }

    // the media notification turns into the prayer's (FR-027)
    private fun finished() {
        val done = entry ?: return
        val duration = player?.duration ?: 0
        emit(done.getInt("id"), playing = false, position = duration, duration = duration, ended = true)
        silence()
        release()
        stopForeground(STOP_FOREGROUND_DETACH)
        leave()
        stopSelf()
    }

    private fun leave() {
        val done = entry ?: return
        if (marked) {
            NotificationManagerCompat.from(this).cancel(done.getInt("id"))
        } else {
            AdhanReceiver.postPrayer(this, done, quiet = true)
        }
    }

    fun markPrayed(id: Int) {
        if (entry?.getInt("id") != id) return
        marked = true
        publish()
    }

    private fun release() {
        handler.removeCallbacksAndMessages(null)
        getSystemService(SensorManager::class.java).unregisterListener(flip)
        try {
            unregisterReceiver(screen)
        } catch (_: IllegalArgumentException) {
            // buttons off, it was never registered
        }
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
        val state = "$playing $marked"
        if (state != shown) {
            shown = state
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
        }
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
        private const val TAG = "AdhanService"
        private const val TICK_MILLIS = 1000L
        private const val FADE_MILLIS = 1500L
        private const val FLIP_MILLIS = 500L
        private const val POWER_GRACE_MILLIS = 2000L

        // m/s², gravity is 9.8 on the screen's axis when it lies flat
        private const val FACE_DOWN_Z = 8f
        private const val FACE_UP_Z = 3f

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
                val path = asset.takeIf { it.startsWith("/") }
                if (path != null) {
                    retriever.setDataSource(path)
                } else {
                    openAsset(context, asset).use { retriever.setDataSource(it.fileDescriptor, it.startOffset, it.length) }
                }
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toInt() ?: 0
            } finally {
                retriever.release()
            }
        }

        // a downloaded recording is a path in the app's files, the rest are flutter assets
        private fun MediaPlayer.setSource(context: Context, asset: String) {
            if (asset.startsWith("/")) return setDataSource(asset)
            openAsset(context, asset).use { setDataSource(it.fileDescriptor, it.startOffset, it.length) }
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
