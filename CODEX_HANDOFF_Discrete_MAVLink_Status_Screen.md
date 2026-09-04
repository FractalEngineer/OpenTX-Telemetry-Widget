# Handoff: Standalone MAVLink Status Telemetry Screen

Last updated: 2026-09-04

## Objective

Build and maintain a small standalone EdgeTX/FreedomTX telemetry script dedicated to autopilot status messages carried by ExpressLRS CRSF. It should replace the full iNav Lua Telemetry script on memory-constrained Tango 2 model profiles.

Suggested entry point:

`src/SCRIPTS/TELEMETRY/MavMsg.lua`

`MavMsg` is six characters, satisfying the OpenTX 2.3 telemetry-script filename limit.

## Critical architecture constraint

A second telemetry screen does **not** receive an independent Lua heap.

OpenTX documents telemetry scripts as permanent scripts started when the model loads. Their `background()` functions continue to run while their screens are hidden, and permanent mix/function/telemetry scripts share the same runtime environment. Therefore:

- Recommended: configure `MavMsg` as the only Lua telemetry script on the Tango 2 model.
- Acceptable: create a separate copy/model profile for message monitoring and switch models when needed. This unloads/reinitializes scripts but resets message history.
- Not acceptable on Tango 2: configure full iNav Lua Telemetry and `MavMsg` simultaneously. Both consume the same constrained heap.
- Also unsafe: let both scripts call `crossfireTelemetryPop()`. The raw CRSF queue has destructive pop semantics, so whichever script runs first can steal frames from the other.

A one-time script would gain memory because OpenTX suspends permanent scripts while it runs, but it cannot continuously collect status history in the background. It is useful only as an optional live diagnostic, not the primary design.

References:

- OpenTX telemetry-script lifetime: https://doc.open-tx.org/opentx-2-3-lua-reference-guide/part_i_-_script_type_overview/telemetry
- OpenTX permanent-script shared runtime: https://doc.open-tx.org/opentx-2-3-lua-reference-guide/part_vi_-_advanced_topics/lua_data_sharing_across_scripts
- OpenTX one-time script lifetime: https://doc.open-tx.org/opentx-2-3-lua-reference-guide/part_i_-_script_type_overview/one-time_scripts

## Validated input contract

Reuse the contract proven by the integrated proof of concept:

- Sole raw queue consumer: `crossfireTelemetryPop()`.
- Process at most eight queued frames per `background()` call.
- Current command `0x80`; accept legacy `0x7F`.
- Payload byte 1 must be subtype `0xF1`.
- Payload byte 2 is MAVLink severity.
- Payload bytes 3-52 contain at most 50 text bytes and may end with NUL.
- Reject malformed payloads and invalid byte values without allocating history entries.
- Do not implement MAVLink 2 chunk reassembly; ExpressLRS does not carry chunk IDs in this conversion.
- Ignore unrelated CRSF frames. Device-info parsing is unnecessary unless a later UI requirement needs it.

Validated source environment:

- ArduPilot flight controller.
- Matching ExpressLRS 4.1 TX/RX firmware.
- ELRS TX `Link Mode = MAVLink`.
- ArduPilot serial protocol MAVLink at 460800 baud (`SERIALx_PROTOCOL=2`, `SERIALx_BAUD=460`).
- TBS Tango 2 running FreedomTX.

## Minimal implementation shape

Prefer one source file and one stripped bytecode entry point. Do not use dynamic modules unless measurement proves they are needed.

Return the standard telemetry interface:

```lua
return {init=init, background=background, run=run}
```

Responsibilities:

- `init`: initialize fixed-size state only.
- `background`: drain up to eight raw frames and update bounded history even while the screen is hidden.
- `run(event)`: call the same bounded drain path, clear/redraw the screen, handle selection/horizontal offset, and return `0`.

Avoid dependencies known to fail or cost excessive memory on Tango 2:

- No global `table` library calls; FreedomTX on the test radio does not expose it.
- No source compilation on-radio; distribute stripped bytecode.
- No `loadScript()` module graph for the first version.
- No growing debug strings, unbounded queues, message reassembly, bitmaps, localization tables, or telemetry sensor discovery.
- No device-info parser unless it becomes essential.

## Data and UI contract

- Retain newest 20 messages initially; reduce only if a standalone soak test proves it necessary.
- Adjacent equal text/severity within three seconds increments `xN`.
- Newest message first.
- Severity labels: `EMR`, `ALR`, `CRT`, `ERR`, `WRN`, `NOT`, `INF`, `DBG`; prefix critical severities with `!`.
- Calculate visible rows from runtime `LCD_H`; do not assume 128x64.
- Keep one selected row. Short next/previous changes the selected row and resets horizontal offset.
- Horizontal offset must remain between zero and the selected row's measured maximum.
- Support virtual inc/dec, raw plus/minus, and repeat events until the Tango's actual mapping is recorded.
- Enter may reset horizontal offset. Do not consume the radio's telemetry-screen navigation key unnecessarily.
- Show an empty state without using `CENTERED`, which is absent on the tested FreedomTX build.
- The screen itself is the viewer, so no transient popup is required.

## Reuse from this branch

Reference, then simplify rather than importing modules at runtime:

- `src/SCRIPTS/TELEMETRY/iNav/status.lua`: validated CRSF parsing, deduplication, severity handling, 20-entry eviction, and eight-frame drain bound.
- `src/SCRIPTS/TELEMETRY/iNav/messages.lua`: runtime-height rows, newest-first rendering, and bounded horizontal slicing.
- `tests/status_test.lua`: malformed frame, 50-byte, legacy command, deduplication, eviction, and queue-bound cases.
- `tests/messages_test.lua`: 128x64, 128x96, 212x64, and color render coverage.

Do not copy the iNav dispatcher lifecycle, ELRS device-info handling, popup, menu, view loading, flight telemetry state, Pilot/Radar renderers, audio logic, or configuration system.

## Test plan

Add a dedicated standalone test, for example `tests/mavmsg_test.lua`, and a Make target.

Automated coverage:

1. No telemetry and empty history.
2. Valid `0x80/0xF1` and legacy `0x7F/0xF1` frames.
3. Malformed payloads, NUL termination, and exactly 50 bytes.
4. Severity labels and critical marker.
5. Three-second adjacent deduplication without extending unrelated state.
6. Twenty-entry in-place eviction with `table = nil`.
7. Eight-frame maximum drain per callback.
8. 128x64 and 128x96 row calculation.
9. Every candidate Tango key-event mapping.
10. Horizontal lower/upper bounds and reset after vertical movement.
11. Repeated render/drain cycles without retained temporary strings.

Hardware acceptance on a model with full iNav Lua Telemetry disabled:

1. Clean-install stripped `MavMsg.lua` bytecode.
2. Confirm the empty screen loads with substantial memory headroom.
3. Leave it hidden while injecting messages; open it and confirm history accumulated via `background()`.
4. Identify and record the exact Tango vertical and horizontal controls.
5. Verify short, repeated, critical, and 50-byte messages.
6. Generate more than 20 distinct messages and confirm stable eviction.
7. Run sustained live MAVLink traffic and repeated screen navigation for at least 15 minutes.
8. Confirm no `not enough memory`, nil call, or raw-queue conflict.

## Packaging

Produce a minimal archive containing only the standalone telemetry entry point required on the radio, preferably:

`SCRIPTS/TELEMETRY/MavMsg.lua`

The `.lua`-named file in the radio package must contain stripped Lua bytecode, not source. Keep readable source in this repository. Verify the Lua magic header and publish a SHA-256 checksum for every hardware candidate.

## Immediate next-session plan

1. Create a `standalone-mavlink-messages` branch from the pushed proof-of-concept branch.
2. Implement single-file `MavMsg.lua` by extracting only the validated parser/history/render logic.
3. Add the standalone automated test and package target.
4. Measure stripped bytecode size and simulator heap before adding optional features.
5. Build the minimal package and test it as the only configured telemetry script on Tango 2.
