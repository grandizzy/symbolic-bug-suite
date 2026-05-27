# symbolic-bug-suite

A small Foundry project that proves the **Foundry symbolic engine**
([PR #14796](https://github.com/foundry-rs/foundry/pull/14796)) catches
real historical DeFi exploits within its currently-supported feature subset
(symbolic storage/memory, branch exploration, transient storage, vm.etch
callbacks, symbolic arithmetic).

Every test below is written so that **success of the engine = test FAILURE
with a concrete attacker witness**. Run with:

```bash
forge test --symbolic
```

(requires a forge build with `--symbolic` enabled and `z3` on `$PATH`)

## Catches

| # | Incident | Year | $ lost | Bug class | Witness |
|---|---|---|---|---|---|
| 01 | Nomad Bridge | 2022 | $190M | magic-value mapping accept | `root = 0x00…00` |
| 02 | Parity multisig `initWallet` | 2017 | $150M+ | missing access control on initializer | any non-owner caller |
| 03 | BeautyChain `batchTransfer` | 2018 | market-wipe | `cnt * value` integer overflow | `value = 2^255`, 2 receivers |
| 04 | Euler Finance | 2023 | $197M | health-check bypass via `donateToReserves` | `donate = 51` (200 collateral / 150 borrow setup) |
| 05 | Curve / Vyper reentrancy | 2023 | $61M | reentrancy via ETH callback before state update | `attackerDeposit ≈ 47.5 ETH` |
| 06 | Hundred Finance | 2023 | $7M | empty-market share inflation, victim rounds to 0 shares | `victimDeposit = 1` |
| 07 | LeetSwap `transferFromUnsafe` | 2023 | $620K | public function w/o auth or allowance check | any third-party caller |
| 08 | Hedgey Finance | 2024 | $44.5M | missing `msg.sender == owner` check on redeem | any non-owner caller |
| 09 | Penpie / Pendle | 2024 | $27M | reward-claim reentrancy via attacker-registered market | re-enter `harvest()` from callback |
| 10 | Velocore | 2024 | $6.8M | `feeMultiplier - 100` unchecked underflow | `feeMultiplier = 36` |
| 11 | Holograph | 2024 | $14.4M | missing `onlyOperator` on `bridgeIn` | any non-operator caller |
| 12 | Munchables | 2024 | $62M | initializer re-callable, upgrader stolen | any second `initialize` caller |
| 13 | KiloEx | 2025 | $7M | missing `onlyKeeper` on `setPrices` | any non-keeper caller |
| 14 | zkLend | 2025 | $9.5M | redeem-side rounding inflation (`+1` bumper) | `deposit = 2`, redeem 1 → 2 |
| 15 | Abracadabra cauldron | 2025 | $13M | liquidation clears full debt regardless of repay | `repay = 80` of 100 debt |

All 15 tests should fail when run; each `[FAIL: panic: assertion failed]`
line includes the concrete counterexample the solver produced.

## Pattern repeat

The empty-market / first-depositor inflation class shows up in 06 (Hundred,
2023) and again in 14 (zkLend, 2025). The same single symbolic invariant —
*"any non-zero deposit must mint a non-zero share, and any redeem must yield
at most its proportional asset value"* — catches both, and would also catch
Sonne, Onyx, and Polter Finance.

Missing-access-control similarly recurs (Parity 2017 → Holograph 2024 →
KiloEx 2025): one invariant, three years apart, same shape.

## Out of scope for the current engine

These classes are intentionally not included — they require features beyond
the current PR's supported subset (symbolic keccak inputs, symbolic CREATE,
oracle modeling, key-management, MEV):

- bridge / multisig key-compromise (Ronin, Multichain, Wormhole)
- oracle manipulation (Mango, Inverse, Cream, BonqDAO)
- CREATE2 vanity-address attacks (Wintermute Profanity)
- TWAP-based pricing exploits
- governance flashloan plays (Beanstalk)

When the symbolic engine hits one of these, it should surface as
`Unsupported(...)` rather than passing silently — that is the soundness
guarantee being verified by the upstream PR's own regression tests.

## Layout

```
src/   one .sol per case (the minimal reproducer of the bug shape)
test/  one .t.sol per case with the symbolic invariant
```

Each test is intentionally tiny: one symbolic input where possible,
concrete setup otherwise. Solver times range from ~100ms (Nomad, KiloEx)
to ~50s (zkLend, Hundred) on a typical laptop with Z3.
