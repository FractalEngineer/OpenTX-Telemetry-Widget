# Handoff: Integrated CRSF/MAVLink Status Messages Proof of Concept

Last updated: 2026-09-04

## Final status

This work is complete as a **validated proof of concept**, not as a production-ready Tango 2 feature.

Real hardware proved the complete ArduPilot `STATUSTEXT` -> ExpressLRS 4.1 MAVLink conversion -> CRSF frame -> FreedomTX Lua parser -> popup/history path. Parsing, deduplication, bounded history, vertical display, and all page types were exercised. Attempt 11 could load every page, but the full integrated telemetry process still terminated with `not enough memory` after receiving a few live telemetry messages.

Do not continue reducing or restructuring the full iNav widget for this feature. Continue from `CODEX_HANDOFF_Discrete_MAVLink_Status_Screen.md` and build a standalone message-only telemetry script.

## Goal

Display autopilot status text in iNav Lua Telemetry when ExpressLRS converts MAVLink `STATUSTEXT` to a CRSF status-text frame. Preserve normal telemetry, bounded memory use, TBS Crossfire compatibility, and existing non-CRSF behavior.

## Test hardware currently in use

- Radio: TBS Tango 2 running FreedomTX, monochrome display.
- Flight controller: ArduPilot.
- Link: ExpressLRS TX/RX upgraded together from 3.5.2 to 4.1, in MAVLink mode.
- MAVLink transport was independently validated by connecting QGroundControl through the ELRS backpack.
- Still record: FreedomTX version, exact ArduPilot version, ELRS hardware targets, and backpack firmware version.

The Tango 2 is the limiting platform. It needs stripped precompiled Lua; source compilation exceeds available Lua RAM. Attempt 10 measured runtime view-load headroom at only about 9 KiB before and 6 KiB after the initial Classic load. Its temporary success diagnostic has been removed from Attempt 11 to reclaim memory.

## Protocol contract

- Sole raw queue consumer: `crossfireTelemetryPop()` must remain centralized.
- Process at most eight frames per background call.
- Current frame: CRSF command `0x80`; accept legacy `0x7F` too.
- Payload byte 1: subtype `0xF1`.
- Payload byte 2: MAVLink severity.
- Payload bytes 3-52: at most 50 text bytes, optionally NUL terminated.
- ELRS device-info response `0x29` must continue to work through the same dispatcher.
- MAVLink 2 chunk IDs are not carried by this CRSF conversion, so do not attempt long-message reassembly.

## Intended UI behavior

- Keep the newest 20 messages.
- Adjacent equal text/severity received within three seconds becomes one item with `xN`.
- Newest message appears first.
- Severity labels: `EMR`, `ALR`, `CRT`, `ERR`, `WRN`, `NOT`, `INF`, `DBG`; critical severities also get `!`.
- Non-debug messages briefly overlay the active telemetry page; duplicate updates do not extend the popup.
- Messages view supports scrolling and `Exit` returns to Classic.
- On memory-constrained 128x64 radios, navigation is intentionally Classic -> Radar -> Messages. Pilot is skipped because its renderer cannot coexist with the added feature in Tango 2 Lua RAM.

## Clean committed baseline

Branch: `status-messages`

1. `c9185cb Add CRSF status text dispatch and history`
2. `ff839c9 Add status messages view and popup`
3. `8b585b2 Document CRSF status messages`
4. `33a25f6 Add status message test target`

Validated Tango fixes have been folded into these four topical commits. Do not reintroduce hardware-debug/fixup commits; future confirmed changes should be amended/folded by topic.

## Current validated implementation

Key changes now included in the clean commit series:

- Extension-neutral internal `loadScript` paths.
- One compact dispatcher handles status text and ELRS device info; the old separate ELRS parser is not retained at runtime.
- Dispatcher loads after initialization, not during the peak top-level load.
- Dispatcher can unload before a dynamic view/menu load and lazily reload in a later background cycle.
- Optional dispatcher and dynamic view loads are checked before invocation; loader OOM must not become an unchecked nil call.
- Unused message-state fields were removed.
- Status parsing uses one retained closure, no popup lookup table, and no temporary character table.
- Status parsing and history eviction do not require the global `table` library, which is absent on this FreedomTX target.
- The monochrome Messages empty state does not use `CENTERED`, which FreedomTX does not define on this target.
- Attempt 9 `SMLCD` navigation skips Pilot and normalizes a saved Pilot view to Radar.
- Tests cover deferred loading, dispatcher reload across view changes, 128x64 navigation, and a missing monochrome `CENTERED` constant.

`CODEX_HANDOFF_EdgeTX_MAVLink_Status_Messages.md` is intentionally maintained as the live handoff. Ignore `CONTRIBUTING.md` per user instruction.

## Distilled Tango 2 test history

| Attempt | Package type | Result | Useful conclusion |
|---|---|---|---|
| Original implementation | Precompiled, eager modules | Immediate nil-value error | Eager status load exceeds Tango headroom. |
| Source and diagnostic builds | Source Lua | Explicit `not enough memory` | On-radio compilation is not viable. |
| Lazy/compact source builds | Source Lua | Nil/OOM | Smaller runtime does not fix compilation peak. |
| Compact precompiled | Stripped bytecode | Classic telemetry loaded; first Enter failed | Precompilation is required; view-load peak remained. |
| Dispatcher-unload precompiled | Stripped bytecode | Classic OK; Pilot blank; Radar OK; Messages errored on `CENTE...` | Pilot is too large; guarded load caused blank page. Messages used unsupported `CENTERED`. |
| Small-navigation precompiled | Stripped bytecode | All pages OK on ELRS 3.5.2; after upgrade to ELRS 4.1, first live message caused `attempt to index field 'table'` | ELRS 4.1 conversion works; FreedomTX has no global `table` library. |

Do not retry older artifacts. Their only remaining value is the conclusions above.

## Latest package: Attempt 9 (end-to-end validated)

Artifact:

`dist/LuaTelemetry_v2.4_status-messages_tango2_validated.zip`

SHA-256:

`C2B37B03FFC05161E12269F2CBF278D12C8CDFFE7B1F75626561268049E76A18`

Changes relative to Attempt 8:

- Replaces `table.unpack` with FreedomTX-compatible string construction.
- Replaces `table.remove` history eviction with an in-place bounded shift.
- The status suite now runs with `table = nil` and still verifies parsing, deduplication, and 20-entry eviction.

Expected radio sequence:

1. Clean install the precompiled package; no source `.lua` modules may remain in `iNav/`.
2. Classic loads and displays normal telemetry.
3. First `Enter`: Radar renders (not a black Pilot page).
4. Second `Enter`: Messages renders, initially showing `No messages`.
5. `Exit`: returns to Classic.
6. Inject a warning `STATUSTEXT`; confirm popup and a history row.
7. Repeat the same warning rapidly and confirm the row becomes `xN`.
8. Generate more than 20 distinct messages and confirm bounded eviction remains error-free.

Real-radio result:

- Classic, Radar, and Messages all load correctly.
- Normal telemetry is displayed.
- ELRS 3.5.2 produced no handset status frames, as expected.
- After TX/RX upgrade to ELRS 4.1, a live status frame reached `status.lua` and exercised `table.unpack`, proving handset conversion and CRSF dispatch are active.
- After removing the `table` library dependency, ArduPilot messages display successfully.
- Vertical message-history scrolling works on the Tango 2.

## Attempt 10 hardware result (failed)

Artifact:

`dist/LuaTelemetry_v2.4_status-messages_tango2_attempt10.zip`

SHA-256:

`2F62598CC5DC20D8BD73304162C88AE71F88CE83F61B41E325323626EE7F27E2`

Changes relative to Attempt 9:

- Dynamic view loads retain the requested view name, runtime `LCD_W`/`LCD_H`, radio ID, and memory readings before and after the load.
- On firmware with `getAvailableMemory()`, the diagnostic reports free KiB. Older firmware falls back to Lua heap usage from `collectgarbage("count")`.
- A successful small-screen view load briefly shows the compact diagnostic at the actual bottom of the LCD.
- A failed view load renders a useful error page instead of returning to a cleared black screen. `Enter` can advance to the next view and `Exit` returns to Classic.
- The monochrome status popup is anchored to `LCD_H`, stays within the screen, and wraps to at most two bounded lines.
- Monochrome message rows are calculated from `LCD_H`; a 128x96 screen displays eight rows rather than the old fixed five.
- The newest visible history row is selected. Left/right (`EVT_VIRTUAL_DEC`/`EVT_VIRTUAL_INC`) reads horizontally through long text; the offset is bounded and resets when vertical selection changes.
- Small-screen navigation is restored to Classic -> Pilot -> Radar -> Messages. Pilot uses the new stripped `pilot_s.luac` renderer (2,255 bytes) instead of loading the full 11,891-byte Pilot module.
- Automated tests inject a failed Pilot load and exercise both memory-diagnostic API paths, 128x96 geometry, popup bounds, Pilot restoration, horizontal bounds, dispatcher reload, and existing status behavior.

Package inspection found 245 entries. Its only `.lua`-named files are the required telemetry and widget entry points, and both contain Lua bytecode rather than source.

Real-radio result:

- The temporary resolution/memory overlay rendered and reported roughly `9k>6k` on startup.
- Classic later crashed with `not enough memory`.
- The lightweight Pilot loaded but looked incomplete: some data and only a single HUD line.
- Full Radar failed to load and its fallback reported `free 0k>0k`.
- Messages loaded, but the attempted virtual-inc/dec mapping did not scroll horizontally.
- Enter did nothing on Messages, preventing the established Enter-cycle back to Classic.

Do not retest Attempt 10.

## Attempt 11 hardware result (proof-of-concept limit reached)

Artifact:

`dist/LuaTelemetry_v2.4_status-messages_tango2_attempt11.zip`

SHA-256:

`8E12FB6C836CCAD3A2C07F6CCEDB8F6236BA889C7087AFA6045C7D6FFA6D36F4`

Changes relative to Attempt 10:

- Removes all successful-load resolution/memory instrumentation and its retained state. The stripped resident entry chunk drops from about 16.5 KiB to 15,093 bytes.
- Retains only a compact two-line failed-view fallback with the module name and navigation hint.
- Replaces the failed 8,365-byte full Radar load with `radar_s.luac` (1,833 bytes), a small-screen renderer with home bearing, orientation, core GPS/flight data, battery, and link quality.
- Expands `pilot_s.luac` to a bounded five-line pitch ladder and center aircraft marker while keeping it to 2,309 bytes.
- Moves all message scrolling event decoding out of the resident entry chunk and into the dynamically loaded Messages view.
- Horizontal reading accepts virtual inc/dec, raw plus/minus, and held next/previous repeat events. Short next/previous remains vertical row selection.
- Both Enter and Exit now leave Messages for Classic; Enter resumes the normal view cycle from there.
- Tests verify lightweight Pilot and Radar selection, raw plus/repeat horizontal movement and bounds, vertical reset, Enter-to-Classic, failed-view fallback, and existing integrations.

Package inspection found 246 entries. Its only `.lua`-named files are the required telemetry and widget entry points, and both contain stripped Lua bytecode.

Real-radio result:

- Classic, lightweight Pilot, lightweight Radar, and Messages all loaded.
- After a few live telemetry/status messages, the script terminated with `not enough memory`.
- This confirms that view-module reduction alone cannot provide a reliable operating margin for the integrated feature on Tango 2.
- The transport, parser, history, and display concept remains validated; the integrated deployment architecture is rejected for this target.

## Conclusion

- The protocol contract and end-to-end message transport are validated.
- The integrated iNav implementation is useful as reference code and an automated test bed.
- The Tango 2 cannot reliably retain the full iNav telemetry state, active view, dispatcher, and growing message history in its available Lua heap.
- A second concurrently configured telemetry screen would not create a separate heap: OpenTX treats telemetry scripts as permanent scripts loaded with the model, calls their background functions while hidden, and places permanent scripts in the same runtime environment.
- The next implementation must therefore be a standalone message-only telemetry script used instead of iNav on the constrained model, or selected through a separate model profile so switching models unloads/reinitializes the permanent scripts.

## Automated verification

Run on Windows:

```powershell
gmake CC=gcc test
```

Current suite passes:

- Status parsing, malformed frames, 50-byte text, legacy command, severity, deduplication, history bound, and eight-frame queue bound.
- ELRS device-info parsing.
- Messages renderer at 128x64, 212x64, and color sizes.
- Main integration at 128x64, 212x64, and color sizes.
- Deferred dispatcher initialization and reload after view changes.
- Visible fallback after an injected `loadScript()` failure.
- Lightweight Pilot and Radar selection on 128-pixel screens.
- 128x96 message geometry, popup bounds, and bounded horizontal reading.

## Validated ELRS configuration

The working setup uses:

- Matching ELRS 4.1 on TX and RX.
- TX `Link Mode = MAVLink`; telemetry ratio becomes 1:2.
- Receiver serial protocol MAVLink (automatic with ELRS v4 when link mode changes; explicit on v3).
- ArduPilot: `SERIALx_PROTOCOL=2`, `SERIALx_BAUD=460`, `RSSI_TYPE=5`.
- INAV 8+: UART telemetry MAVLink at 460800, serial receiver provider MAVLink, and `mavlink_radio_type=ELRS`.

Use a warning/critical message for the first test. Validate on the bench with propellers removed.

## Relevant upstream references

- ExpressLRS MAVLink setup and handset conversion: https://www.expresslrs.org/software/mavlink/
- ExpressLRS MAVLink-to-CRSF implementation: https://github.com/ExpressLRS/ExpressLRS/blob/master/src/lib/MAVLink/MAVLink.cpp
- ArduPilot CRSF telemetry: https://ardupilot.org/copter/docs/common-crsf-telemetry.html
- OpenTX `loadScript` behavior: https://doc.open-tx.org/opentx-2-3-lua-reference-guide/part_iii_-_opentx_lua_api_reference/general-functions-less-than-greater-than-luadoc-begin-general/loadscript

## Immediate next-session plan

No further integrated Tango iteration is planned. Use `CODEX_HANDOFF_Discrete_MAVLink_Status_Screen.md` for the standalone implementation.
