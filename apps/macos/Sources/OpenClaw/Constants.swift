import Foundation

// Stable identifier used for both the macOS LaunchAgent label and Nix-managed defaults suite.
// nix-openaeon writes app defaults into this suite to survive app bundle identifier churn.
let launchdLabel = "ai.openaeon.mac"
let gatewayLaunchdLabel = "ai.openaeon.gateway"
let onboardingVersionKey = "openaeon.onboardingVersion"
let onboardingSeenKey = "openaeon.onboardingSeen"
let currentOnboardingVersion = 7
let pauseDefaultsKey = "openaeon.pauseEnabled"
let iconAnimationsEnabledKey = "openaeon.iconAnimationsEnabled"
let swabbleEnabledKey = "openaeon.swabbleEnabled"
let swabbleTriggersKey = "openaeon.swabbleTriggers"
let voiceWakeTriggerChimeKey = "openaeon.voiceWakeTriggerChime"
let voiceWakeSendChimeKey = "openaeon.voiceWakeSendChime"
let showDockIconKey = "openaeon.showDockIcon"
let defaultVoiceWakeTriggers = ["openaeon"]
let voiceWakeMaxWords = 32
let voiceWakeMaxWordLength = 64
let voiceWakeMicKey = "openaeon.voiceWakeMicID"
let voiceWakeMicNameKey = "openaeon.voiceWakeMicName"
let voiceWakeLocaleKey = "openaeon.voiceWakeLocaleID"
let voiceWakeAdditionalLocalesKey = "openaeon.voiceWakeAdditionalLocaleIDs"
let voicePushToTalkEnabledKey = "openaeon.voicePushToTalkEnabled"
let talkEnabledKey = "openaeon.talkEnabled"
let iconOverrideKey = "openaeon.iconOverride"
let connectionModeKey = "openaeon.connectionMode"
let remoteTargetKey = "openaeon.remoteTarget"
let remoteIdentityKey = "openaeon.remoteIdentity"
let remoteProjectRootKey = "openaeon.remoteProjectRoot"
let remoteCliPathKey = "openaeon.remoteCliPath"
let canvasEnabledKey = "openaeon.canvasEnabled"
let cameraEnabledKey = "openaeon.cameraEnabled"
let systemRunPolicyKey = "openaeon.systemRunPolicy"
let systemRunAllowlistKey = "openaeon.systemRunAllowlist"
let systemRunEnabledKey = "openaeon.systemRunEnabled"
let locationModeKey = "openaeon.locationMode"
let locationPreciseKey = "openaeon.locationPreciseEnabled"
let peekabooBridgeEnabledKey = "openaeon.peekabooBridgeEnabled"
let deepLinkKeyKey = "openaeon.deepLinkKey"
let modelCatalogPathKey = "openaeon.modelCatalogPath"
let modelCatalogReloadKey = "openaeon.modelCatalogReload"
let cliInstallPromptedVersionKey = "openaeon.cliInstallPromptedVersion"
let heartbeatsEnabledKey = "openaeon.heartbeatsEnabled"
let debugPaneEnabledKey = "openaeon.debugPaneEnabled"
let debugFileLogEnabledKey = "openaeon.debug.fileLogEnabled"
let appLogLevelKey = "openaeon.debug.appLogLevel"
let voiceWakeSupported: Bool = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26
