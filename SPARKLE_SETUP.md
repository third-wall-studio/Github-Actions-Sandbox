# Sparkle Auto-Updater Setup Guide

This guide explains how to set up automatic updates for your sandboxed macOS app using Sparkle and GitHub Actions.

## Prerequisites

1. An Apple Developer account with a valid Developer ID certificate
2. A GitHub repository for your project
3. Sparkle 2.x integrated into your project

## Step 1: Generate Sparkle Signing Keys

Sparkle uses EdDSA (Ed25519) signatures to verify that updates come from you.

### Generate Keys Locally

1. Download Sparkle CLI tools:
   ```bash
   curl -L -o sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.8.1/Sparkle-2.8.1.tar.xz
   tar -xf sparkle.tar.xz
   ```

2. Generate a key pair:
   ```bash
   ./sparkle/bin/generate_keys
   ```

3. This will output:
   - **Public key** (starts with `SUPublicEDKey`): Add this to your `Info.plist`
   - **Private key**: **KEEP THIS SECRET!** You'll add it to GitHub Secrets

### Add Public Key to Info.plist

Open `Info.plist` and uncomment/add the public key:

```xml
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
```

## Step 2: Configure Info.plist

Update the `SUFeedURL` in `Info.plist` to point to your hosted appcast.xml:

```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/appcast.xml</string>
```

Or if you're hosting it elsewhere:
```xml
<key>SUFeedURL</key>
<string>https://yourdomain.com/appcast.xml</string>
```

## Step 3: Set Up GitHub Secrets

You need to add several secrets to your GitHub repository for the automated build process.

Go to: **Settings → Secrets and variables → Actions → New repository secret**

### Required Secrets:

1. **`CERTIFICATE_P12`** - Your Developer ID Application certificate
   
   Export from Keychain:
   ```bash
   # Find your certificate in Keychain Access
   # Right-click → Export → Save as .p12
   # Then base64 encode it:
   base64 -i certificate.p12 | pbcopy
   # Paste into GitHub Secrets
   ```

2. **`CERTIFICATE_PASSWORD`** - Password you set when exporting the .p12

3. **`KEYCHAIN_PASSWORD`** - Any secure password (used temporarily during build)

4. **`TEAM_ID`** - Your Apple Developer Team ID (find in Apple Developer Portal)

5. **`APPLE_ID`** - Your Apple ID email for notarization

6. **`APPLE_ID_PASSWORD`** - App-specific password for notarization
   
   Generate at: https://appleid.apple.com/account/manage
   - Sign in → Security → App-Specific Passwords → Generate

7. **`SPARKLE_PRIVATE_KEY`** - The private key from `generate_keys`
   
   Format (just paste the entire key including header):
   ```
   -----BEGIN PRIVATE KEY-----
   YOUR_PRIVATE_KEY_HERE
   -----END PRIVATE KEY-----
   ```

## Step 4: Host Your Appcast

You have several options:

### Option A: GitHub Repository (Simple)
- Commit `appcast.xml` to your repo
- Use GitHub raw URL: `https://raw.githubusercontent.com/USERNAME/REPO/main/appcast.xml`
- Update manually after each release

### Option B: GitHub Pages (Recommended)
1. Enable GitHub Pages in repo settings
2. Put `appcast.xml` in the root or `docs/` folder
3. Use URL: `https://USERNAME.github.io/REPO/appcast.xml`
4. Can be updated automatically by workflow

### Option C: Custom Domain
- Host `appcast.xml` on your own server
- Point `SUFeedURL` to your domain

## Step 5: Update Your Xcode Project

1. **Add entitlements file:**
   - In Xcode, select your target
   - Build Settings → Code Signing Entitlements
   - Set to: `Github_Actions_Sandbox.entitlements`

2. **Add Info.plist:**
   - In your target settings
   - Info tab → Custom macOS Application Target Properties
   - Or Build Settings → Info.plist File → set to `Info.plist`

3. **Ensure sandbox is enabled:**
   - Signing & Capabilities tab
   - Add "App Sandbox" capability if not present
   - Enable "Outgoing Connections (Client)"

## Step 6: Create Your First Release

1. **Update version numbers:**
   - In Xcode, select your target
   - General tab:
     - Version: `1.0.0` (CFBundleShortVersionString)
     - Build: `1` (CFBundleVersion)

2. **Commit and push your code:**
   ```bash
   git add .
   git commit -m "Add Sparkle auto-updater"
   git push
   ```

3. **Create a version tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. **GitHub Actions will automatically:**
   - Build your app
   - Code sign it
   - Notarize it with Apple
   - Create a signed update package
   - Create a GitHub Release
   - Provide the XML snippet for appcast.xml

5. **Update appcast.xml:**
   - Copy the XML snippet from the release notes
   - Add it to your `appcast.xml` file
   - Commit and push

## Step 7: Testing Updates

### Test Locally First:

1. Build version 1.0.0 and install it
2. Create version 1.0.1 with higher build number
3. Point to a local appcast.xml for testing
4. Run the 1.0.0 app and check for updates

### Test the Full Workflow:

1. Install your v1.0.0 release
2. Create and push tag v1.0.1
3. Wait for GitHub Actions to build
4. Update appcast.xml with new release info
5. Run v1.0.0 and check "Check for Updates..."

## Releasing Future Updates

For each new version:

1. **Update version in Xcode** (bump version and/or build number)
2. **Commit changes:**
   ```bash
   git add .
   git commit -m "Version 1.0.1: Bug fixes"
   git push
   ```
3. **Tag the release:**
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```
4. **Wait for GitHub Actions** to complete
5. **Update appcast.xml** with the new entry (copy from release notes)
6. **Commit and push** the updated appcast.xml

## Troubleshooting

### "Updates Not Found"
- Check that `SUFeedURL` in Info.plist is correct
- Verify appcast.xml is accessible (open in browser)
- Check Xcode console for Sparkle logs

### "Invalid Signature"
- Ensure public key in Info.plist matches your private key
- Verify the signature in appcast.xml is correct
- Make sure you're signing with the same private key

### Notarization Fails
- Check Apple ID and app-specific password
- Verify Team ID is correct
- Ensure certificate is valid and not expired

### Build Fails in GitHub Actions
- Verify all secrets are set correctly
- Check that CERTIFICATE_P12 is base64 encoded properly
- Ensure Xcode project/workspace name matches in workflow

## Security Best Practices

1. **Never commit private keys** to your repository
2. **Use app-specific passwords** for Apple ID, not your main password
3. **Rotate certificates** before they expire
4. **Keep Sparkle updated** to get security fixes
5. **Use HTTPS** for appcast URLs

## Additional Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle Sandboxing Guide](https://sparkle-project.org/documentation/sandboxing/)
- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Apple Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

## Need Help?

If you run into issues:
1. Check the GitHub Actions logs for errors
2. Look at Xcode console when testing updates locally
3. Verify all configuration files are correct
4. Check that network entitlements are enabled
