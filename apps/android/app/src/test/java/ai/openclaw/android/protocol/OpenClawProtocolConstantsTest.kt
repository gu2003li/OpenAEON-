package ai.openaeon.android.protocol

import org.junit.Assert.assertEquals
import org.junit.Test

class OpenAEONProtocolConstantsTest {
  @Test
  fun canvasCommandsUseStableStrings() {
    assertEquals("canvas.present", OpenAEONCanvasCommand.Present.rawValue)
    assertEquals("canvas.hide", OpenAEONCanvasCommand.Hide.rawValue)
    assertEquals("canvas.navigate", OpenAEONCanvasCommand.Navigate.rawValue)
    assertEquals("canvas.eval", OpenAEONCanvasCommand.Eval.rawValue)
    assertEquals("canvas.snapshot", OpenAEONCanvasCommand.Snapshot.rawValue)
  }

  @Test
  fun a2uiCommandsUseStableStrings() {
    assertEquals("canvas.a2ui.push", OpenAEONCanvasA2UICommand.Push.rawValue)
    assertEquals("canvas.a2ui.pushJSONL", OpenAEONCanvasA2UICommand.PushJSONL.rawValue)
    assertEquals("canvas.a2ui.reset", OpenAEONCanvasA2UICommand.Reset.rawValue)
  }

  @Test
  fun capabilitiesUseStableStrings() {
    assertEquals("canvas", OpenAEONCapability.Canvas.rawValue)
    assertEquals("camera", OpenAEONCapability.Camera.rawValue)
    assertEquals("screen", OpenAEONCapability.Screen.rawValue)
    assertEquals("voiceWake", OpenAEONCapability.VoiceWake.rawValue)
    assertEquals("location", OpenAEONCapability.Location.rawValue)
    assertEquals("sms", OpenAEONCapability.Sms.rawValue)
    assertEquals("device", OpenAEONCapability.Device.rawValue)
    assertEquals("notifications", OpenAEONCapability.Notifications.rawValue)
    assertEquals("system", OpenAEONCapability.System.rawValue)
    assertEquals("appUpdate", OpenAEONCapability.AppUpdate.rawValue)
    assertEquals("photos", OpenAEONCapability.Photos.rawValue)
    assertEquals("contacts", OpenAEONCapability.Contacts.rawValue)
    assertEquals("calendar", OpenAEONCapability.Calendar.rawValue)
    assertEquals("motion", OpenAEONCapability.Motion.rawValue)
  }

  @Test
  fun cameraCommandsUseStableStrings() {
    assertEquals("camera.list", OpenAEONCameraCommand.List.rawValue)
    assertEquals("camera.snap", OpenAEONCameraCommand.Snap.rawValue)
    assertEquals("camera.clip", OpenAEONCameraCommand.Clip.rawValue)
  }

  @Test
  fun screenCommandsUseStableStrings() {
    assertEquals("screen.record", OpenAEONScreenCommand.Record.rawValue)
  }

  @Test
  fun notificationsCommandsUseStableStrings() {
    assertEquals("notifications.list", OpenAEONNotificationsCommand.List.rawValue)
    assertEquals("notifications.actions", OpenAEONNotificationsCommand.Actions.rawValue)
  }

  @Test
  fun deviceCommandsUseStableStrings() {
    assertEquals("device.status", OpenAEONDeviceCommand.Status.rawValue)
    assertEquals("device.info", OpenAEONDeviceCommand.Info.rawValue)
    assertEquals("device.permissions", OpenAEONDeviceCommand.Permissions.rawValue)
    assertEquals("device.health", OpenAEONDeviceCommand.Health.rawValue)
  }

  @Test
  fun systemCommandsUseStableStrings() {
    assertEquals("system.notify", OpenAEONSystemCommand.Notify.rawValue)
  }

  @Test
  fun photosCommandsUseStableStrings() {
    assertEquals("photos.latest", OpenAEONPhotosCommand.Latest.rawValue)
  }

  @Test
  fun contactsCommandsUseStableStrings() {
    assertEquals("contacts.search", OpenAEONContactsCommand.Search.rawValue)
    assertEquals("contacts.add", OpenAEONContactsCommand.Add.rawValue)
  }

  @Test
  fun calendarCommandsUseStableStrings() {
    assertEquals("calendar.events", OpenAEONCalendarCommand.Events.rawValue)
    assertEquals("calendar.add", OpenAEONCalendarCommand.Add.rawValue)
  }

  @Test
  fun motionCommandsUseStableStrings() {
    assertEquals("motion.activity", OpenAEONMotionCommand.Activity.rawValue)
    assertEquals("motion.pedometer", OpenAEONMotionCommand.Pedometer.rawValue)
  }
}
