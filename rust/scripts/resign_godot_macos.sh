#!/bin/sh

cat > /tmp/editor.entitlements <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist 
  PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>com.apple.security.cs.allow-dyld-environment-variables</key>
        <true/>
        <key>com.apple.security.cs.allow-jit</key>
        <true/>
        <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
        <true/>
        <key>com.apple.security.cs.disable-executable-page-protection</key>
        <true/>
        <key>com.apple.security.cs.disable-library-validation</key>
        <true/>
        <key>com.apple.security.device.audio-input</key>
        <true/>
        <key>com.apple.security.device.camera</key>
        <true/>
        <key>com.apple.security.get-task-allow</key>
        <true/>
    </dict>
</plist>
EOF

codesign -s - --deep --force --options=runtime \
    --entitlements /tmp/editor.entitlements /Applications/Godot_mono.app