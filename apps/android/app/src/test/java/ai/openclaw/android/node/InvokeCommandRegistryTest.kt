package ai.openaeon.android.node

import ai.openaeon.android.protocol.OpenAEONCalendarCommand
import ai.openaeon.android.protocol.OpenAEONCameraCommand
import ai.openaeon.android.protocol.OpenAEONCapability
import ai.openaeon.android.protocol.OpenAEONContactsCommand
import ai.openaeon.android.protocol.OpenAEONDeviceCommand
import ai.openaeon.android.protocol.OpenAEONLocationCommand
import ai.openaeon.android.protocol.OpenAEONMotionCommand
import ai.openaeon.android.protocol.OpenAEONNotificationsCommand
import ai.openaeon.android.protocol.OpenAEONPhotosCommand
import ai.openaeon.android.protocol.OpenAEONSmsCommand
import ai.openaeon.android.protocol.OpenAEONSystemCommand
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class InvokeCommandRegistryTest {
  @Test
  fun advertisedCapabilities_respectsFeatureAvailability() {
    val capabilities =
      InvokeCommandRegistry.advertisedCapabilities(
        NodeRuntimeFlags(
          cameraEnabled = false,
          locationEnabled = false,
          smsAvailable = false,
          voiceWakeEnabled = false,
          motionActivityAvailable = false,
          motionPedometerAvailable = false,
          debugBuild = false,
        ),
      )

    assertTrue(capabilities.contains(OpenAEONCapability.Canvas.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Screen.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Device.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Notifications.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.System.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.AppUpdate.rawValue))
    assertFalse(capabilities.contains(OpenAEONCapability.Camera.rawValue))
    assertFalse(capabilities.contains(OpenAEONCapability.Location.rawValue))
    assertFalse(capabilities.contains(OpenAEONCapability.Sms.rawValue))
    assertFalse(capabilities.contains(OpenAEONCapability.VoiceWake.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Photos.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Contacts.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Calendar.rawValue))
    assertFalse(capabilities.contains(OpenAEONCapability.Motion.rawValue))
  }

  @Test
  fun advertisedCapabilities_includesFeatureCapabilitiesWhenEnabled() {
    val capabilities =
      InvokeCommandRegistry.advertisedCapabilities(
        NodeRuntimeFlags(
          cameraEnabled = true,
          locationEnabled = true,
          smsAvailable = true,
          voiceWakeEnabled = true,
          motionActivityAvailable = true,
          motionPedometerAvailable = true,
          debugBuild = false,
        ),
      )

    assertTrue(capabilities.contains(OpenAEONCapability.Canvas.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Screen.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Device.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Notifications.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.System.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.AppUpdate.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Camera.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Location.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Sms.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.VoiceWake.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Photos.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Contacts.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Calendar.rawValue))
    assertTrue(capabilities.contains(OpenAEONCapability.Motion.rawValue))
  }

  @Test
  fun advertisedCommands_respectsFeatureAvailability() {
    val commands =
      InvokeCommandRegistry.advertisedCommands(
        NodeRuntimeFlags(
          cameraEnabled = false,
          locationEnabled = false,
          smsAvailable = false,
          voiceWakeEnabled = false,
          motionActivityAvailable = false,
          motionPedometerAvailable = false,
          debugBuild = false,
        ),
      )

    assertFalse(commands.contains(OpenAEONCameraCommand.Snap.rawValue))
    assertFalse(commands.contains(OpenAEONCameraCommand.Clip.rawValue))
    assertFalse(commands.contains(OpenAEONCameraCommand.List.rawValue))
    assertFalse(commands.contains(OpenAEONLocationCommand.Get.rawValue))
    assertTrue(commands.contains(OpenAEONDeviceCommand.Status.rawValue))
    assertTrue(commands.contains(OpenAEONDeviceCommand.Info.rawValue))
    assertTrue(commands.contains(OpenAEONDeviceCommand.Permissions.rawValue))
    assertTrue(commands.contains(OpenAEONDeviceCommand.Health.rawValue))
    assertTrue(commands.contains(OpenAEONNotificationsCommand.List.rawValue))
    assertTrue(commands.contains(OpenAEONNotificationsCommand.Actions.rawValue))
    assertTrue(commands.contains(OpenAEONSystemCommand.Notify.rawValue))
    assertTrue(commands.contains(OpenAEONPhotosCommand.Latest.rawValue))
    assertTrue(commands.contains(OpenAEONContactsCommand.Search.rawValue))
    assertTrue(commands.contains(OpenAEONContactsCommand.Add.rawValue))
    assertTrue(commands.contains(OpenAEONCalendarCommand.Events.rawValue))
    assertTrue(commands.contains(OpenAEONCalendarCommand.Add.rawValue))
    assertFalse(commands.contains(OpenAEONMotionCommand.Activity.rawValue))
    assertFalse(commands.contains(OpenAEONMotionCommand.Pedometer.rawValue))
    assertFalse(commands.contains(OpenAEONSmsCommand.Send.rawValue))
    assertFalse(commands.contains("debug.logs"))
    assertFalse(commands.contains("debug.ed25519"))
    assertTrue(commands.contains("app.update"))
  }

  @Test
  fun advertisedCommands_includesFeatureCommandsWhenEnabled() {
    val commands =
      InvokeCommandRegistry.advertisedCommands(
        NodeRuntimeFlags(
          cameraEnabled = true,
          locationEnabled = true,
          smsAvailable = true,
          voiceWakeEnabled = false,
          motionActivityAvailable = true,
          motionPedometerAvailable = true,
          debugBuild = true,
        ),
      )

    assertTrue(commands.contains(OpenAEONCameraCommand.Snap.rawValue))
    assertTrue(commands.contains(OpenAEONCameraCommand.Clip.rawValue))
    assertTrue(commands.contains(OpenAEONCameraCommand.List.rawValue))
    assertTrue(commands.contains(OpenAEONLocationCommand.Get.rawValue))
    assertTrue(commands.contains(OpenAEONDeviceCommand.Status.rawValue))
    assertTrue(commands.contains(OpenAEONDeviceCommand.Info.rawValue))
    assertTrue(commands.contains(OpenAEONDeviceCommand.Permissions.rawValue))
    assertTrue(commands.contains(OpenAEONDeviceCommand.Health.rawValue))
    assertTrue(commands.contains(OpenAEONNotificationsCommand.List.rawValue))
    assertTrue(commands.contains(OpenAEONNotificationsCommand.Actions.rawValue))
    assertTrue(commands.contains(OpenAEONSystemCommand.Notify.rawValue))
    assertTrue(commands.contains(OpenAEONPhotosCommand.Latest.rawValue))
    assertTrue(commands.contains(OpenAEONContactsCommand.Search.rawValue))
    assertTrue(commands.contains(OpenAEONContactsCommand.Add.rawValue))
    assertTrue(commands.contains(OpenAEONCalendarCommand.Events.rawValue))
    assertTrue(commands.contains(OpenAEONCalendarCommand.Add.rawValue))
    assertTrue(commands.contains(OpenAEONMotionCommand.Activity.rawValue))
    assertTrue(commands.contains(OpenAEONMotionCommand.Pedometer.rawValue))
    assertTrue(commands.contains(OpenAEONSmsCommand.Send.rawValue))
    assertTrue(commands.contains("debug.logs"))
    assertTrue(commands.contains("debug.ed25519"))
    assertTrue(commands.contains("app.update"))
  }

  @Test
  fun advertisedCommands_onlyIncludesSupportedMotionCommands() {
    val commands =
      InvokeCommandRegistry.advertisedCommands(
        NodeRuntimeFlags(
          cameraEnabled = false,
          locationEnabled = false,
          smsAvailable = false,
          voiceWakeEnabled = false,
          motionActivityAvailable = true,
          motionPedometerAvailable = false,
          debugBuild = false,
        ),
      )

    assertTrue(commands.contains(OpenAEONMotionCommand.Activity.rawValue))
    assertFalse(commands.contains(OpenAEONMotionCommand.Pedometer.rawValue))
  }
}
