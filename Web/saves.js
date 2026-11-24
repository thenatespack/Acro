// Keeps a game's user data (save games, settings: `UserData` in Swift) in IndexedDB, so it
// survives reloads (docs/wasm-spike.md, wave W2.5A).
//
// The wasm reads and writes files synchronously in the WASI shim's in-memory filesystem, while
// IndexedDB is asynchronous. So:
// 1. Before the wasm starts, `openUserData()` reads every stored file into an in-memory folder,
//    which the loader mounts at /userdata (on WASI `UserData.directory(app:)` is /userdata/<app>).
// 2. After the engine writes or removes a user data file it calls `acro.onUserDataChange()`, and
//    `persist()` writes the folder's changes back: new and changed files are put, removed ones
//    deleted, in one transaction. It also runs when the page is hidden or closed.
//
// One record per file: key "<path under /userdata>", value the bytes. IndexedDB is per origin,
// and the <app> folder keeps different games on the same origin apart.
import { File, Directory } from "@bjorn3/browser_wasi_shim";

const databaseName = "acro-userdata";
const storeName = "files";

/**
 * Opens the user data store and loads it into a WASI directory.
 * @returns {Promise<{ directory: Directory, persist: () => Promise<void> }>} `directory` to mount
 *   at /userdata; `persist()` saves its changes (calls are serialized). Without IndexedDB (a
 *   private window in some browsers, blocked storage) the folder still works, for the session only.
 */
export async function openUserData() {
  const directory = new Directory(new Map());
  let database = null;
  try {
    database = await openDatabase();
  } catch (error) {
    console.warn(`[acro] saves are kept for this session only: IndexedDB is unavailable (${error})`);
  }
  // What IndexedDB holds, by path (the bytes as last written), to find what changed.
  const stored = new Map();
  if (database) {
    const records = await request(database.transaction(storeName).objectStore(storeName).getAll());
    for (const { path, data } of records) {
      put(directory, path, data);
      stored.set(path, data);
    }
    if (records.length) console.log(`[acro] user data: ${records.length} file(s) from IndexedDB`);
  }

  let pending = Promise.resolve();
  const persist = () => {
    pending = pending.then(() => save(database, directory, stored)).catch((error) => {
      console.error(`[acro] couldn't save user data to IndexedDB: ${error}`);
    });
    return pending;
  };
  const flush = () => { persist(); };
  addEventListener("pagehide", flush);
  addEventListener("visibilitychange", () => { if (document.visibilityState === "hidden") flush(); });
  return { directory, persist };
}

/** Writes the changes in `directory` since `stored` to the database, and updates `stored`. */
async function save(database, directory, stored) {
  const current = new Map();
  collect(directory, "", current);
  const puts = [], deletes = [];
  for (const [path, data] of current) {
    const old = stored.get(path);
    if (!old || !equal(old, data)) puts.push([path, data.slice()]);
  }
  for (const path of stored.keys()) if (!current.has(path)) deletes.push(path);
  if (!puts.length && !deletes.length) return;
  if (database) {
    const transaction = database.transaction(storeName, "readwrite");
    const store = transaction.objectStore(storeName);
    for (const [path, data] of puts) store.put({ path, data });
    for (const path of deletes) store.delete(path);
    await done(transaction);
  }
  for (const [path, data] of puts) stored.set(path, data);
  for (const path of deletes) stored.delete(path);
}

function openDatabase() {
  if (!globalThis.indexedDB) return Promise.reject(new Error("no indexedDB"));
  const open = indexedDB.open(databaseName, 1);
  open.onupgradeneeded = () => open.result.createObjectStore(storeName, { keyPath: "path" });
  return request(open);
}

/** Every file under `folder` into `out`, by path relative to the root. Temporary files of
 *  unfinished atomic writes (".<name>.tmp-<uuid>") are left out. */
function collect(folder, prefix, out) {
  for (const [name, entry] of folder.contents) {
    const path = prefix + name;
    if (entry instanceof Directory) collect(entry, `${path}/`, out);
    else if (entry instanceof File && !/^\..*\.tmp-/.test(name)) out.set(path, entry.data);
  }
}

function put(root, path, data) {
  const parts = path.split("/");
  let folder = root;
  for (const name of parts.slice(0, -1)) {
    let next = folder.contents.get(name);
    if (!(next instanceof Directory)) { next = new Directory(new Map()); folder.contents.set(name, next); }
    folder = next;
  }
  folder.contents.set(parts.at(-1), new File(new Uint8Array(data)));
}

function equal(a, b) {
  if (a.byteLength !== b.byteLength) return false;
  for (let i = 0; i < a.byteLength; i++) if (a[i] !== b[i]) return false;
  return true;
}

function request(req) {
  return new Promise((resolve, reject) => {
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

function done(transaction) {
  return new Promise((resolve, reject) => {
    transaction.oncomplete = () => resolve();
    transaction.onerror = transaction.onabort = () => reject(transaction.error);
  });
}
