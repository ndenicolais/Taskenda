// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Push notifications for sharing: when the owner adds collaborators to a
// note, task or event (users/{ownerId}/<collection>/{itemId}), every device
// of each new collaborator (users/{uid}/fcm_tokens, saved by the app's
// PushMessaging) gets a message in the language stored with its token.
// Tokens rejected by FCM are deleted. The content of the items is
// end-to-end encrypted, so the message never carries it: only the owner's
// name (in clear on shared items) and a generic text.
//
// searchPlaces: place suggestions for the event location field, from the
// Google Places API (New) Autocomplete. The API key stays here, in the
// PLACES_API_KEY secret, and never ships in the app.

const {setGlobalOptions} = require("firebase-functions/v2");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {logger} = require("firebase-functions");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

// Firestore is in eur3: run every function in Europe, next to the data.
setGlobalOptions({region: "europe-west1"});

initializeApp();

// Collection → NotificationTarget type in the app.
const KINDS = {notes: "note", tasks: "task", calendar_events: "event"};

const TEXTS = {
  it: {
    note: (who) => `${who} ha condiviso una nota con te`,
    task: (who) => `${who} ha condiviso un task con te`,
    event: (who) => `${who} ha condiviso un evento con te`,
    someone: "Qualcuno",
    open: "Tocca per aprirlo in Taskenda",
  },
  en: {
    note: (who) => `${who} shared a note with you`,
    task: (who) => `${who} shared a task with you`,
    event: (who) => `${who} shared an event with you`,
    someone: "Someone",
    open: "Tap to open it in Taskenda",
  },
};

// Same as NotificationService.sharedChannelId in the app.
const CHANNEL_ID = "taskenda_shared_notes";

// FCM errors meaning the token will never work again.
const DEAD_TOKEN_ERRORS = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

/** Notifies the collaborators added by this write of a [collection] item. */
async function notifyNewCollaborators(collection, event) {
  const {itemId} = event.params;
  const kind = KINDS[collection];
  const after = event.data?.after?.data();
  if (!after || after.deletedAt) return;
  const before = event.data?.before?.data() ?? {};
  const previous = new Set(before.collaborators ?? []);
  const added = (after.collaborators ?? []).filter((uid) => !previous.has(uid));
  if (added.length === 0) return;

  const ownerName = after.owner?.name || after.owner?.email || "";
  const db = getFirestore();

  await Promise.all(added.map(async (uid) => {
    const tokensSnap = await db.collection(`users/${uid}/fcm_tokens`).get();
    if (tokensSnap.empty) return;
    const byLang = new Map();
    for (const doc of tokensSnap.docs) {
      const lang = doc.get("lang") === "it" ? "it" : "en";
      if (!byLang.has(lang)) byLang.set(lang, []);
      byLang.get(lang).push(doc);
    }
    for (const [lang, docs] of byLang) {
      const t = TEXTS[lang];
      const response = await getMessaging().sendEachForMulticast({
        tokens: docs.map((d) => d.id),
        notification: {
          title: t[kind](ownerName || t.someone),
          body: t.open,
        },
        data: {type: kind, id: itemId},
        android: {
          priority: "high",
          notification: {channelId: CHANNEL_ID, icon: "ic_notification"},
        },
      });
      const dead = [];
      response.responses.forEach((r, i) => {
        if (!r.success && DEAD_TOKEN_ERRORS.has(r.error?.code)) {
          dead.push(docs[i].ref.delete());
        }
      });
      await Promise.all(dead);
      logger.info("Share push sent", {
        kind, sent: response.successCount, failed: response.failureCount,
      });
    }
  }));
}

// One trigger per shareable collection, so writes to labels, prefs or
// tokens don't run the function.
for (const [collection, name] of [
  ["notes", "notifyNoteCollaborators"],
  ["tasks", "notifyTaskCollaborators"],
  ["calendar_events", "notifyEventCollaborators"],
]) {
  exports[name] = onDocumentWritten(
    `users/{ownerId}/${collection}/{itemId}`,
    (event) => notifyNewCollaborators(collection, event),
  );
}

// ─── Place search ────────────────────────────────────────────────────────────

const PLACES_API_KEY = defineSecret("PLACES_API_KEY");
const AUTOCOMPLETE_URL = "https://places.googleapis.com/v1/places:autocomplete";

/** Up to 5 suggestion texts for [body], [] on any API error. */
async function autocomplete(body) {
  const response = await fetch(AUTOCOMPLETE_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": PLACES_API_KEY.value(),
      "X-Goog-FieldMask": "suggestions.placePrediction.text.text",
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    logger.warn("Places autocomplete failed", {status: response.status});
    return [];
  }
  const json = await response.json();
  return (json.suggestions ?? [])
      .map((s) => s.placePrediction?.text?.text)
      .filter((t) => typeof t === "string")
      .slice(0, 5);
}

// Signed-in users only. Called from the app over plain HTTPS with the
// Firebase ID token (callable protocol): data = {query, language, region}.
// Without coordinates Google would bias by the caller's IP, which here is
// the function's: results are restricted to the device's country first,
// and searched worldwide only when that finds nothing.
exports.searchPlaces = onCall(
    {secrets: [PLACES_API_KEY], maxInstances: 5, memory: "256MiB"},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required");
      }
      const query = String(request.data?.query ?? "").trim();
      if (query.length < 3 || query.length > 200) return {results: []};
      const language = /^[a-z]{2}$/.test(request.data?.language) ?
        request.data.language : "en";
      const region = /^[A-Z]{2}$/.test(request.data?.region) ?
        request.data.region : null;

      const base = {input: query, languageCode: language};
      let results = [];
      if (region) {
        results = await autocomplete({
          ...base,
          regionCode: region,
          includedRegionCodes: [region],
        });
      }
      if (results.length === 0) results = await autocomplete(base);
      return {results};
    },
);
