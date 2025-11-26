# Github Actions Sandbox

macOS app with automated release workflow using GitHub Actions.

## Release Process Setup

This project uses a GitHub Actions workflow (`.github/workflows/release.yml`) to automate the release process including building, signing, notarizing, and distributing the macOS app.

### What the Workflow Does

1. Builds and archives the Xcode project
2. Signs the app with Developer ID certificate
3. Notarizes the app with Apple
4. Creates a signed DMG
5. Creates a GitHub Release with the DMG
6. Updates the Sparkle appcast.xml for auto-updates

### Prerequisites

- Apple Developer Program membership
- Developer ID Application certificate
- App-specific password for notarization
- Sparkle framework integrated in your app

### Required GitHub Secrets

Configure these secrets in your repository settings (Settings > Secrets and variables > Actions):

| Secret | Description |
|--------|-------------|
| `CERTIFICATE_BASE64` | Base64-encoded Developer ID Application certificate (.p12) |
| `CERTIFICATE_PASSWORD` | Password for the .p12 certificate |
| `KEYCHAIN_PASSWORD` | Any password for the temporary keychain (can be random) |
| `DEVELOPMENT_TEAM` | Your Apple Developer Team ID (10-character string) |
| `APPLE_ID` | Your Apple ID email for notarization |
| `APPLE_ID_PASSWORD` | App-specific password for notarization |
| `SPARKLE_PRIVATE_KEY` | EdDSA private key for Sparkle updates |

### Setting Up Secrets

#### 1. Export Developer ID Certificate

```bash
# In Keychain Access:
# 1. Find "Developer ID Application: Your Name (TEAM_ID)"
# 2. Right-click > Export
# 3. Save as .p12 with a password

# Convert to base64
base64 -i certificate.p12 | pbcopy
# Paste as CERTIFICATE_BASE64 secret
```

#### 2. Create App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in and go to Security > App-Specific Passwords
3. Generate a new password for "GitHub Actions"
4. Use this as `APPLE_ID_PASSWORD`

#### 3. Generate Sparkle EdDSA Key

```bash
# Download Sparkle and use generate_keys tool
curl -L -o sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.8.1/Sparkle-2.8.1.tar.xz
tar -xf sparkle.tar.xz
./bin/generate_keys

# This outputs:
# - Private key (save as SPARKLE_PRIVATE_KEY secret)
# - Public key (add to your app's Info.plist as SUPublicEDKey)
```

If private key has been added directly into keychain, then run this to find it:

```bash
security find-generic-password -s "https://sparkle-project.org" -a "ed25519" -w
```


#### 4. Find Your Team ID

```bash
# List available signing identities
security find-identity -v -p codesigning

# Team ID is the 10-character code in parentheses
# Example: "Developer ID Application: Your Name (ABC123XYZ0)"
#                                               ^^^^^^^^^^
```

### Appcast Setup for Sparkle

Create `docs/appcast.xml` with the following structure:

```xml
<?xml version="1.0" encoding="utf-8" ?>
<rss
    version="2.0"
    xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
>
    <channel>
        <title>Your App Updates</title>
        <link>https://github.com/your-org/your-repo</link>
        <description>Most recent updates to Your App</description>
        <language>en</language>

        <!-- new first -->

    </channel>
</rss>
```

The `<!-- new first -->` comment is required - the workflow inserts new releases after this marker.

### DMG Background Image

Place your DMG background image at `Assets/background@2x.png`. This image will be used as the background in the DMG installer window.

### Triggering a Release

#### Option 1: Push a Version Tag

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow triggers on tags matching `v*` pattern.

#### Option 2: Manual Dispatch

1. Go to Actions tab in GitHub
2. Select "Release macOS App" workflow
3. Click "Run workflow"
4. Optionally enter a version number

### Customizing the Workflow

Update the environment variables in `release.yml` to match your project:

```yaml
env:
  SCHEME: "Your App Scheme"
  PROJECT: "Your App.xcodeproj"
  PRODUCT_NAME: "Your App"
  DMG_BACKGROUND_FILE_NAME: "Assets/background@2x.png"
```

### Workflow Requirements

- **Runner**: `macos-26` (macOS with Xcode 26.1)
- **Xcode versioning**: Project must use `agvtool` for version management
  - Enable in Build Settings: Versioning System = Apple Generic
- **DMG creation**: Uses [dmgs](https://github.com/velocityzen/dmgs) tool
- **Auto-updates**: Uses [Sparkle](https://sparkle-project.org/) framework

### Troubleshooting

#### Certificate Issues
- Ensure the certificate is a "Developer ID Application" certificate (not Mac App Store)
- Verify the certificate hasn't expired
- Check that the base64 encoding doesn't have line breaks

#### Notarization Failures
- Verify the app-specific password is correct
- Ensure hardened runtime is enabled in Xcode
- Check that all frameworks and helpers are signed

#### Sparkle Signature Issues
- Verify the private key matches the public key in your app's Info.plist
- Ensure `SUPublicEDKey` is set in Info.plist

## Additional Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle Sandboxing Guide](https://sparkle-project.org/documentation/sandboxing/)
