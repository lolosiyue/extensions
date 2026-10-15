# resolve4.md — extensions/offline.lua conflict resolution

## What was merged
Resolved all 8 conflict blocks in `extensions/offline.lua` when incoming commit
`5b91966` was merged into the current HEAD (`qs-command-code/gu-integrate-20261015`).

- HEAD side (the `A` blocks): the diyba batches (b01-b21) and the appended sheji
  `extension_sj` batches (b01-b09).
- Incoming side (the `B` blocks, `5b91966`): the huanle `extension_hl` batches
  `c203_04` ... `c217_03`, i.e. the continuation of the huanle chapters already started
  in the common `c201` ... `c203_03` prefix.

## Why the conflicts looked interleaved
Each block was an append/append conflict, but git's diff matched repeated boilerplate
lines as *common*. Those shared lines sit between `>>>>>>> 5b91966` and the next
`<<<<<<< HEAD` (call them `C1` ... `C7`). They are required by BOTH sides: they continue
or close the last definition of the HEAD side and the last definition of the incoming side.

## Resolution applied
Every open definition was completed with the shared lines it needs, so each side is kept
completely, HEAD first:

    HEAD region     = A1 C1 A2 C2 A3 C3 A4 C4 A5 C5 A6 C6 A7 C7 A8
    incoming region = B1 C1 B2 C2 B3 C3 B4 C4 B5 C5 B6 C6 B7 C7 B8

    file = common prefix (c201 ... c203_03)
         + HEAD region
         + incoming region
         + one final return

All conflict markers were removed. The stub `return { ... }` at the end of each side was
dropped and replaced by exactly one final statement.

## Cross-side duplicate definitions
- top-level assignment names defined on BOTH sides: none
- sgs.General names defined on BOTH sides: none
- local function names defined on BOTH sides: none

No exact-duplicate definition (general name, skill/object variable, or helper) appears on both sides, so both sides are kept in full; nothing was replaced by the incoming huanle version.

## Return statement

    return { extension, extension_card, extension_wz, extension_hl, extension_sj }

## Checks
- conflict markers remaining: 0
- top-level `return {` statements: exactly 1 (the final one)
- original line count: 29903
- resolved line count: 29910
- HEAD region lines: 1813
- incoming region lines: 18567

