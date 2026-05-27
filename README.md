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

| Tag | Count | Cases |
|---|---|---|
| Faithful | 13 | 01, 02, 03, 07, 10, 11, 13, 17, 18, 24, 26, 27, 30 |
| Simplified | 15 | 04, 06, 09, 12, 15, 16, 19, 20, 21, 28, 29, 32, 34, 35, 36 |
| Loose | 8 | 05, 08, 14, 22, 23, 25, 31, 33 |

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
