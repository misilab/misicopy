# MisiCopy — Live Activity push relay setup

The lock-screen Live Activity ticks in real time **only** when the Mac can
push updates to Apple through this relay. The relay is a tiny Cloudflare
Worker that holds the APNs auth key (`.p8`) so the key never ships inside
the publicly-distributed Mac app.

Do this once. ~15 minutes.

## 1. Create an APNs Auth Key

1. Go to https://developer.apple.com/account/resources/authkeys/list
2. **+** → name it `MisiCopy Push` → enable **Apple Push Notifications service (APNs)** → Continue → Register
3. **Download** the `AuthKey_XXXXXXXXXX.p8` file (you can only download it once — keep it safe)
4. Note the **Key ID** (the 10 characters in the filename, `XXXXXXXXXX`)
5. Your **Team ID** is `SM6L2XLUBA` (already in `wrangler.toml`)

## 2. Deploy the Worker

```bash
cd scripts/cloudflare-worker

# First time only — installs the Cloudflare CLI and logs you in
npm install -g wrangler
wrangler login

# Push the two secrets (the .p8 contents + the Key ID)
cat ~/Downloads/AuthKey_XXXXXXXXXX.p8 | wrangler secret put APNS_KEY
wrangler secret put APNS_KEY_ID      # paste the 10-char Key ID when prompted

# Deploy
wrangler deploy
```

`wrangler deploy` prints the public URL, e.g.:

```
https://misicopy-push.apple-591.workers.dev
```

## 3. Point the Mac app at the Worker

If your deployed URL is **not** `https://misicopy-push.apple-591.workers.dev`,
edit the constant in `MisiCopy/Engine/LiveActivityPushRelay.swift`:

```swift
static let workerURL = URL(string: "https://<your-worker-url>/push")!
```

Then rebuild + ship the Mac app (`bash scripts/release.sh`).

## 4. Test it

1. Run a copy on the Mac with the iPhone paired (MisiCopy → Réglages → iPhone ON).
2. On the iPhone, open MisiCopy Remote so the Live Activity starts (you'll
   see the tile on the lock screen).
3. Lock the iPhone. The progress bar should keep advancing in real time.

Quick manual smoke test of the Worker (replace the token with a real one
from the Mac log):

```bash
curl -X POST https://misicopy-push.apple-591.workers.dev/push \
  -H 'content-type: application/json' \
  -d '{"token":"<hexToken>","event":"update","priority":5,
       "contentState":{"status":"running","progress":0.5,"copiedCount":10,
       "failedCount":0,"currentFile":"A001.mxf","bytesPerSecond":120000000,
       "etaSeconds":42}}'
```

A `200` with `{"ok":true,"apnsStatus":200}` means the push reached Apple.

## How it fits together

```
iPhone starts Live Activity (pushType: .token)
   │  APNs mints a push token
   ▼
iPhone → Mac   (RemoteClientMessage.liveActivityToken over the local channel)
   ▼
Mac every ~1.5s → Worker   (POST /push  { token, content-state })
   ▼
Worker signs ES256 JWT with the .p8 → api.push.apple.com
   ▼
APNs wakes the lock-screen tile — no need to wake the iPhone app
```

## Notes

- **Local channel required for the handoff**: the iPhone delivers its push
  token to the Mac over Wi-Fi. They must be on the same network at least at
  the moment the Live Activity starts. After that, APNs reaches the iPhone
  anywhere (cellular included).
- **Cost**: Cloudflare's free tier covers 100k Worker requests/day — far
  beyond what a DIT plateau generates (~40 pushes/min during a copy).
- **Security**: the `.p8` lives only as a Cloudflare secret. The Worker URL
  is public but carries no credentials and only relays well-formed pushes.
