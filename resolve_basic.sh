#!/bin/bash
git checkout --ours extensions/feishu/src/bot.ts
git checkout --ours apps/macos/Sources/OpenAEON/GeneralSettings.swift
git checkout --ours apps/macos/Sources/OpenAEON/OnboardingView+Pages.swift
git checkout --ours apps/macos/Sources/OpenAEON/SystemRunSettingsView.swift
git checkout --ours apps/shared/OpenAEONKit/Sources/OpenAEONChatUI/ChatMessageViews.swift
git checkout --ours apps/macos/Sources/OpenAEON/AnthropicAuthControls.swift
git rm scripts/bundle-a2ui.sh 2>/dev/null
git add apps/ extensions/ scripts/
