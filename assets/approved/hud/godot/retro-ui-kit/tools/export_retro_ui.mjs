import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const project = fileURLToPath(new URL("../", import.meta.url));
const visuals = process.argv[2] ?? path.resolve(project, "../../assets/ui-pixel-v1");
const output = path.join(project, "assets/ui/pixel-v1");
const masters = path.join(visuals, "regen-retro");
const manifest = { version: 1, texture_filter: "nearest", font: "font/PressStart2P-Regular.ttf", themes: {}, common: {} };

function magick(args, input) {
  return execFileSync("magick", args, { input, maxBuffer: 32 * 1024 * 1024 });
}

function png(relative, width, height, pixels) {
  const filename = path.join(output, relative + ".png");
  fs.mkdirSync(path.dirname(filename), { recursive: true });
  magick(["-size", width + "x" + height, "-depth", "8", "rgba:-", "PNG32:" + filename], pixels);
  return { texture: relative + ".png", size: [width, height] };
}

function rgb(hex, alpha = 255) {
  return [
    Number.parseInt(hex.slice(0, 2), 16), Number.parseInt(hex.slice(2, 4), 16),
    Number.parseInt(hex.slice(4, 6), 16), alpha
  ];
}

function raster(relative, width, height, pixel) {
  const pixels = Buffer.alloc(width * height * 4);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const color = pixel(x, y);
      if (color) pixels.set(color, (y * width + x) * 4);
    }
  }
  return png(relative, width, height, pixels);
}

function frame(relative, width, height, colors, corner = 3) {
  const [rim, shine, body, shadow] = colors.map((hex) => rgb(hex));
  const inside = (x, y, inset) => {
    const left = Math.min(x, width - 1 - x) - inset;
    const top = Math.min(y, height - 1 - y) - inset;
    return left >= 0 && top >= 0 && left + top >= Math.max(0, corner - inset);
  };
  const texture = raster(relative, width, height, (x, y) => {
    if (inside(x, y, 2)) return body;
    if (inside(x, y, 1)) return y > height - 4 ? shadow : shine;
    return inside(x, y, 0) ? rim : null;
  });
  return { ...texture, stretch_margin: Math.min(corner + 2, Math.floor((Math.min(width, height) - 1) / 2)) };
}

const themes = [
  ["luna",  "A45DFC", "C697FB", "2B0950", "FFF3FF", "FD82F0", "260D42"],
  ["yuki",  "F75CAA", "FAB6E8", "FDCFF3", "380E36", "FC82D1", "541442"],
  ["ori",   "9DD4F4", "CCEAFC", "F1FAFE", "041150", "FDC7EC", "17447F"],
  ["leya",  "A2DEA0", "B5EBC5", "124B34", "D9FAE8", "FDA3E3", "184F30"],
  ["toffi", "FDBA68", "FCE9C4", "FEEDCD", "541D0B", "FDEBC8", "71391B"],
  ["miya",  "5DB3FC", "B0DFFD", "2E599A", "E5F5FC", "6FA9FD", "102C59"],
  ["oni",   "005CC8", "40CBED", "102F60", "FAFCFC", "40D9FD", "11234B"],
];

for (const [id, body, light, sheet, text, active, rim] of themes) {
  const folder = "themes/" + id + "/";
  const theme = { ink: "#" + text, accent_ink: "#" + rim, parts: {} };
  const add = (key, w, h, colors, cut) => {
    theme.parts[key] = frame(folder + key, w, h, colors, cut);
  };
  const window = raster(folder + "window", 40, 40, (x, y) => {
    const distance = (inset) => {
      const dx = Math.min(x, 39 - x) - inset;
      const dy = Math.min(y, 39 - y) - inset;
      return dx >= 0 && dy >= 0 && Math.floor(dx / 3) + Math.floor(dy / 3) >= 3 - Math.floor(inset / 2);
    };
    if (!distance(0)) return null;
    if (!distance(2)) return rgb(light);
    if (!distance(4)) return rgb(y < 20 ? rim : body);
    if (!distance(5)) return rgb(y < 20 ? light : rim);
    return rgb(body);
  });
  theme.parts.window = { ...window, stretch_margin: 12 };
  if (id === "luna") {
    add("copy_normal", 22, 22, [rim, "F3DCFF", "CEABF6", "9362C4"]);
    add("copy_hover", 22, 22, [rim, "FFF3FF", "DEBFFF", "9362C4"]);
    add("copy_pressed", 22, 22, [rim, "A478C9", "BE97F0", "F3DCFF"]);
  }
  add("title_bar", 24, 18, [rim, light, light, body]);
  add("object_header", 28, 28, [rim, body, sheet, body], 5);
  add("object_portrait", 32, 32, [rim, light, body, rim], 4);
  add("property_panel", 28, 28, [rim, light, sheet, body], 5);
  add("property_row", 20, 16, [sheet, sheet, sheet, body], 0);
  add("tab_normal", 24, 23, [rim, light, light, body], 4);
  add("tab_hover", 24, 23, [rim, "FFF3FF", light, body], 4);
  add("tab_selected", 24, 23, [rim, light, active, body], 4);
  add("tab_disabled", 24, 23, [rim, body, body, rim], 4);
  add("field_normal", 22, 16, [light, sheet, sheet, sheet]);
  add("field_focus", 22, 16, [active, light, sheet, sheet]);
  add("field_error", 22, 16, ["F45173", light, sheet, sheet]);
  add("toggle_on", 26, 16, [rim, light, active, body]);
  add("toggle_off", 26, 16, [body, sheet, sheet, rim]);
  add("button_save", 42, 22, [rim, light, active, body], 4);
  add("button_save_hover", 42, 22, [rim, "FFF3FF", active, body], 4);
  add("button_save_pressed", 42, 22, [rim, body, active, light], 4);
  add("button_disabled", 42, 22, [rim, body, light, body], 4);
  add("toast", 28, 21, [rim, light, light, body], 4);
  add("console_panel", 32, 32, [rim, light, sheet, body], 6);
  add("mission_panel", 28, 24, [rim, light, sheet, body], 4);
  add("hint_panel", 26, 18, [rim, light, sheet, body], 3);
  add("active_tool_panel", 30, 24, [rim, light, sheet, body], 5);
  add("clock_panel", 28, 18, [rim, light, light, body], 4);
  add("hud_panel", 22, 18, [rim, light, sheet, body], 4);
  add("slot_normal", 26, 26, [rim, light, sheet, body]);
  add("slot_hover", 26, 26, [rim, active, sheet, light]);
  add("slot_selected", 26, 26, [rim, "FFF3FF", active, body]);
  add("slot_disabled", 26, 26, [rim, body, sheet, rim]);
  add("hotkey_backing", 13, 12, [rim, light, light, body], 2);
  for (const [key, size, thickness] of [["portrait_ring", 56, 4], ["minimap_ring", 80, 4]]) {
    theme.parts[key] = raster(folder + key, size, size, (x, y) => {
      const distance = Math.hypot(x + 0.5 - size / 2, y + 0.5 - size / 2);
      const inner = size / 2 - thickness - 1;
      if (distance < inner || distance > size / 2 - 1) return null;
      if (distance < inner + 1 || distance > size / 2 - 2) return rgb(rim);
      return rgb(distance < inner + 2 ? light : body);
    });
  }
  manifest.themes[id] = theme;
}

const common = manifest.common;
for (const [id, fill, light, shade] of [
  ["copy", "A9F4E5", "E0FFF9", "50AFAC"], ["delete", "FF4C76", "FFABB7", "A61F52"]
]) {
  for (const state of ["normal", "hover", "pressed"]) {
    const colors = ["240D3B", state === "hover" ? "FFFFFF" : light, fill, shade];
    if (state === "pressed") [colors[1], colors[3]] = [shade, light];
    const key = "button_" + id + "_" + state;
    common[key] = frame("common/" + key, 22, 22, colors);
  }
}

function cut(relative, source, area, width, height = width) {
  const [x, y, w, h] = area;
  const pixels = magick([source, "-crop", w + "x" + h + "+" + x + "+" + y,
    "+repage", "-filter", "point", "-resize", width + "x" + height + "!", "-depth", "8", "rgba:-"]);
  return png(relative, width, height, pixels);
}
function glyph(key, grid, color, outline = "") {
  const border = outline ? 1 : 0;
  const has = (x, y) => grid[y]?.[x] === "#";
  common[key] = raster("common/" + key, grid[0].length + border * 2, grid.length + border * 2, (x, y) => {
    x -= border;
    y -= border;
    if (has(x, y)) return rgb(color);
    if (border && (has(x - 1, y) || has(x + 1, y) || has(x, y - 1) || has(x, y + 1))) return rgb(outline);
    return null;
  });
}

glyph("quest_empty", ["#######","#.....#","#.....#","#.....#","#.....#","#.....#","#######"], "FFFFFF");
glyph("quest_done", ["#######","#....##","#...#.#","##.#..#","#.#...#","#.....#","#######"], "FFFFFF");
glyph("icon_dropdown", ["#######",".#####.","..###..","...#..."], "FFFFFF");
glyph("signal_4", [".........#",".........#","......#..#","......#..#","...#..#..#","...#..#..#","#..#..#..#","#..#..#..#"], "A8BBFF");
for (const [id, color] of [["active", "68F69A"], ["inactive", "FF4A70"]]) {
  glyph("status_" + id, [".#####.","#######","#######","#######","#######","#######",".#####."], color);
}
const hue = ["FF4568","FF8049","FFD255","F6F653","77EA55","35D88A","41E4DE","53BEFF","6978FF","A767FF","F564F9","FF478F"];
common.color_ramp = raster("common/color_ramp", 60, 8, (x, y) =>
  rgb(y === 0 || y === 7 ? "F3DBFF" : hue[Math.floor(x / 5)]));
common.color_thumb = frame("common/color_thumb", 9, 12, ["240D3B", "FFFFFF", "ECE3FF", "A897C9"], 2);
for (const [name, color] of [["health", "FF72AB"], ["mana", "64D8FF"], ["stamina", "FFCE61"]]) {
  common["bar_" + name] = frame("common/bar_" + name, 104, 8, ["27193E", "FBDFFA", color, "563968"], 2);
}
common.bar_empty = frame("common/bar_empty", 104, 8, ["27193E", "B8A8D0", "43325D", "21172F"], 2);

for (const [id] of themes) {
  const source = path.join(visuals, "cursors", id + "-source.png");
  manifest.themes[id].cursor = cut("cursors/" + id, source, [280, 265, 650, 760], 32, 38);
}
for (const filename of fs.readdirSync(path.join(visuals, "abilities/individual"))) {
  if (!filename.endsWith(".png")) continue;
  const id = filename.slice(0, -4);
  common["ability_" + id] = originalArt("abilities/" + id, path.join(visuals, "abilities/individual", filename), 1, { alphaFloor: 18 });
}

const artRoot = path.dirname(visuals);
function prepare(relative, source, w, h, config = {}) {
  const args = [source, "-alpha", "on"];
  if (config.crop) args.push("-crop", config.crop, "+repage");
  if (config.alphaFloor) args.push("-channel", "A", "-level", config.alphaFloor + "%,95%", "+channel");
  args.push("-trim", "+repage", "-filter", "point", "-resize", (w - 2) + "x" + (h - 2),
    "-background", "none", "-gravity", "center", "-extent", w + "x" + h, "-depth", "8", "rgba:-");
  return png(relative, w, h, magick(args));
}

// Export master art at its original resolution. Padding normalizes the aspect ratio without resampling.
function originalArt(relative, source, aspect, config = {}) {
  const args = [source, "-alpha", "on"];
  if (config.crop) args.push("-crop", config.crop, "+repage");
  if (config.alphaFloor) args.push("-channel", "A", "-level", config.alphaFloor + "%,98%", "+channel");
  args.push("-trim", "+repage");
  const [w, h] = magick([...args, "-format", "%w %h", "info:"]).toString().split(" ").map(Number);
  const width = Math.max(w, Math.ceil(h * aspect)) + 4;
  const height = Math.round(width / aspect);
  args.push("-background", "none", "-gravity", "center", "-extent", width + "x" + height, "-depth", "8", "rgba:-");
  return png(relative, width, height, magick(args));
}

function master(name) {
  return path.join(masters, name + ".png");
}

function exportRow(name, keys, alphaFloor = 25) {
  const source = master("row-" + name);
  const [w, h] = magick([source, "-format", "%w %h", "info:"]).toString().split(" ").map(Number);
  const alpha = magick([source, "-alpha", "extract", "-depth", "8", "gray:-"]);
  const coverage = Array.from({length: w}, (_, x) => {
    let pixels = 0;
    for (let y = 0; y < h; y++) if (alpha[y * w + x] > 100) pixels++;
    return pixels;
  });
  const cuts = [0];
  const stride = w / keys.length;
  for (let i = 1; i < keys.length; i++) {
    const center = Math.round(stride * i);
    const search = Math.floor(stride * 0.23);
    let cut = center;
    let best = Infinity;
    for (let x = center - search; x <= center + search; x++) {
      const score = coverage[x] + Math.abs(x - center) * 0.025;
      if (score < best) {
        best = score;
        cut = x;
      }
    }
    if (coverage[cut] > 0) throw new Error(name + ": missing clear gutter before " + keys[i]);
    cuts.push(cut);
  }
  cuts.push(w);
  for (const [i, key] of keys.entries()) {
    const crop = (cuts[i + 1] - cuts[i]) + "x" + h + "+" + cuts[i] + "+0";
    common[key] = originalArt("common/" + key, source, 1, {crop, alphaFloor});
  }
}

for (const [id] of themes) {
  manifest.themes[id].parts.backpack = originalArt("characters/" + id + "/backpack", master("backpack-" + id), 252 / 273, {alphaFloor: 18});
  manifest.themes[id].parts.portrait = originalArt("characters/" + id + "/portrait", master("portrait-" + id), 1, {alphaFloor: 18});
}
exportRow("actions", ["icon_copy", "icon_delete", "icon_done", "icon_close", "window_minimize", "window_maximize"]);
exportRow("markers", ["map_player", "map_passage", "map_bridge", "map_quest", "map_pin"]);
exportRow("clock", ["time_dawn", "time_day", "time_dusk", "time_night"]);
exportRow("vitals", ["hud_health", "hud_mana", "hud_stamina"]);
exportRow("properties", ["property_health", "property_alive", "property_speed", "property_behavior", "property_tint"], 40);
exportRow("tabs", ["tab_general", "tab_appearance", "tab_physics", "tab_mind", "tab_behavior", "tab_relationships", "tab_abilities"]);
common["maple-sample"] = originalArt("common/maple-sample", master("maple"), 1, {alphaFloor: 18});
common.window_moon = common.map_player;
for (const id of ["lock"]) {
  common["hud_" + id] = prepare("common/hud_" + id, path.join(artRoot, "ui/common/icons", id + ".svg"), 16, 16);
}
glyph("hud_plus", ["..#..","..#..","#####","..#..","..#.."], "FFFFFF");
glyph("hud_minus", [".....",".....","#####",".....","....."], "FFFFFF");
glyph("hud_info", ["..#..",".....","..#..","..#..","..#.."], "FFFFFF");
const canon = JSON.parse(fs.readFileSync(path.join(masters, "artifact-roster.json"), "utf8"));
manifest.artifact_roster = canon.source;
manifest.artifacts = canon.artifacts.map((item) => {
  const {key} = item;
  const config = key === "miya-potion" ? {alphaFloor: 18} : {};
  const part = originalArt("items/" + key, master("artifacts/" + key), 1, config);
  common["item_" + key] = part;
  return {...item, texture: part.texture};
});
common.item_wand = originalArt("items/wand", master("wand"), 1, {alphaFloor: 18});

fs.writeFileSync(path.join(output, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n");
