// Milo's Mole Dig — make.fun roblox-game-01 entry (Node 22, stdlib only).
//
// This program hands the game in. It copies the place file, the play-link
// file, the Luau sources and the screenshots from this repository into the
// output directory, then writes /output/dossier.json with the kit's vendored
// dossier library. The scorer builds the dossier again from what we hand in
// with the same library, so the two must agree byte for byte.
//
// Run it outside the grader with MAKEFUN_OUTPUT_DIR standing in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import {
  copyFileSync,
  cpSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = fileURLToPath(new URL(".", import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

function handInFile(name: string): void {
  copyFileSync(join(repoRoot, name), join(outputDir, name));
}

function handInDir(name: string): void {
  if (existsSync(join(repoRoot, name))) {
    cpSync(join(repoRoot, name), join(outputDir, name), { recursive: true });
  }
}

mkdirSync(outputDir, { recursive: true });
mkdirSync(join(outputDir, "screenshots"), { recursive: true });

handInFile("game.rbxl");
handInFile("PLAY.json");
handInDir("src");
handInDir("screenshots");

// The caps are the scorer's own (reference/gate.json): a dossier text of at
// most 65536 bytes, at most 4 screenshots of at most 262144 bytes each, a
// place of at most 500000 instances, and scripts of at most 8388608 source
// bytes and 1048576 path characters in all.
const dossier = buildDossier(outputDir, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(outputDir, "dossier.json"), dossier);
const dossierBytes = statSync(join(outputDir, "dossier.json")).size;

const shots = readdirSync(join(outputDir, "screenshots")).filter(
  (name) => !name.startsWith("."),
);
console.log(
  `handed in: game.rbxl + ${shots.length} screenshot(s) + PLAY.json + dossier.json (${dossierBytes} bytes)`,
);

// The entry is not submittable until a human has published the place and
// captured real screenshots: say so out loud instead of failing silently.
const play = JSON.parse(
  readFileSync(join(outputDir, "PLAY.json"), "utf8"),
) as { place_id: number };
if (play.place_id === 0) {
  console.log(
    "NOTE: PLAY.json still has the starter zeros — publish the place and fill in the real ids.",
  );
}
if (shots.length < 3) {
  console.log(
    `NOTE: only ${shots.length} screenshot(s) — the gate needs 3 or 4 real captures.`,
  );
}
