# iOS Deploy Pipeline

Push to `main` → TestFlight beta. Tag `v1.0.0` → App Store submission. That's it.

---

## One-time setup (do this once, never again)

### Step 1 - Create an App Store Connect API Key

1. Go to [App Store Connect → Users & Access → Integrations → API Keys](https://appstoreconnect.apple.com/access/api)
2. Create a key with **App Manager** role
3. Download the `.p8` file (you can only download it once)
4. Note: **Key ID** and **Issuer ID**

### Step 2 - Create a private Match repo

Fastlane Match stores your certificates encrypted in a private git repo.

```bash
# Create a new private repo on GitHub - call it "ios-certs" or similar
# Then init it
```

Go to github.com/new → Private repo → name it `ios-certs` (or anything you want)

Generate a Personal Access Token with `repo` scope:
- GitHub → Settings → Developer Settings → Personal Access Tokens → Fine-grained
- Give it `Contents: Read and Write` on your certs repo

### Step 3 - Run Match for the first time (on your Mac)

```bash
cd LLMChat
bundle install

# Set your env vars locally
export APPLE_TEAM_ID="XXXXXXXXXX"          # 10-char team ID from developer.apple.com
export MATCH_GIT_URL="https://github.com/mathew-simpson/ios-certs"
export MATCH_GIT_AUTH=$(echo -n "mathew-simpson:your_pat" | base64)
export MATCH_PASSWORD="a strong password to encrypt the certs"
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ASC_KEY_CONTENT=$(cat ~/Downloads/AuthKey_XXXXXXXXXX.p8)

# Generate and store certificates
bundle exec fastlane match appstore --readonly false
```

This uploads your cert and profile to the private repo, encrypted.

### Step 4 - Set GitHub Secrets

Go to your repo → Settings → Secrets and Variables → Actions → New repository secret

| Secret name | Value |
|-------------|-------|
| `APPLE_TEAM_ID` | Your 10-char team ID |
| `ASC_KEY_ID` | Key ID from Step 1 |
| `ASC_ISSUER_ID` | Issuer ID from Step 1 |
| `ASC_KEY_CONTENT` | Base64 of the .p8 file: `base64 -i AuthKey_XXX.p8 \| tr -d '\n'` |
| `MATCH_GIT_URL` | URL of your ios-certs repo |
| `MATCH_GIT_AUTH` | `echo -n "username:PAT" \| base64` |
| `MATCH_PASSWORD` | The password you used in Step 3 |

### Step 5 - Update bundle ID

Edit `fastlane/Fastfile` and `fastlane/Appfile`:
```ruby
APP_IDENTIFIER = "com.yourdomain.llmchat"  # ← change this
```

Also update in Xcode: Target → Signing & Capabilities → Bundle Identifier

---

## Day-to-day usage

### Auto (just push)

```bash
git push origin main   # → TestFlight beta in ~10 minutes
```

### Release to App Store

```bash
git tag v1.0.0
git push origin v1.0.0  # → submits for App Store review
```

### Manual trigger

GitHub → Actions → iOS Deploy → Run workflow → pick beta or release

### Register a new test device

```bash
bundle exec fastlane register_device name:"Someone's iPhone" udid:"DEVICE_UDID"
```

---

## What happens in CI

1. Checkout code
2. Set up Ruby + install Fastlane via Bundler
3. Write ASC API key from secrets
4. Detect lane (beta or release) from trigger
5. Run `fastlane beta` or `fastlane release`:
   - Sync certs/profiles from Match repo
   - Build with `gym` (xcodebuild under the hood)
   - Upload to TestFlight with `pilot` / submit to App Store with `deliver`
6. Archive IPA as GitHub Actions artifact (kept 30 days)

---

## Troubleshooting

**"No profiles found"**
- Run Match locally with `--readonly false` to regenerate profiles

**"Invalid signature"**
- Re-run Match: `bundle exec fastlane match appstore --force`

**Build fails on Xcode version**
- Update the `xcode-select` line in the workflow to match the installed version on the runner

**"Two-factor authentication required"**
- You're using Apple ID login instead of API key. Make sure `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_CONTENT` are all set correctly.
