# GU drawn-fix report (sk.lua DrawNCards stall)

Branch: qs-claude/gu-verify-fix2-20261015. Only `extensions/sk.lua` changed.

## Cause
In this engine DrawNCards data is a DrawStruct (`data:toDraw()`, field `num`, `reason`). Skills that did
`setValue(original_data:toInt() + n)` read 0 and overwrote the draw count with `n`/0. `sk_quji` is `global = true`
and ran this for every player on every draw, so everyone drew 0 and the AI game stalled.

## Fixed (pattern now `local draw = ctx.original_data:toDraw(); draw.num = draw.num + n; ctx.original_data:setValue(draw)`,
same as sk_zhongyong / sk_xingbu / sk_anguo in this file)
| skill | note |
|---|---|
| sk_quji | global on_record; now only adds when `&sk_quji_draw` > 0 and `draw.reason == "draw_phase"` |
| sk_shemi | +1 |
| sk_huaiyi | + length of pile sk_yi |
| sk_jingce | + `&sk_jingce_draw` mark |
| sk_juyi | + `&sk_juyi` mark |

## Grep audit
All `DrawNCards` uses in sk.lua: lines ~2122 (sk_zhongyong), ~7356 (sk_xingbu), ~9393 (sk_anguo) already used
toDraw()/draw.num correctly; the 5 above were the only toInt() users. Remaining `toInt()` hits in sk.lua are
`ctx.extra_data:toInt()` (card ids / points), unrelated to DrawNCards. No other occurrences.

## Verification
`luac5.1 -p extensions/sk.lua` passes (syntax only). No game run performed.
