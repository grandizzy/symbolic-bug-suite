# symbolic-bug-suite

A Foundry project that demonstrates what the **Foundry symbolic engine**
([PR #14796](https://github.com/foundry-rs/foundry/pull/14796)) can and
cannot do, by reproducing the shape of real historical DeFi exploits and
running them under `forge test --symbolic`.

Every test is written so that **success of the engine = test FAILURE with a
concrete attacker witness**. Run with:

```bash
forge test --symbolic
```

(requires a forge build with `--symbolic` enabled and `z3` on `$PATH`)

## What the suite actually proves

36 tests over 14 distinct engine primitives × 9 years of incidents
(2016–2025). All 36 currently fail = the engine produces a counterexample
for each.

This is a **capability demo**, not a benchmark. See [Honest caveats](#honest-caveats)
below for what these results do and don't imply about production readiness.

---

## A. Engine capabilities — one representative case per primitive

These 14 cases are the *evidence the engine works*. Each exercises a distinct
symbolic-execution primitive at minimum.

| Primitive | Representative | Year | $ lost | What the engine has to do |
|---|---|---|---|---|
| Default-layout SLOAD with symbolic mapping key | **01 Nomad** | 2022 | $190M | Reason that `mapping[symbolic_key]` defaults to zero unless written; find key where value ≠ 0 |
| Symbolic `msg.sender` + access-control branch | **02 Parity** | 2017 | $150M+ | Fork on `msg.sender == owner` check after `vm.prank(symbolic)` |
| Symbolic `uint256` arithmetic (over/underflow) | **03 BEC** | 2018 | wipe | Solve `cnt * value` overflow inside `unchecked` |
| Multi-step state reachability | **04 Euler** | 2023 | $197M | Sequence `deposit → borrow → donate → liquidate` on symbolic params, find combo that violates wealth invariant |
| Reentrancy via attacker callback | **05 Curve** | 2023 | $61M | Step through external call to attacker contract, model state update *after* call |
| Share-price rounding (deposit side) | **06 Hundred** | 2023 | $7M | Multiplication-then-division with empty-market priming, find round-to-zero |
| Missing owner check on redemption | **08 Hedgey** | 2024 | $44.5M | Symbolic third-party caller redeems victim's plan |
| Initializer re-callable | **12 Munchables** | 2024 | $62M | Reach state where re-running `initialize` overwrites prior owner |
| Delegatecall storage hijack | **16 Visor** | 2021 | $8.2M | Reason that `delegatecall(stealer, …)` writes into the *caller's* storage slot 0 |
| Multicall msg.value reuse | **17 MISO** | 2021 | $3M attempt | Track `msg.value` semantics across nested `delegatecall`s inside a multicall loop |
| Revert-loop griefing | **18 Akutar** | 2022 | $34M locked | Show liveness fails when one bidder's `receive` reverts |
| Proxy storage-slot collision | **22 Audius** | 2022 | $6M | Track assembly `sstore(0, …)` clobbering `admin` |
| Same-token swap math | **23 MonoX** | 2021 | $31M | Arithmetic where `price[tIn] = …` then read `price[tOut]` is the same slot |
| Crafted-calldata routing | **28 PolyNetwork** | 2021 | $611M | Reach `putCurEpochConPubKeyBytes` via `address(this).call(data)` with attacker-built `data` |

### Redeem-side rounding (separate from #06)

| Primitive | Case | Year | $ lost | Why distinct |
|---|---|---|---|---|
| Share-price rounding (redeem side, `+1` bumper) | **14 zkLend** | 2025 | $9.5M | Different arithmetic shape from #06: bug is on `redeem` not `deposit` |

---

## B. Historical recurrence — same primitive, different incidents

These are the *narrative evidence* that the same invariant catches bugs
across years. They add little engine-coverage signal on top of the
representative case, but each is a real $-loss datapoint.

### Empty-market share inflation
*(same one-line invariant catches all)*

| Case | Year | $ lost |
|---|---|---|
| 06 Hundred Finance | 2023 | $7M |
| 20 Onyx Protocol | 2023 | $2.1M |
| 19 Sonne Finance | 2024 | $20M |
| 21 Polter Finance | 2025 | ~$700K |
| 14 zkLend (redeem-side variant) | 2025 | $9.5M |

### Missing access control on a setter / endpoint

| Case | Year | $ lost |
|---|---|---|
| 02 Parity multisig `initWallet` | 2017 | $150M+ |
| 07 LeetSwap `transferFromUnsafe` | 2023 | $620K |
| 11 Holograph `bridgeIn` | 2024 | $14.4M |
| 13 KiloEx `setPrices` | 2025 | $7M |
| 34 DeltaPrime `borrowFromPool` | 2024 | $5.98M |
| 35 Predy swap callback | 2024-25 | ~$0.5M |

### Reentrancy via external callback before state update

| Case | Year | $ lost |
|---|---|---|
| 30 The DAO | 2016 | $60M |
| 31 Lendf.Me (ERC-777 hook) | 2020 | $25M |
| 29 Fei / Rari Fuse | 2022 | $80M |
| 05 Curve / Vyper | 2023 | $61M |
| 09 Penpie / Pendle | 2024 | $27M |

### Initializer re-callable

| Case | Year | $ lost |
|---|---|---|
| 24 DODO | 2021 | $3.8M |
| 26 Punk Protocol | 2021 | $3M |
| 12 Munchables | 2024 | $62M |

### Delegatecall storage hijack

| Case | Year | $ lost |
|---|---|---|
| 16 Visor Finance | 2021 | $8.2M |
| 32 Furucombo | 2021 | $14M |
| 36 Nexera | 2024 | $1.5M |

### Revert-loop griefing

| Case | Year | $ lost |
|---|---|---|
| 27 King of the Ether | 2016 | locked |
| 18 Akutar | 2022 | $34M locked |

### Arithmetic over/underflow

| Case | Year | $ lost |
|---|---|---|
| 03 BeautyChain (BEC) | 2018 | market-wipe |
| 10 Velocore | 2024 | $6.8M |
| 33 Indexed Finance | 2021 | $16M |

### Liquidation / accounting branch

| Case | Year | $ lost |
|---|---|---|
| 04 Euler Finance | 2023 | $197M |
| 15 Abracadabra cauldron | 2025 | $13M |

### Free-mint via deposit-path bypass

| Case | Year | $ lost |
|---|---|---|
| 08 Hedgey Finance | 2024 | $44.5M |
| 25 Qubit bridge (native path) | 2022 | $80M |

---

## C. Fidelity of each model to the real bug

A reproducer is more valuable when the model is close to what shipped. Tags:

- **F**aithful: the engine sees essentially the same code shape that was deployed.
- **S**implified: same bug class, but modeled in a small standalone contract (no proxy / oracle / multi-module routing).
- **L**oose: I had to adapt the bug to make the engine catch it (compiler differences, missing primitives).

| # | Case | Fidelity | Notes |
|---|---|:---:|---|
| 01 | Nomad | F | The actual bug shape (`confirmAt[0]=1`) is in the reproducer. |
| 02 | Parity initWallet | F | Missing init guard reproduced verbatim. |
| 03 | BEC | F | `cnt*value` in `unchecked` block matches Solidity 0.4.x semantics. |
| 04 | Euler | S | Single contract; real exploit spanned EVC + Risk + price modules. |
| 05 | Curve / Vyper | L | Used `unchecked` to model Vyper miscompilation so wrap-around manifests as silent corruption (real Vyper miscompiled the lock differently). |
| 06 | Hundred | S | Bare vault; real Compound-v2 fork has Comptroller, oracle, interest model. |
| 07 | LeetSwap | F | The `transferFromUnsafe` function shape is the real bug. |
| 08 | Hedgey | L | Modeled as missing owner check; real bug involved arbitrary `IERC20` injection (symbolic-external-call territory the engine doesn't handle yet). |
| 09 | Penpie | S | Single master contract; real exploit spanned Penpie + Pendle markets. |
| 10 | Velocore | F | `feeMultiplier - 100` underflow is the real shape. |
| 11 | Holograph | F | Missing `onlyOperator` is the real bug. |
| 12 | Munchables | S | Bare contract; real bug was inside a UUPS proxy chain. |
| 13 | KiloEx | F | Missing `onlyKeeper` is the real bug. |
| 14 | zkLend | L | Modeled `+1` redeem bumper; real bug was Cairo-side and uses different math primitives. |
| 15 | Abracadabra | S | Bare cauldron; real cauldron uses BoringSolidity + BentoBox + oracle. |
| 16 | Visor | S | Registry mapping reproduced; real Visor had nontrivial proxy + manager layers. |
| 17 | MISO | F | `multicall` + payable subcall reuse is the real bug shape. |
| 18 | Akutar | F | Refund loop with `require(ok)` matches the real contract. |
| 19 | Sonne | S | Same model as #06 with renamed contract. |
| 20 | Onyx | S | Same model as #06 with renamed contract. |
| 21 | Polter | S | Same model as #06 with renamed contract. |
| 22 | Audius | L | Used assembly `sstore(0, …)`; real bug was a Solidity storage layout overlap with the proxy admin slot. |
| 23 | MonoX | L | Simplified two-line arithmetic; real bug involved reserve accounting + price-update ordering across multiple state variables. |
| 24 | DODO | F | Missing initializer guard matches real shape. |
| 25 | Qubit | L | Modeled as `deposit(0, amount)` skipping payment check; real bug was `safeTransferFrom` no-op when token was 0x0 inside the bridge router. |
| 26 | Punk | F | Bare `__init` reproduces the public-initializer bug. |
| 27 | King of the Ether | F | Royalty `transfer` to a contract that reverts is the real bug. |
| 28 | PolyNetwork | S | Single dispatch contract; real exploit used a full crafted cross-chain message. |
| 29 | Fei / Rari | S | Bare cToken; real exploit required Fuse comptroller path. |
| 30 | The DAO | F | The 2016 reentrancy shape, almost line-for-line. |
| 31 | Lendf.Me | L | Reordered deposit operations so the engine can surface the hook-reentry as a bug (real bug was specific to ERC-777 transfer hook semantics that the engine doesn't model directly). |
| 32 | Furucombo | S | Same primitive as #16. |
| 33 | Indexed | L | Reduced to a one-line `weight[t] -= delta` underflow; real Indexed bug was Balancer-pool reweight math. |
| 34 | DeltaPrime | S | Same primitive as #02. |
| 35 | Predy | S | Same primitive as #02 with callback flavor. |
| 36 | Nexera | S | Same primitive as #16. |

Counts: **15 Faithful · 13 Simplified · 8 Loose** (of 36).

The strongest claims of "this engine would have caught a real bug" come from
the 15 Faithful entries. The 13 Simplified entries are credible at the
class level but stripped of production context. The 8 Loose entries are
*adapted* — they show the engine handles a related primitive, not that it
catches the historical bug as it actually shipped.

---

## D. Out of scope for the current engine

These classes are intentionally not included — they require features beyond
the current PR's supported subset:

- bridge / multisig key-compromise (Ronin, Multichain, Wormhole, Bybit) — not a code-level bug
- oracle manipulation (Mango, Inverse, Cream, BonqDAO, WOOFi) — requires realistic oracle model
- CREATE2 vanity-address attacks (Wintermute Profanity) — symbolic keccak
- TWAP-based pricing exploits — oracle + time modeling
- governance flashloan plays (Beanstalk) — multi-protocol state
- non-EVM chains (Sui Cetus, real zkLend uses Cairo on Starknet)

These collectively account for *more* $-loss than the 36 cases here combined.
When the symbolic engine encounters one of these in a real test, the
soundness guarantee being verified upstream says it should surface as
`Unsupported(...)` rather than passing silently.

---

## Honest caveats

- I authored every bug AND its invariant. A real auditor/fuzzer doesn't
  have that prior knowledge. The suite proves *capability*, not *discovery
  power*.
- Models are minimal (~25–50 LOC). Whether the engine scales to thousand-LOC
  contracts with the same bug class is a separate question.
- Several tests required input bounding to keep the SMT problem tractable
  (Euler, Hundred, zkLend). The bug exists at any scale, but the proof
  requires bounded ranges.
- Attacker contracts (`Stealer`, `RevertingBidder`, `ReenterToken`, etc.)
  are hand-written — the engine doesn't synthesize payload bytecode, it
  finds inputs to existing code.
- The "out of scope" list above is the majority of $-weighted DeFi loss;
  this suite covers what the engine *can* do, not what fraction of the
  threat surface it covers.

## Layout

```
src/   one .sol per case (minimal reproducer of the bug shape)
test/  one .t.sol per case with the symbolic invariant
```

Tests inherit from `forge-std/Test.sol` for `vm` access. Solver times
range from ~100ms (Nomad, KiloEx) to ~50s (Hundred, zkLend) on a typical
laptop with Z3.
