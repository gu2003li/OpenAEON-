package ai.openaeon.android.node

import ai.openaeon.android.protocol.OpenAEONCalendarCommand
import ai.openaeon.android.protocol.OpenAEONCanvasA2UICommand
import ai.openaeon.android.protocol.OpenAEONCanvasCommand
import ai.openaeon.android.protocol.OpenAEONCameraCommand
import ai.openaeon.android.protocol.OpenAEONCapability
import ai.openaeon.android.protocol.OpenAEONContactsCommand
import ai.openaeon.android.protocol.OpenAEONDeviceCommand
import ai.openaeon.android.protocol.OpenAEONLocationCommand
import ai.openaeon.android.protocol.OpenAEONMotionCommand
import ai.openaeon.android.protocol.OpenAEONNotificationsCommand
import ai.openaeon.android.protocol.OpenAEONPhotosCommand
import ai.openaeon.android.protocol.OpenAEONScreenCommand
import ai.openaeon.android.protocol.OpenAEONSmsCommand
import ai.openaeon.android.protocol.OpenAEONSystemCommand

data class NodeRuntimeFlags(
  val cameraEnabled: Boolean,
  val locationEnabled: Boolean,
  val smsAvailable: Boolean,
  val voiceWakeEnabled: Boolean,
  val motionActivityAvailable: Boolean,
  val motionPedometerAvailable: Boolean,
  val debugBuild: Boolean,
)

enum class InvokeCommandAvailability {
  Always,
  CameraEnabled,
  LocationEnabled,
  SmsAvailable,
  MotionActivityAvailable,
  MotionPedometerAvailable,
  DebugBuild,
}

enum class NodeCapabilityAvailability {
  Always,
  CameraEnabled,
  LocationEnabled,
  SmsAvailable,
  VoiceWakeEnabled,
  MotionAvailable,
}

data class NodeCapabilitySpec(
  val name: String,
  val availability: NodeCapabilityAvailability = NodeCapabilityAvailability.Always,
)

data class InvokeCommandSpec(
  val name: String,
  val requiresForeground: Boolean = false,
  val availability: InvokeCommandAvailability = InvokeCommandAvailability.Always,
)

object InvokeCommandRegistry {
  val capabilityManifest: List<NodeCapabilitySpec> =
    listOf(
      NodeCapabilitySpec(name = OpenAEONCapability.Canvas.rawValue),
      NodeCapabilitySpec(name = OpenAEONCapability.Screen.rawValue),
      NodeCapabilitySpec(name = OpenAEONCapability.Device.rawValue),
      NodeCapabilitySpec(name = OpenAEONCapability.Notifications.rawValue),
      NodeCapabilitySpec(name = OpenAEONCapability.System.rawValue),
      NodeCapabilitySpec(name = OpenAEONCapability.AppUpdate.rawValue),
      NodeCapabilitySpec(
        name = OpenAEONCapability.Camera.rawValue,
        availability = NodeCapabilityAvailability.CameraEnabled,
      ),
      NodeCapabilitySpec(
        name = OpenAEONCapability.Sms.rawValue,
        availability = NodeCapabilityAvailability.SmsAvailable,
      ),
      NodeCapabilitySpec(
        name = OpenAEONCapability.VoiceWake.rawValue,
        availability = NodeCapabilityAvailability.VoiceWakeEnabled,
      ),
      NodeCapabilitySpec(
        name = OpenAEONCapability.Location.rawValue,
        availability = NodeCapabilityAvailability.LocationEnabled,
      ),
      NodeCapabilitySpec(name = OpenAEONCapability.Photos.rawValue),
      NodeCapabilitySpec(name = OpenAEONCapability.Contacts.rawValue),
      NodeCapabilitySpec(name = OpenAEONCapability.Calendar.rawValue),
      NodeCapabilitySpec(
        name = OpenAEONCapability.Motion.rawValue,
        availability = NodeCapabilityAvailability.MotionAvailable,
      ),
    )

  val all: List<InvokeCommandSpec> =
    listOf(
      InvokeCommandSpec(
        name = OpenAEONCanvasCommand.Present.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = OpenAEONCanvasCommand.Hide.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = OpenAEONCanvasCommand.Navigate.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = OpenAEONCanvasCommand.Eval.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = OpenAEONCanvasCommand.Snapshot.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = OpenAEONCanvasA2UICommand.Push.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = OpenAEONCanvasA2UICommand.PushJSONL.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = OpenAEONCanvasA2UICommand.Reset.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = OpenAEONScreenCommand.Record.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = OpenAEONSystemCommand.Notify.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONCameraCommand.List.rawValue,
        requiresForeground = true,
        availability = InvokeCommandAvailability.CameraEnabled,
      ),
      InvokeCommandSpec(
        name = OpenAEONCameraCommand.Snap.rawValue,
        requiresForeground = true,
        availability = InvokeCommandAvailability.CameraEnabled,
      ),
      InvokeCommandSpec(
        name = OpenAEONCameraCommand.Clip.rawValue,
        requiresForeground = true,
        availability = InvokeCommandAvailability.CameraEnabled,
      ),
      InvokeCommandSpec(
        name = OpenAEONLocationCommand.Get.rawValue,
        availability = InvokeCommandAvailability.LocationEnabled,
      ),
      InvokeCommandSpec(
        name = OpenAEONDeviceCommand.Status.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONDeviceCommand.Info.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONDeviceCommand.Permissions.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONDeviceCommand.Health.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONNotificationsCommand.List.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONNotificationsCommand.Actions.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONPhotosCommand.Latest.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONContactsCommand.Search.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONContactsCommand.Add.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONCalendarCommand.Events.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONCalendarCommand.Add.rawValue,
      ),
      InvokeCommandSpec(
        name = OpenAEONMotionCommand.Activity.rawValue,
        availability = InvokeCommandAvailability.MotionActivityAvailable,
      ),
      InvokeCommandSpec(
        name = OpenAEONMotionCommand.Pedometer.rawValue,
        availability = InvokeCommandAvailability.MotionPedometerAvailable,
      ),
      InvokeCommandSpec(
        name = OpenAEONSmsCommand.Send.rawValue,
        availability = InvokeCommandAvailability.SmsAvailable,
      ),
      InvokeCommandSpec(
        name = "debug.logs",
        availability = InvokeCommandAvailability.DebugBuild,
      ),
      InvokeCommandSpec(
        name = "debug.ed25519",
        availability = InvokeCommandAvailability.DebugBuild,
      ),
      InvokeCommandSpec(name = "app.update"),
    )

  private val byNameInternal: Map<String, InvokeCommandSpec> = all.associateBy { it.name }

  fun find(command: String): InvokeCommandSpec? = byNameInternal[command]

  fun advertisedCapabilities(flags: NodeRuntimeFlags): List<String> {
    return capabilityManifest
      .filter { spec ->
        when (spec.availability) {
          NodeCapabilityAvailability.Always -> true
          NodeCapabilityAvailability.CameraEnabled -> flags.cameraEnabled
          NodeCapabilityAvailability.LocationEnabled -> flags.locationEnabled
          NodeCapabilityAvailability.SmsAvailable -> flags.smsAvailable
          NodeCapabilityAvailability.VoiceWakeEnabled -> flags.voiceWakeEnabled
          NodeCapabilityAvailability.MotionAvailable -> flags.motionActivityAvailable || flags.motionPedometerAvailable
        }
      }
      .map { it.name }
  }

  fun advertisedCommands(flags: NodeRuntimeFlags): List<String> {
    return all
      .filter { spec ->
        when (spec.availability) {
          InvokeCommandAvailability.Always -> true
          InvokeCommandAvailability.CameraEnabled -> flags.cameraEnabled
          InvokeCommandAvailability.LocationEnabled -> flags.locationEnabled
          InvokeCommandAvailability.SmsAvailable -> flags.smsAvailable
          InvokeCommandAvailability.MotionActivityAvailable -> flags.motionActivityAvailable
          InvokeCommandAvailability.MotionPedometerAvailable -> flags.motionPedometerAvailable
          InvokeCommandAvailability.DebugBuild -> flags.debugBuild
        }
      }
      .map { it.name }
  }
}
