# Diodon Image Clipboard — Implementation Guide

## Overview

This document explains the **full lifecycle** of how images flow through Diodon's clipboard system, the architecture that prevents UI freezes and memory bloat, and the refactored caching and loop-detection mechanisms.

---

## The Problem We Solved

A single 4K image (3840×2160, RGBA) is **33 MB of raw pixel data**. The original Diodon code would:

1. Hold the full 33 MB pixbuf in memory per image in the clipboard history
2. Call `clipboard.set_image()` + `clipboard.store()` which **re-encodes 33 MB to PNG synchronously on the main thread** — freezing the desktop for 2-5 seconds
3. Query Zeitgeist + decode PNG + SHA1 hash the raw pixels on every paste from history
4. Keep unbounded copies in memory — 5 images = 165 MB+

A subsequent two-tier caching approach (instance `_cached_png` + static single-slot cache) reduced the freeze but introduced **~144 MB** memory usage for 5 items (10 MB PNG per instance) and a fragile cache duality with race conditions.

---

## Architecture (Refactored)

### Data Representations

| Form | Size (4K image) | Purpose |
|------|-----------------|---------|
| `Gdk.Pixbuf` (raw RGBA pixels) | ~33 MB | Required by GTK's `set_pixbuf()` for non-PNG targets. Only kept on `with_image()` items (ONE item). |
| PNG-encoded `GLib.Bytes` (in LRU cache) | ~10 MB | Compact lossless form, stored in global `ImageCache` |
| `Gdk.Pixbuf` thumbnail (`_thumbnail`) | ~100 KB | 200×150 preview for menu display, kept on instance |

### Key Classes

- **`ImageCache`** — Global LRU cache (singleton) with a hard 64 MB memory limit. Stores PNG `GLib.Bytes` keyed by SHA1 checksum. Evicts least-recently-used entries when full. Also provides a single-slot **speculative pixbuf warm-up** cache for hover-based pre-decoding.
- **`ImageClipboardItem`** — Represents a clipboard image. Four construction paths optimized for different use cases:
  - `with_image()` — Fresh copies: keeps pixbuf, saves thumbnail to disk
  - `with_metadata()` — Menu display: loads ONLY thumbnail from disk (~5 KB)
  - `with_known_payload()` — Paste: known checksum, keeps pixbuf, no SHA1 re-compute
  - `with_payload()` — Legacy fallback: full decode, drops pixbuf
- **`ZeitgeistClipboardStorage`** — Stores/retrieves items via Zeitgeist (local database). Uses **lightweight mode** for menu items (thumbnails only) and **full mode** for paste operations.
- **`ClipboardManager`** — Monitors the system clipboard for changes. Implements **ownership-based loop detection** via `Gtk.Clipboard.get_owner()`.
- **`Controller`** — Orchestrates paste operations and menu rebuilds.
- **`ClipboardMenuItem`** — GTK menu widget showing the thumbnail. Hooks `select` signal for speculative pixbuf warm-up on hover.

---

## Full Lifecycle

### Phase 1: Image Copied (User copies an image in any app)

```
App copies image → X11 clipboard changes → owner_change signal
    → ClipboardManager.check_clipboard()
    → OWNERSHIP CHECK: get_owner() returns null (external app) → proceed
    → clipboard.wait_for_image()
    → on_image_received(pixbuf)  [33 MB raw pixels]
```

**`ImageClipboardItem.with_image(pixbuf)`** is called:
1. `extract_pixbuf_info(pixbuf)`:
   - SHA1 hash of all raw pixels → `_checksum` (unique content ID)
   - Create `_thumbnail` (200×150, bilinear, contain-fit) → ~100 KB
   - **Save thumbnail to disk** (`~/.local/share/diodon/thumbnails/<checksum>.png`) for instant menu loading
   - Encode pixbuf → PNG → `GLib.Bytes` → stored in global `ImageCache`
2. `_pixbuf` stays set (needed for immediate clipboard serving and `keep_clipboard_content`)
3. Item passed to `controller.add_item()` → stored in Zeitgeist with PNG payload

**Cost:** ~200ms for SHA1 + PNG encode + thumbnail save. One-time per copy event.

### Phase 2: Menu Opens (User clicks Diodon indicator)

```
rebuild_recent_menu()
    → storage.get_recent_items()
    → Zeitgeist query returns events
    → create_clipboard_items() iterates events (lightweight=true)
    → For each image event: extract checksum from URI, load thumbnail from disk
```

**`ImageClipboardItem.with_metadata(checksum, label)`** is called per image:
1. Checksum extracted from Zeitgeist subject URI (`dav:<checksum>`) — **no SHA1 computation**
2. Label (dimensions string) read from Zeitgeist subject text — **no PNG decode**
3. Thumbnail loaded from disk (`~/.local/share/diodon/thumbnails/<checksum>.png`) — **~5 KB**
4. If thumbnail file missing (pre-persistence items): graceful fallback, show label only

**Memory per menu item:** ~5 KB thumbnail only (was ~33 MB temporary pixbuf).
**Global LRU cache:** Not touched during menu load.
**Menu open time:** Near-instant regardless of image count (was O(n × 100ms) for decoding).

### Phase 2.5: Speculative Decode (User hovers an image item)

```
User highlights menu item → Gtk.MenuItem `select` signal
    → GLib.Idle.add() schedules warm-up (non-blocking)
    → ImageCache.warm_pixbuf(checksum)
    → If PNG in LRU cache: decode to pixbuf, store in single-slot warm cache
    → If PNG not cached: skip (paste path will handle it)
```

**Speculative decode** pre-decodes the full image when the user hovers or keyboard-navigates to an item. The decoded pixbuf is stored in `ImageCache._warm_pixbuf` (single slot, ~33 MB). When the user clicks, `to_clipboard()` picks it up instantly — zero decode latency at paste time.

Only ONE warm pixbuf exists at a time. Hovering a new item releases the previous one.

### Phase 3: User Clicks an Item (Paste from History)

```
ClipboardMenuItem.activate signal
    → controller.select_item_by_checksum(checksum)
    → storage.get_item_by_checksum(checksum)  [Zeitgeist query]
    → create_clipboard_item(lightweight=false)
    → ImageClipboardItem.with_known_payload(checksum, payload)
    → storage.select_item(item)
    → item.to_clipboard(clipboard)
    → execute_paste() → fake Ctrl+V via XTest
```

**`with_known_payload(checksum, payload)`** does:
1. Checksum already known from Zeitgeist URI — **skips SHA1 of 33 MB pixels (~15ms saved)**
2. Decode PNG → pixbuf (~50ms for 4K)
3. Store PNG in global LRU cache
4. **KEEP `_pixbuf`** — needed for immediate clipboard serving (no second decode)
5. Save thumbnail to disk if not already persisted

**`to_clipboard(clipboard)`** does:
1. Check `_pixbuf` — **non-null** (kept by `with_known_payload()`) → fast path
2. Check `ImageCache.get_warm_pixbuf()` — speculative warm-up from hover
3. Fallback: decode from LRU cache (only if neither of the above)
4. Call `clipboard.set_with_owner(targets, get_func, clear_func, this)`

**Improvement over previous design:**
- Old: decode pixbuf in `with_payload()` → drop it → re-decode in `to_clipboard()` (2× decode)
- New: decode once in `with_known_payload()` → keep it → `to_clipboard()` finds it immediately (1× decode)

### Phase 4: Target App Requests Data

```
App pastes (Ctrl+V) → X11 selection request
    → GTK calls clipboard_get_func(selection_data, target)
    → We check what format the app wants
```

**`clipboard_get_func` — Fail-Fast Contract (never blocks >5ms):**

| Requested Target | What We Do | Cost |
|-----------------|------------|------|
| `image/png` | Serve cached PNG bytes from `ImageCache` directly | **~0ms** (memcpy) |
| `image/bmp`, `image/x-pixbuf`, etc. | `selection_data.set_pixbuf(_pixbuf)` — GDK converts | ~100ms |
| Any format, pixbuf not ready | **Fail immediately** — return without setting data | **~0ms** |

**The PNG fast path is the key optimization.** Most modern apps (GIMP, Chrome, LibreOffice, etc.) accept PNG. We serve our pre-encoded ~10 MB PNG bytes directly — no re-encoding of 33 MB pixels on the main thread.

**Fail-fast guarantee:** For non-PNG targets, if `_pixbuf` is null (shouldn't happen after `to_clipboard()`, but possible in edge cases), the callback checks the speculative warm-up cache. If still null, it returns immediately without blocking. The requesting app sees an empty selection and can retry or fall back to a different target. **NEVER** does a synchronous PNG→pixbuf decode inside this callback — that would freeze the entire desktop.

### Phase 5: Clipboard Feedback Loop (Eliminated)

```
set_with_owner() changes clipboard ownership
    → owner_change signal fires
    → ClipboardManager.check_clipboard()
    → get_owner() returns ImageClipboardItem instance
    → SELF-OWNED: return immediately (zero CPU cost)
```

**The feedback loop is now eliminated at the source:**
1. Diodon calls `set_with_owner(this)` → Diodon owns the clipboard
2. `owner_change` signal fires → `check_clipboard()` runs
3. `_clipboard.get_owner()` returns the `ImageClipboardItem` → recognized as self-ownership
4. **Return immediately** — no image readback, no SHA1 hash, no duplicate check

When an external app later copies something, GTK clears Diodon's ownership. `get_owner()` returns null → normal processing resumes.

---

## Cache Architecture

### Global LRU Cache (ImageCache)

```
┌─────────────────────────────────────────────┐
│  ImageCache (singleton)                     │
│                                             │
│  Hard limit: 64 MB                          │
│  Storage: GLib.Bytes (immutable, ref-count) │
│  Eviction: Least Recently Used              │
│  Lookup: O(1) HashTable by checksum         │
│  Ordering: GLib.Queue for LRU              │
│                                             │
│  Capacity: ~6 cached 4K images              │
│  At rest: typically 1 image (~10 MB)        │
│                                             │
│  Warm pixbuf: single-slot pre-decode cache  │
│  (~33 MB, populated on hover, cleared on    │
│   next hover or cache clear)                │
│                                             │
│  Used by:                                   │
│    - clipboard_get_func (PNG fast path)     │
│    - to_clipboard (pixbuf resolution)       │
│    - get_payload (Zeitgeist storage)        │
│    - warm_pixbuf (speculative decode)       │
└─────────────────────────────────────────────┘
```

### Thumbnail Persistence

```
~/.local/share/diodon/thumbnails/
    <checksum1>.png   (~5 KB, 200×150)
    <checksum2>.png
    ...
```

Thumbnails are saved to disk at copy time (`extract_pixbuf_info()`). At menu load time, only these tiny files are read — never the full PNG payload from Zeitgeist. This makes the menu open instantly regardless of how many 4K images are in history.

Files are written idempotently (skip if exists) and survive application restarts. Old items from before thumbnail persistence was added will show label-only in the menu until they are reselected (which triggers `with_known_payload()` → `save_thumbnail_to_disk()`).

### Why LRU Instead of Two-Tier?

The previous two-tier system (instance `_cached_png` + static single-slot cache) had:
- **Unbounded memory**: 10 items × 10 MB = 100 MB of `_cached_png` on instances
- **Cache coherence bugs**: single-slot cache eviction could leave items with stale or no data
- **Empty-paste bugs**: when static cache was evicted AND instance `_cached_png` was null

The global LRU cache:
- **Fixed 64 MB limit** regardless of history size
- **Single source of truth** — no consistency issues between tiers
- **Automatic eviction** — least-used images freed first
- **GLib.Bytes immutability** — zero-copy ref-counting, safe for callbacks

---

## Loop Detection: Ownership Check

### Previous Method (Eliminated)

```
owner_change → read clipboard → wait_for_image() → 33 MB pixbuf
    → SHA1 hash 33 MB → compare with current item → skip if match
    Cost: ~200ms CPU + 33 MB temporary allocation per loop iteration
```

### New Method

```
owner_change → get_owner() → is IClipboardItem? → skip
    Cost: ~0ms, single pointer comparison
```

`Gtk.Clipboard.get_owner()` returns the GObject passed to `set_with_owner()`. When Diodon sets the clipboard with an `ImageClipboardItem` as owner, subsequent `owner_change` callbacks detect this immediately and return without reading the clipboard.

When another application takes clipboard ownership:
1. GTK calls `clipboard_clear_func` on our item
2. GTK clears the stored owner reference
3. `get_owner()` returns null on the next `owner_change`
4. Normal clipboard processing resumes

---

## Bug History & Fixes

### Bug: Desktop Freezing on 4K Paste
**Root cause:** `clipboard.set_image()` + `clipboard.store()` synchronously encodes 33 MB pixbuf to multiple formats.
**Fix:** Replaced with `set_with_owner()` + lazy `clipboard_get_func` callbacks.

### Bug: CPU Spike on Every Paste from History
**Root cause:** Each paste triggered: Zeitgeist query → PNG decode → SHA1 of 33 MB → PNG re-encode.
**Fix:** PNG bytes cached in global LRU cache. SHA1 computed once during initial copy. Feedback loop eliminated via ownership check.

### Bug: 213 MB Memory Usage (HashMap cache)
**Root cause:** Unbounded HashMap caching both pixbufs (33 MB each) AND PNGs (10 MB each).
**Fix:** Global LRU cache (64 MB hard limit) + instances hold only thumbnails (~100 KB).

### Bug: 144 MB Memory Usage (Two-tier cache)
**Root cause:** Instance `_cached_png` fields (10 MB each × N items) + static cache.
**Fix:** Eliminated instance-level PNG storage entirely. Single global LRU cache bounded at 64 MB.

### Bug: Empty Image Pasted
**Root cause:** Static cache eviction left items with no data source.
**Fix:** All PNG data in single LRU cache. Paste path always re-queries Zeitgeist → `with_known_payload()` → LRU cache is populated immediately before `to_clipboard()`.

### Bug: First Image Always Pasted (Regardless of Selection)
**Root cause:** `from_cache()` shortcut returned stale data; `clipboard_get_func` forced PNG atom for all targets.
**Fix:** Removed `from_cache()` entirely. Always query Zeitgeist for correctness. `clipboard_get_func` checks requested target format.

### Bug: Feedback Loop CPU Waste
**Root cause:** Reading back own clipboard data and hashing 33 MB of pixels just to detect self-ownership.
**Fix:** `ClipboardManager.check_clipboard()` calls `get_owner()` — if Diodon owns the clipboard (via `set_with_owner`), return immediately. Zero-cost ownership check.

### Bug: Menu Open Lag (4K images decode on every open)
**Root cause:** `create_clipboard_items()` called `with_payload()` for each image event, which decoded the full PNG (33 MB pixbuf) just to extract a thumbnail. 10 images = 10× ~100ms decode = 1+ second lag.
**Fix:** `with_metadata()` constructor loads ONLY the thumbnail from disk (~5 KB). Checksum extracted from Zeitgeist URI — no SHA1, no PNG decode. Menu opens instantly.

### Bug: Double Pixbuf Decode on Paste
**Root cause:** `with_payload()` decoded PNG → pixbuf for checksum extraction, then dropped `_pixbuf`. `to_clipboard()` immediately re-decoded the same PNG from LRU cache. Two expensive decodes for one paste operation.
**Fix:** `with_known_payload()` takes the checksum from the Zeitgeist URI (no SHA1 needed) and KEEPS the decoded pixbuf. `to_clipboard()` finds `_pixbuf` non-null — zero additional decode.

### Bug: Desktop Freeze from clipboard_get_func Blocking
**Root cause:** `clipboard_get_func()` had a "last resort" path that synchronously decoded a 4K PNG (~50-100ms) on the GTK main thread when `_pixbuf` was null. This blocked the entire desktop during paste.
**Fix:** Fail-fast contract: `clipboard_get_func()` never blocks >5ms. For non-PNG targets without a ready pixbuf, it returns immediately without setting data. The requesting app sees an empty selection and can retry or fall back.

---

## Memory Profile (Steady State)

| Component | Memory | Notes |
|-----------|--------|-------|
| Global LRU cache | ≤ 64 MB | Hard limit; typically ~10 MB (one image) |
| Per-item thumbnails (10 items) | ~50 KB | Loaded from disk, ~5 KB each |
| Warm pixbuf (speculative) | ~33 MB | Single-slot, only while hovering image item |
| Active paste pixbuf | ~33 MB | Only during paste, kept by `with_known_payload()` |
| Thumbnail files on disk | ~50 KB | Persistent, survives restarts |
| **Total (worst case, hovering)** | **~130 MB** | LRU max + warm pixbuf + thumbnails |
| **Total (typical, menu open)** | **~10.05 MB** | ~10 MB cache + 50 KB disk thumbnails |
| **Total (idle, menu closed)** | **≤ 10 MB** | Only last-touched image in LRU |

**Improvement over previous architectures:**
- Original: **165 MB+** (unbounded pixbufs)
- Two-tier cache: **~144 MB** (instance `_cached_png` × N)
- LRU refactor: **~10 MB idle, 98 MB peak** (bounded)
- **Performance patch: ~10 MB idle, instant menu open, fail-fast paste**

---

## UI Changes

- **Image thumbnails:** 200×150 max, bilinear scaling, contain-fit (no crop, no upscale)
- **Menu items:** Base class `Gtk.MenuItem` (was `Gtk.ImageMenuItem`), centered image in `Gtk.Box`
- **Text wrapping:** Labels wrap to 4 lines max, 50 chars wide, ellipsize at end
- **Label length:** Text/file items show up to 100 chars (was 50)
- **Auto-select:** Menu auto-selects first item on popup for keyboard navigation

---

## Build & Run

```bash
# Build
cd builddir && ninja

# Run (with custom libdiodon)
LD_LIBRARY_PATH=builddir/libdiodon builddir/diodon/diodon

# Kill & restart
killall diodon; sleep 1; LD_LIBRARY_PATH=builddir/libdiodon builddir/diodon/diodon &
```
