//
// MisiCopy — Live Activity push relay (Cloudflare Worker)
// --------------------------------------------------------
// Receives a small JSON payload from the Mac app and forwards it to Apple
// Push Notification service as a Live Activity update, signing the request
// with an APNs auth key (.p8) that NEVER leaves this Worker.
//
// The Mac POSTs to https://<worker>/push with:
//   {
//     "token":        "<hex apns push token from the iPhone>",
//     "event":        "update" | "end",
//     "contentState": { status, progress, copiedCount, failedCount,
//                       currentFile, bytesPerSecond, etaSeconds },
//     "staleDate":    <unix seconds, optional>,
//     "dismissalDate":<unix seconds, optional, only for "end">,
//     "priority":     5 | 10
//   }
//
// Secrets (set with `wrangler secret put`):
//   APNS_KEY        – the full .p8 PEM contents (BEGIN/END PRIVATE KEY)
//   APNS_KEY_ID     – the 10-char Key ID from developer.apple.com
//   APNS_TEAM_ID    – your Apple Team ID (SM6L2XLUBA)
//   APNS_BUNDLE_ID  – fr.misilab.MisiCopyRemote
//
// APNs host: production (api.push.apple.com). TestFlight + App Store builds
// use production. If a token is a sandbox token (Xcode debug build) APNs
// returns BadDeviceToken on prod — we transparently retry sandbox.
//

const APNS_HOST_PROD = "https://api.push.apple.com";
const APNS_HOST_SANDBOX = "https://api.sandbox.push.apple.com";

// Cached APNs bearer JWT — APNs requires reuse for 20-60 min and rejects
// tokens regenerated too often. The isolate stays warm between requests,
// so this survives across calls until it ages out.
let cachedJWT = null;
let cachedJWTAt = 0;

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Method Not Allowed", { status: 405 });
    }
    const url = new URL(request.url);
    if (url.pathname !== "/push") {
      return new Response("Not Found", { status: 404 });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "invalid JSON" }, 400);
    }

    const { token, event, contentState, staleDate, dismissalDate, priority, alert } = body;
    if (!token || !event || !contentState) {
      return json({ error: "missing token / event / contentState" }, 400);
    }

    let jwt;
    try {
      jwt = await getJWT(env);
    } catch (e) {
      return json({ error: "jwt signing failed", detail: String(e) }, 500);
    }

    // Build the APNs Live Activity payload.
    const aps = {
      timestamp: Math.floor(Date.now() / 1000),
      event,
      "content-state": contentState,
    };
    if (staleDate) aps["stale-date"] = staleDate;
    if (event === "end" && dismissalDate) aps["dismissal-date"] = dismissalDate;
    // Attaching an alert makes iOS show a real banner + sound on the lock
    // screen when the copy ends — works even while the app is suspended.
    // `alert` = { title, body }.
    if (alert && alert.title) {
      aps.alert = { title: alert.title, body: alert.body || "" };
      aps.sound = "default";
    }
    const payload = JSON.stringify({ aps });

    const topic = `${env.APNS_BUNDLE_ID}.push-type.liveactivity`;
    const headers = {
      authorization: `bearer ${jwt}`,
      "apns-topic": topic,
      "apns-push-type": "liveactivity",
      "apns-priority": String(priority === 10 ? 10 : 5),
      "apns-expiration": String(staleDate || 0),
      "content-type": "application/json",
    };

    // Try production first; fall back to sandbox on a token-environment
    // mismatch so Xcode debug builds keep working during development.
    let res = await sendAPNs(APNS_HOST_PROD, token, headers, payload);
    if (res.status === 400) {
      const reason = (res.body && res.body.reason) || "";
      if (reason === "BadDeviceToken" || reason === "TopicDisallowed") {
        res = await sendAPNs(APNS_HOST_SANDBOX, token, headers, payload);
      }
    }

    return json(
      { ok: res.status === 200, apnsStatus: res.status, apns: res.body },
      res.status === 200 ? 200 : 502
    );
  },
};

async function sendAPNs(host, token, headers, payload) {
  const resp = await fetch(`${host}/3/device/${token}`, {
    method: "POST",
    headers,
    body: payload,
  });
  let parsed = null;
  const text = await resp.text();
  if (text) {
    try { parsed = JSON.parse(text); } catch { parsed = { raw: text }; }
  }
  return { status: resp.status, body: parsed };
}

// ── APNs bearer JWT (ES256) ──────────────────────────────────────────────

async function getJWT(env) {
  const now = Math.floor(Date.now() / 1000);
  // Reuse for 30 min (APNs allows up to 60; refresh well before).
  if (cachedJWT && now - cachedJWTAt < 1800) return cachedJWT;

  const header = { alg: "ES256", kid: env.APNS_KEY_ID };
  const claims = { iss: env.APNS_TEAM_ID, iat: now };
  const signingInput =
    base64url(JSON.stringify(header)) + "." + base64url(JSON.stringify(claims));

  const key = await importPrivateKey(env.APNS_KEY);
  const sig = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput)
  );
  const jwt = signingInput + "." + base64urlBytes(new Uint8Array(sig));
  cachedJWT = jwt;
  cachedJWTAt = now;
  return jwt;
}

async function importPrivateKey(pem) {
  // Strip PEM armour + whitespace, base64-decode to DER (PKCS#8).
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    der.buffer,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );
}

// ── helpers ──────────────────────────────────────────────────────────────

function base64url(str) {
  return base64urlBytes(new TextEncoder().encode(str));
}

function base64urlBytes(bytes) {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json" },
  });
}
