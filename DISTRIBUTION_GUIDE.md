# 🚀 BabyLock for macOS — Public Distribution & Certification Guide

This guide explains how macOS distribution works, why keyboard locker utilities use **Direct Distribution (Notarization)** rather than the Mac App Store, how to get certified by Apple, and where to publish the app so you receive full credit as the creator.

---

## 🏛️ 1. Mac App Store vs. Direct Distribution (The Technical Reality)

### Why BabyLock Cannot Be On the Mac App Store
Apple enforces strict **App Sandboxing** (`com.apple.security.app-sandbox = true`) on all Mac App Store submissions:
* **Sandboxed apps are forbidden from intercepting system-wide keyboard events** (`CGEvent.tapCreate` outside their own windows).
* **Sandboxed apps cannot suppress system shortcuts** like `⌘+Tab`, `⌘+Space`, or lock other applications.
* Apple Review Guideline **2.4.5** explicitly prohibits apps that take control of system input or escape the sandbox.

> [!NOTE]
> This is why all top-tier Mac utilities in this category — including **Karabiner-Elements** (keyboard remapper), **Rectangle / Spectacle** (window managers), **Maccy** (clipboard manager), and **Alfred** — are distributed directly via **Apple-Notarized DMG installers**, not the Mac App Store.

### The Official Alternative: Apple Notarization (Direct Distribution)
Apple provides an official distribution channel called **Developer ID & Notarization**:
1. You sign the app with your Apple Developer ID.
2. Apple's Notary service automatedly scans and certifies the binary.
3. macOS Gatekeeper verifies the Apple certification ticket.
4. Users double-click the DMG and install with **zero warnings**.

---

## 🌟 2. Best Platforms to Publish (To Showcase Your Work)

Here is where developers publish their Mac apps so people know who built them:

### A. GitHub Releases (Recommended #1)
* **Why**: GitHub is the premier portfolio platform for developers. You get:
  * Full developer attribution as the creator.
  * Download count badges.
  * GitHub Stars and community issues/feedback.
* **How to publish**:
  1. Create a repository on GitHub (e.g., `github.com/shaoor/BabyLock`).
  2. Push this folder to the repository.
  3. Go to **Releases** → **Draft a new release**.
  4. Tag: `v1.0.0`, Title: `BabyLock v1.0.0 — Sensory Keyboard Lock for Mac`.
  5. Drag and drop `BabyLock-1.0.0.dmg` into the release binaries.
  6. Click **Publish release**!

### B. Homebrew Cask (`brew install --cask babylock`)
* **Why**: Homebrew is the most popular package manager on macOS. Millions of Mac users install tools using `brew install`.
* **How to publish**:
  Once your DMG is on GitHub Releases:
  1. Fork `homebrew/homebrew-cask` on GitHub.
  2. Create `Casks/b/babylock.rb`:
     ```ruby
     cask "babylock" do
       version "1.0.0"
       sha256 "SHA256_OF_YOUR_DMG"

       url "https://github.com/shaoor/BabyLock/releases/download/v#{version}/BabyLock-#{version}.dmg"
       name "BabyLock"
       desc "Zero-leak toddler keyboard and mouse lock for macOS"
       homepage "https://github.com/shaoor/BabyLock"

       app "BabyLock.app"
     end
     ```
  3. Submit a Pull Request. Once merged, anyone can install via:
     ```bash
     brew install --cask babylock
     ```

### C. Product Hunt & Hacker News (Launch Days)
* Create a launch post on [ProductHunt.com](https://www.producthunt.com).
* Great for getting initial thousands of parents and toddler caregivers to discover your app.

### D. Mac Software Directories
* **AlternativeTo**: List BabyLock as a free macOS alternative to BabySmash.
* **MacUpdate**: Free utility listing.

---

## 🔏 3. Apple Certification & Notarization (Step-by-Step)

If you have or want an **Apple Developer Account** ($99/year), here is how to notarize:

### Step 1: Get Your Signing Certificate
1. Enroll at [developer.apple.com](https://developer.apple.com).
2. Open **Xcode** → **Settings** → **Accounts**.
3. Under **Manage Certificates**, create a **Developer ID Application** certificate.
4. Verify your identity in Terminal:
   ```bash
   security find-identity -p codesigning -v
   ```
   You will see an entry like:
   `"Developer ID Application: Your Name (TEAM_ID)"`

### Step 2: Store an App Store Connect App Password
Create an app-specific password at [appleid.apple.com](https://appleid.apple.com):
```bash
xcrun notarytool store-credentials "BabyLockProfile" \
    --apple-id "your-email@example.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "your-app-specific-password"
```

### Step 3: Run the Notarization Script
We have included a ready-to-run script:
```bash
./notarize.sh "Developer ID Application: Your Name (YOUR_TEAM_ID)" "your-email@example.com" "YOUR_TEAM_ID"
```

The script automatically:
1. Builds the release binary.
2. Applies hardened runtime and entitlements.
3. Signs `BabyLock.app` and `BabyLock-1.0.0.dmg`.
4. Submits to Apple Notary Service.
5. Staples the Apple ticket to the `.dmg`.

---

## 🆓 4. Free Distribution (Without Paying Apple $99/Year)

You can distribute `BabyLock-1.0.0.dmg` immediately for **$0**!

The app is already pre-configured with ad-hoc code signing and full entitlements.
* Upload `BabyLock-1.0.0.dmg` directly to GitHub Releases or your website.
* When users first open the app, macOS may display:
  *"BabyLock cannot be opened because the developer cannot be verified."*
* **How users open it once**:
  1. Right-click (or Control-click) `BabyLock.app` in `/Applications` → click **Open** → click **Open**.
  2. Or open **System Settings → Privacy & Security** → click **Open Anyway**.
* Once opened once, macOS remembers it forever!

---

## 📦 5. Assets Included in this Project

| Asset | Location |
|-------|----------|
| **Installer DMG** | [BabyLock-1.0.0.dmg](file:///Users/shaoor/Downloads/CodeProjects/myMACApps/babyLockKeyboardAppForMac/BabyLock-1.0.0.dmg) (2.4 MB) |
| **App Bundle** | [BabyLock.app](file:///Users/shaoor/Downloads/CodeProjects/myMACApps/babyLockKeyboardAppForMac/BabyLock.app) |
| **App Icon** | [Resources/AppIcon.icns](file:///Users/shaoor/Downloads/CodeProjects/myMACApps/babyLockKeyboardAppForMac/Resources/AppIcon.icns) |
| **DMG Packager** | [package_dmg.sh](file:///Users/shaoor/Downloads/CodeProjects/myMACApps/babyLockKeyboardAppForMac/package_dmg.sh) |
| **Apple Notarizer** | [notarize.sh](file:///Users/shaoor/Downloads/CodeProjects/myMACApps/babyLockKeyboardAppForMac/notarize.sh) |
| **Entitlements** | [Resources/BabyLock.entitlements](file:///Users/shaoor/Downloads/CodeProjects/myMACApps/babyLockKeyboardAppForMac/Resources/BabyLock.entitlements) |
