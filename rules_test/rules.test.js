// Tests of firestore.rules on the local Firestore emulator (demo project,
// nothing reaches taskenda21). Run with `npm test` in this folder.

import { readFileSync } from "node:fs";
import { after, before, beforeEach, describe, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  setLogLevel,
  updateDoc,
} from "firebase/firestore";

const ALICE = "alice"; // has encryption keys
const BOB = "bob"; // has encryption keys, collaborator of Alice
const CAROL = "carol"; // no keys (encryption off or skipped)
const EVE = "eve"; // stranger

const blob = (c = "cipher") => ({ n: "nonce", c });
const encrypted = (extra = {}) => ({ e: 1, enc: blob(), ...extra });

let env;

// Denied writes are the point of most tests: keep the SDK quiet about them.
setLogLevel("silent");

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-taskenda",
    firestore: {
      rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8"),
    },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `users/${ALICE}/crypto/keys`), { v: 2 });
    await setDoc(doc(db, `users/${BOB}/crypto/keys`), { v: 2 });
    // Encrypted note of Alice shared with Bob.
    await setDoc(doc(db, `users/${ALICE}/notes/shared`), {
      ...encrypted(),
      priv: blob("priv"),
      keys: { [ALICE]: blob(), [BOB]: blob() },
      keyVer: 1,
      collaborators: [BOB],
      collaboratorProfiles: { [BOB]: { name: "Bob" } },
    });
    // Note in clear of Carol shared with Bob.
    await setDoc(doc(db, `users/${CAROL}/notes/plain`), {
      title: "Hi",
      content: "text",
      isPinned: false,
      collaborators: [BOB],
      collaboratorProfiles: { [BOB]: { name: "Bob" } },
    });
  });
});

const as = (uid, email) =>
  env.authenticatedContext(uid, email ? { email } : {}).firestore();

describe("own data", () => {
  test("a user with keys can't write in clear in an encrypted collection", async () => {
    for (const col of ["notes", "tasks", "calendar_events", "labels", "task_lists",
      "shared_note_prefs", "shared_task_prefs", "shared_event_prefs"]) {
      await assertFails(setDoc(doc(as(ALICE), `users/${ALICE}/${col}/x`), { title: "t" }));
    }
  });

  test("a user with keys can write encrypted documents", async () => {
    await assertSucceeds(setDoc(doc(as(ALICE), `users/${ALICE}/notes/x`), encrypted()));
  });

  test("a user with keys can't turn an encrypted document back into clear", async () => {
    await assertFails(updateDoc(doc(as(ALICE), `users/${ALICE}/notes/shared`), { e: 0 }));
    await assertFails(setDoc(doc(as(ALICE), `users/${ALICE}/notes/shared`), { title: "t" }));
  });

  test("`e` = 1 without an `enc` map is refused", async () => {
    await assertFails(setDoc(doc(as(ALICE), `users/${ALICE}/notes/x`), { e: 1, enc: "x" }));
  });

  test("a user without keys writes in clear", async () => {
    await assertSucceeds(setDoc(doc(as(CAROL), `users/${CAROL}/notes/x`), { title: "t" }));
    await assertSucceeds(setDoc(doc(as(CAROL), `users/${CAROL}/tasks/x`), { title: "t" }));
  });

  test("collections outside encryption accept documents in clear", async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), `users/${ALICE}/settings/preferences`), { values: {} }),
    );
    await assertSucceeds(setDoc(doc(as(ALICE), `users/${ALICE}/fcm_tokens/t`), { lang: "it" }));
  });

  test("the owner reads and deletes their documents, nobody else does", async () => {
    await assertSucceeds(getDoc(doc(as(ALICE), `users/${ALICE}/notes/shared`)));
    await assertSucceeds(deleteDoc(doc(as(ALICE), `users/${ALICE}/notes/shared`)));
    await assertFails(getDoc(doc(as(EVE), `users/${CAROL}/notes/plain`)));
    await assertFails(setDoc(doc(as(EVE), `users/${ALICE}/notes/x`), encrypted()));
    await assertFails(getDoc(doc(as(EVE), `users/${ALICE}/crypto/keys`)));
  });

  test("signed out, nothing is readable", async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `users/${ALICE}/notes/shared`)));
  });
});

describe("collaborators, encrypted item", () => {
  const note = () => doc(as(BOB), `users/${ALICE}/notes/shared`);

  test("read it", async () => {
    await assertSucceeds(getDoc(note()));
  });

  test("change `enc` and `updatedAt`", async () => {
    await assertSucceeds(updateDoc(note(), { enc: blob("new"), updatedAt: "now" }));
  });

  test("never `priv`, `keys`, `keyVer`, `e` or the members", async () => {
    await assertFails(updateDoc(note(), { priv: blob("z") }));
    await assertFails(updateDoc(note(), { [`keys.${BOB}`]: blob("z") }));
    await assertFails(updateDoc(note(), { enc: blob("new"), keyVer: 2 }));
    await assertFails(updateDoc(note(), { e: 0, title: "t" }));
    await assertFails(updateDoc(note(), { collaborators: [BOB, EVE] }));
  });

  test("never the fields in clear", async () => {
    await assertFails(updateDoc(note(), { title: "t" }));
  });

  test("leave it", async () => {
    await assertSucceeds(updateDoc(note(), { collaborators: [], collaboratorProfiles: {} }));
  });

  test("can't remove someone else", async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `users/${ALICE}/notes/shared`), {
        collaborators: [BOB, EVE],
        collaboratorProfiles: { [BOB]: { name: "Bob" }, [EVE]: { name: "Eve" } },
      }));
    await assertFails(updateDoc(note(), {
      collaborators: [BOB],
      collaboratorProfiles: { [BOB]: { name: "Bob" } },
    }));
  });

  test("can't delete it", async () => {
    await assertFails(deleteDoc(note()));
  });

  test("a stranger can't read it", async () => {
    await assertFails(getDoc(doc(as(EVE), `users/${ALICE}/notes/shared`)));
  });
});

describe("collaborators, item in clear", () => {
  const note = () => doc(as(BOB), `users/${CAROL}/notes/plain`);

  test("change the shared content", async () => {
    await assertSucceeds(updateDoc(note(), { title: "New", content: "x", updatedAt: "now" }));
  });

  test("never the owner's personal fields", async () => {
    await assertFails(updateDoc(note(), { isPinned: true }));
  });

  test("leave it", async () => {
    await assertSucceeds(updateDoc(note(), { collaborators: [], collaboratorProfiles: {} }));
  });

  test("shared task and event keys", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      const base = { collaborators: [BOB], collaboratorProfiles: {} };
      await setDoc(doc(db, `users/${CAROL}/tasks/t`), { title: "T", ...base });
      await setDoc(doc(db, `users/${CAROL}/calendar_events/c`), { title: "C", ...base });
    });
    await assertSucceeds(updateDoc(doc(as(BOB), `users/${CAROL}/tasks/t`), {
      isCompleted: true,
      subtasks: [],
    }));
    await assertFails(updateDoc(doc(as(BOB), `users/${CAROL}/tasks/t`), { listId: "l" }));
    await assertSucceeds(updateDoc(doc(as(BOB), `users/${CAROL}/calendar_events/c`), {
      startTime: "s",
      recurrenceWeekdays: [1],
    }));
    await assertFails(
      updateDoc(doc(as(BOB), `users/${CAROL}/calendar_events/c`), { alertSameDay: true }),
    );
  });
});

describe("public keys and user directory", () => {
  test("public keys: anyone signed in reads one, only the owner writes", async () => {
    await assertSucceeds(setDoc(doc(as(ALICE), `public_keys/${ALICE}`), { pk: "x" }));
    await assertSucceeds(getDoc(doc(as(EVE), `public_keys/${ALICE}`)));
    await assertFails(setDoc(doc(as(EVE), `public_keys/${ALICE}`), { pk: "y" }));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), `public_keys/${ALICE}`)));
  });

  test("directory: own lowercase email only", async () => {
    const db = as(ALICE, "Alice@Example.com");
    await assertSucceeds(setDoc(doc(db, "user_directory/alice@example.com"), { uid: ALICE }));
    await assertFails(setDoc(doc(db, "user_directory/bob@example.com"), { uid: ALICE }));
    await assertFails(setDoc(doc(db, "user_directory/alice@example.com"), { uid: EVE }));
    await assertSucceeds(getDoc(doc(as(EVE), "user_directory/alice@example.com")));
  });

  test("everything else is denied", async () => {
    await assertFails(setDoc(doc(as(ALICE), "other/x"), { a: 1 }));
  });
});
