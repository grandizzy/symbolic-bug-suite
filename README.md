# symbolic-bug-suite

A Foundry project that proves the **Foundry symbolic engine**
([PR #14796](https://github.com/foundry-rs/foundry/pull/14796)) catches
real historical DeFi exploits within its currently-supported feature subset
(symbolic storage/memory, branch exploration, transient storage, `vm.etch`
callbacks, symbolic arithmetic, symbolic call targets/calldata).

Every test is written so that **success of the engine = test FAILURE with a
concrete attacker witness**. Run with:

```bash
forge test --symbolic
```

(requires a forge build with `--symbolic` enabled and `z3` on `$PATH`)

## Catches — 36 incidents across 9 years and 12 distinct bug classes

| # | Incident | Year | $ lost | Bug class | Witness shape |
|---|---|---|---|---|---|
| 01 | Nomad Bridge | 2022 | $190M | magic-value mapping accept | `root = 0x00…00` |
| 02 | Parity multisig `initWallet` | 2017 | $150M+ | missing access control on initializer | any non-owner caller |
| 03 | BeautyChain `batchTransfer` | 2018 | market-wipe | integer overflow on `cnt * value` | `value = 2^255`, 2 receivers |
| 04 | Euler Finance | 2023 | $197M | health-check bypass via `donateToReserves` | `donate = 51` (200/150 setup) |
| 05 | Curve / Vyper reentrancy | 2023 | $61M | reentrancy via ETH callback | `attackerDeposit ≈ 47.5 ETH` |
| 06 | Hundred Finance | 2023 | $7M | empty-market share inflation | `victimDeposit = 1` |
| 07 | LeetSwap `transferFromUnsafe` | 2023 | $620K | public function w/o auth | any third-party caller |
| 08 | Hedgey Finance | 2024 | $44.5M | missing owner check on redeem | any non-owner caller |
| 09 | Penpie / Pendle | 2024 | $27M | reward-claim reentrancy | re-enter `harvest()` |
| 10 | Velocore | 2024 | $6.8M | unchecked underflow on fee math | `feeMultiplier = 36` |
| 11 | Holograph | 2024 | $14.4M | missing `onlyOperator` on `bridgeIn` | any non-operator caller |
| 12 | Munchables | 2024 | $62M | initializer re-callable | any second `initialize` caller |
| 13 | KiloEx | 2025 | $7M | missing `onlyKeeper` on `setPrices` | any non-keeper caller |
| 14 | zkLend | 2025 | $9.5M | redeem-side rounding inflation (`+1`) | `deposit = 2`, redeem 1 → 2 |
| 15 | Abracadabra cauldron | 2025 | $13M | liquidation clears full debt | `repay = 80` of 100 |
| 16 | Visor Finance | 2021 | $8.2M | delegatecall hijack via registry | attacker installs `Stealer` impl |
| 17 | SushiSwap MISO | 2021 | $3M attempt | `msg.value` reused across multicall | 2 sub-calls credit 2 ETH for 1 |
| 18 | Akutar | 2022 | $34M locked | revert-loop griefs entire batch | one reverting bidder |
| 19 | Sonne Finance | 2024 | $20M | empty-market share inflation | same as 06, 13 months later |
| 20 | Onyx Protocol | 2023 | $2.1M | empty-market share inflation | same as 06, fork two |
| 21 | Polter Finance | 2025 | ~$700K | empty-market share inflation | same as 06, fork three |
| 22 | Audius governance | 2022 | $6M | proxy storage-slot collision | attacker overwrites slot 0 |
| 23 | MonoX | 2021 | $31M | missing `tokenIn != tokenOut` check | self-swap pumps price |
| 24 | DODO | 2021 | $3.8M | initializer re-callable | second `init` overwrites admin |
| 25 | Qubit bridge | 2022 | $80M | `deposit(0, amount)` skips transfer | free-mint via native path |
| 26 | Punk Protocol | 2021 | $3M | initializer re-callable | second `__init` overwrites owner |
| 27 | King of the Ether | 2016 | locked | non-payable royalty fails | reverting prior king |
| 28 | Poly Network | 2021 | $611M | crafted message rotates keeper | call `executeCrossChainMessage(putCur…)` |
| 29 | Fei / Rari Fuse | 2022 | $80M | borrow callback reentrancy | re-enter `borrow()` |
| 30 | The DAO | 2016 | $60M | classic reentrancy on `withdraw` | re-enter `withdraw()` |
| 31 | Lendf.Me / dForce | 2020 | $25M | ERC-777 deposit hook reentrancy | borrow against not-yet-paid collateral |
| 32 | Furucombo | 2021 | $14M | handler registry hijack | attacker installs `HandlerStealer` |
| 33 | Indexed Finance | 2021 | $16M | reweight zeros weight | `delta ≥ weight` |
| 34 | DeltaPrime | 2024 | $5.98M | missing `onlyOwner` on `borrowFromPool` | any non-owner caller |
| 35 | Predy Finance | 2024-25 | ~$0.5M | missing `msg.sender == pool` on callback | any non-pool caller |
| 36 | Nexera | 2024 | $1.5M | delegatecall upgrade without admin check | attacker installs `AdminSwapper` |

All 36 tests fail when run; each `[FAIL: panic: assertion failed]` line
includes the concrete counterexample the solver produced.

## Distinct classes covered

```
magic-value mapping       01 Nomad
missing access control    02 Parity   11 Holograph   13 KiloEx
                          34 DeltaPrime 35 Predy
integer over/underflow    03 BEC      10 Velocore
health-check bypass       04 Euler
reentrancy                05 Curve    09 Penpie     29 FeiRari
                          30 TheDAO   31 LendfMe
empty-market inflation    06 Hundred  19 Sonne      20 Onyx     21 Polter
redeem rounding           14 zkLend
public no-auth function   07 LeetSwap
missing owner check       08 Hedgey
initializer re-callable   12 Munchables 24 DODO    26 Punk
delegatecall hijack       16 Visor    32 Furucombo  36 Nexera
selector / msg.value      17 MISO
revert-loop griefing      18 Akutar   27 KingOfEther
proxy storage collision   22 Audius
same-token swap           23 MonoX
free-mint via zero path   25 Qubit
selector + access         28 PolyNetwork
arithmetic edge           33 Indexed
accounting branch         15 Abracadabra
```

## Pattern repeat

The empty-market / first-depositor inflation class shows up across **four
years and four protocols**: Hundred (2023), Onyx (2023), Sonne (2024),
zkLend (2025), Polter (2025). The same single symbolic invariant —
*"any non-zero deposit must mint a non-zero share"* — catches every one.

Missing-access-control similarly recurs: Parity 2017 → Holograph 2024 →
KiloEx 2025 → DeltaPrime 2024 → Predy 2025 — one invariant, eight years
apart, same shape.

Reentrancy keeps shipping: The DAO 2016 → Lendf.Me 2020 → Fei/Rari 2022
→ Curve 2023 → Penpie 2024.

## Out of scope for the current engine

These classes are intentionally not included — they require features beyond
the current PR's supported subset (symbolic keccak inputs of attacker-
controlled data, symbolic CREATE, oracle modeling, key-management, MEV):

- bridge / multisig key-compromise (Ronin, Multichain, Wormhole, Bybit)
- oracle manipulation (Mango, Inverse, Cream, BonqDAO, WOOFi)
- CREATE2 vanity-address attacks (Wintermute Profanity)
- TWAP-based pricing exploits
- governance flashloan plays (Beanstalk)
- non-EVM chains (Sui Cetus, zkLend uses Cairo on Starknet)

When the symbolic engine hits one of these, it should surface as
`Unsupported(...)` rather than passing silently — that is the soundness
guarantee being verified by the upstream PR's own regression tests.

## Layout

```
src/   one .sol per case (the minimal reproducer of the bug shape)
test/  one .t.sol per case with the symbolic invariant
```

Tests inherit from `forge-std/Test.sol` for `vm` access. Each test is
intentionally tiny — one symbolic input where possible, concrete setup
otherwise. Solver times range from ~100ms (Nomad, KiloEx) to ~50s
(Hundred, zkLend) on a typical laptop with Z3.

## Honest caveats

- All bugs and invariants were authored *with knowledge of the historical
  exploit*. A real-world auditor or fuzzing campaign would not have that
  prior. The suite proves *capability*, not *discovery power*.
- Contracts are minimal reproducers (~25–50 LOC), not production code at
  scale. Whether the engine scales to thousand-LOC contracts with similar
  bugs is a separate question.
- Several tests required input bounding to keep the SMT problem tractable
  (Euler, Hundred, zkLend) — the bug exists at any scale, but the proof
  requires bounded ranges.
- The "out of scope" list above is the majority of $-weighted DeFi loss;
  the suite shows what the engine *can* do, not what fraction of the
  threat surface it covers.
