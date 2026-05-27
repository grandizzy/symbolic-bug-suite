# symbolic-bug-suite

A Foundry project demonstrating what the **Foundry symbolic engine**
([PR #14796](https://github.com/foundry-rs/foundry/pull/14796)) can and
cannot do, by reproducing the shape of real historical DeFi exploits
under `forge test --symbolic`.

Each test is written so that **engine success = test FAILURE with a
concrete attacker witness**. 36 tests covering 14 distinct engine
primitives across incidents from 2016 to 2025; all 36 currently fail
(= caught).

```bash
forge test --symbolic
```

(requires a forge build with `--symbolic` enabled and `z3` on `$PATH`)

## Engine capabilities

One representative case per primitive — the evidence the engine works.

| Primitive | Representative | Year | $ lost |
|---|---|---|---|
| Default-layout SLOAD with symbolic mapping key | 01 Nomad | 2022 | $190M |
| Symbolic `msg.sender` + access-control branch | 02 Parity | 2017 | $150M+ |
| Symbolic `uint256` arithmetic (over/underflow) | 03 BEC | 2018 | wipe |
| Multi-step state reachability | 04 Euler | 2023 | $197M |
| Reentrancy via attacker callback | 05 Curve | 2023 | $61M |
| Share-price rounding (deposit side) | 06 Hundred | 2023 | $7M |
| Missing owner check on redemption | 08 Hedgey | 2024 | $44.5M |
| Initializer re-callable | 12 Munchables | 2024 | $62M |
| Share-price rounding (redeem side) | 14 zkLend | 2025 | $9.5M |
| Delegatecall storage hijack | 16 Visor | 2021 | $8.2M |
| Multicall `msg.value` reuse | 17 MISO | 2021 | $3M attempt |
| Revert-loop griefing | 18 Akutar | 2022 | $34M locked |
| Proxy storage-slot collision | 22 Audius | 2022 | $6M |
| Same-token swap math | 23 MonoX | 2021 | $31M |
| Crafted-calldata routing | 28 PolyNetwork | 2021 | $611M |

The remaining 21 cases are additional historical incidents covering the
same primitives; see [`src/`](src) and the per-case NatSpec for details.

## Fidelity

Each case is tagged on how close the reproducer is to what shipped.

- **Faithful** — engine sees essentially the same code shape that was deployed.
- **Simplified** — same bug class, but modeled in a small standalone contract
  (no proxy / oracle / multi-module routing).
- **Loose** — bug shape adapted to make the engine catch it (compiler
  differences or missing engine primitives).

| # | Case | Fidelity | Notes |
|---|---|:---:|---|
| 01 | Nomad | F | The actual bug shape (`confirmAt[0]=1`) is in the reproducer. |
| 02 | Parity initWallet | F | Missing init guard reproduced verbatim. |
| 03 | BEC | F | `cnt*value` in `unchecked` block matches Solidity 0.4.x semantics. |
| 04 | Euler | S | Single contract; real exploit spanned EVC + Risk + price modules. |
| 05 | Curve / Vyper | L | Used `unchecked` to model the Vyper miscompilation so wrap-around manifests as silent corruption. |
| 06 | Hundred | S | Bare vault; real Compound-v2 fork has Comptroller, oracle, interest model. |
| 07 | LeetSwap | F | The `transferFromUnsafe` function shape is the real bug. |
| 08 | Hedgey | L | Modeled as missing owner check; real bug involved arbitrary `IERC20` injection. |
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
| 19 | Sonne | S | Same model as 06 with renamed contract. |
| 20 | Onyx | S | Same model as 06 with renamed contract. |
| 21 | Polter | S | Same model as 06 with renamed contract. |
| 22 | Audius | L | Used assembly `sstore(0, …)`; real bug was a Solidity storage layout overlap with the proxy admin slot. |
| 23 | MonoX | L | Simplified two-line arithmetic; real bug involved reserve accounting + price-update ordering across multiple state variables. |
| 24 | DODO | F | Missing initializer guard matches real shape. |
| 25 | Qubit | L | Modeled as `deposit(0, amount)` skipping payment; real bug was `safeTransferFrom` no-op when token was 0x0 inside the bridge router. |
| 26 | Punk | F | Bare `__init` reproduces the public-initializer bug. |
| 27 | King of the Ether | F | Royalty `transfer` to a contract that reverts is the real bug. |
| 28 | PolyNetwork | S | Single dispatch contract; real exploit used a full crafted cross-chain message. |
| 29 | Fei / Rari | S | Bare cToken; real exploit required Fuse comptroller path. |
| 30 | The DAO | F | The 2016 reentrancy shape, almost line-for-line. |
| 31 | Lendf.Me | L | Reordered deposit operations so the engine can surface the hook-reentry; real bug was specific to ERC-777 transfer hook semantics. |
| 32 | Furucombo | S | Same primitive as 16. |
| 33 | Indexed | L | Reduced to a one-line `weight[t] -= delta` underflow; real Indexed bug was Balancer-pool reweight math. |
| 34 | DeltaPrime | S | Same primitive as 02. |
| 35 | Predy | S | Same primitive as 02 with callback flavor. |
| 36 | Nexera | S | Same primitive as 16. |

Counts: **13 Faithful · 15 Simplified · 8 Loose** (of 36).

The strongest "would have caught a real bug" claims come from the
Faithful entries. Simplified entries are credible at the class level
but stripped of production context. Loose entries show the engine
handles a related primitive, not the bug as shipped.

## Out of scope

These classes are excluded — they require features beyond the current
PR's supported subset:

- bridge / multisig key-compromise (Ronin, Multichain, Wormhole, Bybit) — not a code-level bug
- oracle manipulation (Mango, Inverse, Cream, BonqDAO, WOOFi) — requires realistic oracle model
- CREATE2 vanity-address attacks (Wintermute Profanity) — symbolic keccak
- TWAP-based pricing exploits — oracle + time modeling
- governance flashloan plays (Beanstalk) — multi-protocol state
- non-EVM chains (Sui Cetus, Starknet zkLend)

These collectively account for more $-loss than the 36 cases here.
When the engine encounters one in a real test, the upstream soundness
guarantee says it should surface as `Unsupported(...)` rather than
pass silently.

## Caveats

- Bugs and invariants were authored *with knowledge of the historical exploit*.
  A real auditor or fuzzer would not have that prior. The suite proves
  *capability*, not *discovery power*.
- Models are minimal (~25–50 LOC). Whether the engine scales to thousand-LOC
  contracts with the same bug class is a separate question.
- Several tests required input bounding to keep the SMT problem tractable
  (Euler, Hundred, zkLend). The bug exists at any scale; the proof requires
  bounded ranges.
- Attacker contracts (`Stealer`, `RevertingBidder`, `ReenterToken`, etc.)
  are hand-written. The engine finds inputs to existing code, not new
  bytecode for the attacker payload.

## Layout

```
src/   one .sol per case (minimal reproducer of the bug shape)
test/  one .t.sol per case with the symbolic invariant
```

Tests inherit from `forge-std/Test.sol` for `vm` access. Solver times
range from ~100ms (Nomad, KiloEx) to ~50s (Hundred, zkLend) on a typical
laptop with Z3.
