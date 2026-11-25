// Runs the rules tests. Reuses a Firestore emulator already listening on the
// port of firebase.json (on Windows `emulators:exec` can leave it running):
// each run loads firestore.rules again and clears the data. Otherwise starts
// one with `firebase emulators:exec`.

import { spawnSync } from "node:child_process";
import { connect } from "node:net";

const HOST = "127.0.0.1";
const PORT = 8085; // emulators.firestore.port in firebase.json

const listening = await new Promise((resolve) => {
  const socket = connect(PORT, HOST);
  socket.once("connect", () => socket.end(() => resolve(true)));
  socket.once("error", () => resolve(false));
});

const options = { stdio: "inherit", shell: true };
const result = listening
  ? spawnSync("node --test", {
      ...options,
      env: { ...process.env, FIRESTORE_EMULATOR_HOST: `${HOST}:${PORT}` },
    })
  : spawnSync(
      'firebase emulators:exec --only firestore --project demo-taskenda "node --test"',
      options,
    );
process.exit(result.status ?? 1);
