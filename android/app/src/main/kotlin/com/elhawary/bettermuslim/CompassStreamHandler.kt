package com.elhawary.bettermuslim

import android.app.Activity
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.Surface
import io.flutter.plugin.common.EventChannel

/** the qibla's magnetic heading of the top of the screen, dart adds the declination
 * (contracts/compass-channel.md) */
class CompassStreamHandler(private val activity: Activity) :
    EventChannel.StreamHandler, SensorEventListener {
    private val sensors = activity.getSystemService(SensorManager::class.java)
    private val rotation = FloatArray(9)
    private val remapped = FloatArray(9)
    private val orientation = FloatArray(3)
    private var events: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        if (sensor == null) {
            events.success(null)
            return
        }
        this.events = events
        sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
    }

    override fun onCancel(arguments: Any?) {
        sensors.unregisterListener(this)
        events = null
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}

    override fun onSensorChanged(event: SensorEvent) {
        SensorManager.getRotationMatrixFromVector(rotation, event.values)
        // the sensor's axes follow the phone, the needle follows the screen as shown (R8)
        val (x, y) = when (displayRotation()) {
            Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
            Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
            Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
            else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
        }
        SensorManager.remapCoordinateSystem(rotation, x, y, remapped)
        SensorManager.getOrientation(remapped, orientation)
        val heading = (Math.toDegrees(orientation[0].toDouble()) + 360) % 360
        events?.success(mapOf("heading" to heading, "accuracy" to accuracy(event)))
    }

    /** values[4] is the heading accuracy in radians where the phone fills it (R9) */
    private fun accuracy(event: SensorEvent): Double {
        if (event.values.size > 4 && event.values[4] >= 0) {
            return Math.toDegrees(event.values[4].toDouble())
        }
        return when (event.accuracy) {
            SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> 15.0
            SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> 30.0
            SensorManager.SENSOR_STATUS_ACCURACY_LOW -> 45.0
            else -> -1.0
        }
    }

    @Suppress("DEPRECATION")
    private fun displayRotation(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display?.rotation ?: Surface.ROTATION_0
        } else {
            activity.windowManager.defaultDisplay.rotation
        }
}
