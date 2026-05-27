# symbolic-bug-suite

A Foundry project demonstrating what the **Foundry symbolic engine**
([PR #14796](https://github.com/foundry-rs/foundry/pull/14796)) can do
that a regular unit test cannot — by reproducing the shape of real
historical DeFi exploits where the engine has to *discover* a specific
attacker input the solver finds in an otherwise-untestable search space.

Each test is written so that **engine success = test FAILURE with a
concrete attacker witness**. 12 tests, all currently fail (= caught).

```bash
forge test --symbolic
```

(requires a forge build with `--symbolic` enabled and `z3` on `$PATH`)

## Why these 12 cases

Many DeFi bugs are caught equally well by a hand-written unit test —
"call this function as a non-owner and assert state unchanged." This
suite intentionally keeps only the cases where a unit test would *not*
find the witness, and the symbolic solver does. Each row below names
the specific input the engine has to discover.

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

## What the engine has to do

| Primitive | Cases |
|---|---|
| Default-layout SLOAD with symbolic mapping key | 01 Nomad |
| Symbolic `uint256` arithmetic (over/underflow / threshold) | 03 BEC · 10 Velocore · 33 Indexed |
| Multi-step state reachability with symbolic values | 04 Euler · 15 Abracadabra |
| Share-price rounding (deposit side) | 06 Hundred · 19 Sonne · 20 Onyx · 21 Polter |
| Share-price rounding (redeem side) | 14 zkLend |
| Same-token swap math | 23 MonoX |

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
| 06 | Hundred | S | Bare vault; real Compound-v2 fork has Comptroller, oracle, interest model. |
| 10 | Velocore | F | `feeMultiplier - 100` underflow is the real shape. |
| 14 | zkLend | L | Modeled `+1` redeem bumper; real bug was Cairo-side. |
| 15 | Abracadabra | S | Bare cauldron; real cauldron uses BoringSolidity + BentoBox + oracle. |
| 19 | Sonne | S | Same model as 06 with renamed contract. |
| 20 | Onyx | S | Same model as 06 with renamed contract. |
| 21 | Polter | S | Same model as 06 with renamed contract. |
| 23 | MonoX | L | Simplified arithmetic; real bug involved reserve accounting + price-update ordering. |
| 33 | Indexed | L | Reduced to one-line `weight[t] -= delta`; real Indexed bug was Balancer-pool reweight math. |

Counts: **3 Faithful · 5 Simplified · 4 Loose** (of 12).

## Explicitly excluded

This suite previously included ~23 additional cases (access control,
init re-callable, delegatecall hijack, reentrancy, multicall, revert-loop,
storage collision, etc.). Those are real bug classes worth catching, but
a hand-written unit test catches them equally well — the symbolic engine
doesn't add discovery power. They were removed to keep the headline
"the engine finds bugs a unit test cannot" honest.

The engine's broader capability set (path forking, vm.etch attacker
modeling, reentrancy semantics, etc.) is regression-tested in the
upstream PR itself.

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
- Models are minimal (~25–50 LOC). Whether the engine scales to
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
~100ms (Nomad) to ~50s (Hundred, zkLend) on a typical laptop with Z3.
