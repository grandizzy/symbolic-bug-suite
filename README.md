# symbolic-bug-suite

A Foundry project demonstrating what the **Foundry symbolic engine**
([PR #14796](https://github.com/foundry-rs/foundry/pull/14796)) can do
that a regular unit test cannot — either by *discovering* an attacker
witness in an otherwise-untestable search space, or by *proving* a
universal property a single concrete test never could.

Each test is written so that **engine success = test FAILURE with a
concrete attacker witness**. 22 tests, all currently fail (= caught).

```bash
forge test --symbolic
```

(requires a forge build with `--symbolic` enabled and `z3` on `$PATH`)

## A. Cases where the engine *discovers* the attacker witness

These tests ask the engine to synthesize a concrete exploit witness. Some
require needle-in-a-haystack arithmetic values; others exercise stateful or
reentrant protocol flows over symbolic parameters.

| # | Case | Year | $ lost | Witness the solver must find |
|---|---|---|---|---|
| 01 | Nomad Bridge | 2022 | $190M | `root = 0x00…00` out of 2^256 |
| 03 | BeautyChain `batchTransfer` | 2018 | wipe | `value = 2^255` so `cnt * value` overflows |
| 04 | Euler Finance | 2023 | $197M | `donate` value crossing the health threshold |
| 06 | Hundred Finance | 2023 | $7M | `victimDeposit` that rounds to zero shares |
| 10 | Velocore | 2024 | $6.8M | `feeMultiplier < 100` out of 2^256 |
| 14 | zkLend | 2025 | $9.5M | redeem amount where `+1` bumper inflates payout |
| 15 | Abracadabra cauldron | 2025 | $13M | `repay < startBorrow` clearing full debt |
| 19 | Sonne Finance | 2024 | $20M | same primitive as 06, different incident |
| 20 | Onyx Protocol | 2023 | $2.1M | same primitive as 06, different incident |
| 21 | Polter Finance | 2025 | ~$700K | same primitive as 06, different incident |
| 23 | MonoX | 2021 | $31M | `amountIn` that triggers the self-swap math |
| 33 | Indexed Finance | 2021 | $16M | `delta ≥ weight` underflow |
| 34 | DEI / Deus DAO | 2023 | $6.5M | positive attacker approval that is rewritten as victim allowance |
| 35 | DFX Finance | 2022 | $7.5M | any positive in-liquidity flash amount that mints withdrawable LP |
| 36 | Fei/Rari Fuse | 2022 | $80M | valid collateralized borrow amount that opens the reentrant exit window |
| 37 | Uranium Finance | 2021 | $50M | branch selecting the drain-sized output accepted by the typo'd invariant |
| 38 | Platypus Finance | 2023 | $8.5M | solvent borrow amount that survives collateral emergency-withdrawal |
| 39 | Cover Protocol Blacksmith | 2020 | $4M+ | stake amount that claims rewards accrued before the stake existed |

## B. Cases where the engine *proves a universal property*

A unit test catches these for one concrete input. The symbolic engine
proves the bug holds across the entire input space — a stronger claim.

| # | Case | Year | $ lost | Universal property |
|---|---|---|---|---|
| 05 | Curve / Vyper reentrancy | 2023 | $61M | bug fires for *any* positive deposit |
| 17 | SushiSwap MISO | 2021 | $3M attempt | double-credit holds across multicall path |
| 18 | Akutar | 2022 | $34M locked | refund loop blocks for *any* bidder set including a reverter |
| 30 | The DAO | 2016 | $60M | reentrancy drains for *any* positive deposit |

## What the engine has to do

| Primitive | Cases |
|---|---|
| Default-layout SLOAD with symbolic mapping key | 01 Nomad |
| Symbolic `uint256` arithmetic (over/underflow / threshold) | 03 BEC · 10 Velocore · 33 Indexed |
| Multi-step state reachability with symbolic values | 04 Euler · 15 Abracadabra |
| Share-price rounding (deposit side) | 06 Hundred · 19 Sonne · 20 Onyx · 21 Polter |
| Share-price rounding (redeem side) | 14 zkLend |
| Same-token swap math | 23 MonoX |
| Reentrancy via attacker callback (universal-property) | 05 Curve · 30 The DAO |
| Allowance owner/spender reversal | 34 DEI |
| Side-entrance flash-loan accounting | 35 DFX |
| Borrow reentrancy before debt accounting | 36 Fei/Rari Fuse |
| AMM invariant typo | 37 Uranium |
| Post-withdraw solvency accounting | 38 Platypus |
| Stale reward-index accounting | 39 Cover |
| `msg.value` semantics across multicall | 17 MISO |
| Revert-loop griefing | 18 Akutar |

## Fidelity

How close each reproducer is to the deployed bug.

- **F**aithful — engine sees essentially the same code shape that shipped.
- **S**implified — same bug class, modeled in a small standalone contract.
- **L**oose — bug shape adapted to match what the engine can express.

| # | Case | Fidelity | Notes |
|---|---|:---:|---|
| 01 | Nomad | F | `confirmAt[0]=1` reproduced verbatim. |
| 03 | BEC | F | `cnt*value` in `unchecked` matches Solidity 0.4.x semantics. |
| 04 | Euler | S | Single contract; real exploit spanned EVC + Risk + price modules. |
| 05 | Curve / Vyper | L | Used `unchecked` to model the Vyper miscompilation so wrap-around manifests as silent corruption. |
| 06 | Hundred | S | Bare vault; real Compound-v2 fork has Comptroller, oracle, interest model. |
| 10 | Velocore | F | `feeMultiplier - 100` underflow is the real shape. |
| 14 | zkLend | L | Modeled `+1` redeem bumper; real bug was Cairo-side. |
| 15 | Abracadabra | S | Bare cauldron; real cauldron uses BoringSolidity + BentoBox + oracle. |
| 17 | MISO | F | `multicall` + payable subcall reuse is the real bug shape. |
| 18 | Akutar | F | Refund loop with `require(ok)` matches the real contract. |
| 19 | Sonne | S | Same model as 06 with renamed contract. |
| 20 | Onyx | S | Same model as 06 with renamed contract. |
| 21 | Polter | S | Same model as 06 with renamed contract. |
| 23 | MonoX | L | Simplified arithmetic; real bug involved reserve accounting + price-update ordering. |
| 30 | The DAO | F | The 2016 reentrancy shape, almost line-for-line. |
| 33 | Indexed | L | Reduced to one-line `weight[t] -= delta`; real Indexed bug was Balancer-pool reweight math. |
| 34 | DEI / Deus DAO | S | ERC20 allowance and `burnFrom` flow retained; governance/lossless-token scaffolding omitted. |
| 35 | DFX Finance | S | Keeps flash callback, repayment-by-balance check, LP mint, and post-flash withdrawal; omits multi-asset curve math. |
| 36 | Fei/Rari Fuse | S | Keeps collateral entry, borrow-before-accounting, reentrant market exit, and collateral redemption; omits full Comptroller/cToken stack. |
| 37 | Uranium Finance | S | Keeps the shipped `10000` fee adjustment vs `1000 ** 2` invariant typo; harness uses a finite branch because the fully symbolic nonlinear guard currently times out. |
| 38 | Platypus Finance | S | Keeps pre-withdraw solvency check, collateral/debt relation, and collateral removal; omits LP token and pool integrations. |
| 39 | Cover Protocol | S | Keeps memory-copied pool state, storage update, stale writeoff, and reward minting; omits LP/reward token plumbing. |

Counts: **6 Faithful · 12 Simplified · 4 Loose** (of 22).

## Explicitly excluded

The suite previously included ~20 additional cases (most access-control,
init re-callable, delegatecall hijack, etc.). Those are real bug classes
worth catching, but a hand-written unit test catches them equally well
*and* covers the same input space — the symbolic engine adds neither
discovery nor universal-property value over a unit test. They were
removed to keep the headline "the engine does something a unit test
cannot" honest.

The engine's broader capability set (path forking, vm.etch attacker
modeling, etc.) is regression-tested in the upstream PR itself.

## Out of scope

These classes are excluded for a different reason — the engine cannot
handle them at all yet:

- bridge / multisig key-compromise (Ronin, Multichain, Wormhole, Bybit)
- oracle manipulation (Mango, Inverse, Cream, BonqDAO, WOOFi)
- CREATE2 vanity-address attacks (Wintermute Profanity)
- TWAP-based pricing exploits
- governance flashloan plays (Beanstalk)
- non-EVM chains (Sui Cetus, Starknet zkLend)

On these, the upstream soundness guarantee says the engine should
surface `Unsupported(...)` rather than pass silently.

## Caveats

- Bugs and invariants were authored *with knowledge of the historical
  exploit*. A real auditor or fuzzer would not have that prior. The
  suite proves *capability*, not *discovery power*.
- Models are minimal (~25–75 LOC). Whether the engine scales to
  thousand-LOC contracts with the same bug class is a separate question.
- Several tests required input bounding to keep the SMT problem
  tractable (Euler, Hundred, zkLend). The bug exists at any scale; the
  proof requires bounded ranges.

## Layout

```
src/   one .sol per case (minimal reproducer of the bug shape)
test/  one .t.sol per case with the symbolic invariant
```

Tests inherit from `forge-std/Test.sol`. Solver times range from
~20ms (Uranium) to ~80s (MonoX) on a typical laptop with Z3.
