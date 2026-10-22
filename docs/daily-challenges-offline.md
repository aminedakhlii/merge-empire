# Daily challenges — offline clock behavior

Phase 2 daily challenges use the **device local calendar day** (`yyyy-MM-dd`).

## Safeguards

| Situation | Behavior |
|-----------|----------|
| Same local day | Continue current challenge progress |
| Clock jumps **backward** | Keep current challenge; do not reset progress (soft anti-rollback) |
| Next consecutive day | New challenge; activity streak +1 |
| Forward jump of 2+ days (`maxForwardJumpDays`) | New challenge; **streak resets** to 1 |
| Unique active days ≥ 7 | Unlocks `activity7Day` achievement |

## Limitations

- No server time authority — a determined player can still manipulate the device clock.
- Time zone changes that alter the calendar day are treated as a normal day change.
- Streak rewards are ordinary gameplay bonuses (coins), never ad-gated.

These limits are acceptable for an offline MVP; a future online backend could harden them.
