---
summary: "AEON runtime logic model: safety-first cognition loop, persistence, and traceability."
read_when:
  - You want to understand how AEON decisions are made at runtime
  - You need a practical map from philosophy to executable system behavior
title: "AEON Logic Model"
---

# AEON Logic Model

OpenAEON defines AEON as:

- **Open**: inspectable, extensible, and operator-controlled
- **Eternal Evolution**: continuously adaptive over long-running sessions

This page describes the implemented runtime logic, not aspirational messaging.

## Core loop (implemented)

AEON runs as a verifiable five-stage loop:

1. **Perceive**  
   Ingest session state, runtime telemetry, task intent, and model/tool outputs.
2. **Adjudicate**  
   Apply guardrail and policy decisions (`maintenanceDecision`, `guardrailDecision`, `reasonCode`) with epistemic labels.
3. **Act**  
   Execute agent/tool work under policy intensity and safety constraints.
4. **Persist**  
   Record delivery outcomes (`persisted` / `persist_failed`), memory checkpoint signals, and decision logs.
5. **Trace**  
   Expose structured state for operators and UI via AEON control APIs.

## Safety-first decision semantics

Decision state is emitted as typed, inspectable data:

- `selfKernel`: identity continuity, drift, calibration, integrity state
- `epistemic`: confidence labeling and uncertainty framing
- `impactLens`: multi-scale benefit/risk and reversibility
- `decisionCard`: why / why-not / counterfactual / rollback

This keeps optimization constrained by trust and reversibility rather than raw autonomy.

## Runtime inspection APIs

The Control UI and operators read AEON through:

- `aeon.status` (schema v3 with compatibility mirrors)
- `aeon.memory.trace`
- `aeon.execution.lookup`
- `aeon.thinking.stream`

See [Control UI](/web/control-ui) and [RPC reference](/reference/rpc) for request/response usage patterns.

## Session durability and operator outcomes

AEON is designed to avoid "worked overnight but no result" failures by making delivery and traceability first-class:

- explicit delivery state transitions
- persisted artifact references for lookup
- memory persistence metadata (`lastDistillAt`, `checkpoint`, `totalEntries`, `lastWriteSource`)
- UI-visible runtime source/timestamp for telemetry blocks

## Memory logic (implemented)

AEON memory is intentionally layered:

1. **In-memory working tail**  
   A bounded cognitive log supports fast runtime/UI interaction.
2. **Persisted cognitive stream**  
   Events are appended to per-scope JSONL storage (`session + agent`), enabling replay and audit.
3. **Distillation checkpointing**  
   Distillation advances checkpoint state and appends checkpoint markers instead of erasing `MEMORY.md`.
4. **Memory trace contract**  
   Runtime memory state is exposed via `aeon.status` and `aeon.memory.trace`.

This balances short-latency operations with long-horizon continuity.

## Relationship to evolution log

The evolution log is the historical timeline.  
This model page is the system contract.

- Historical record: [AEON Evolution Log](/aeon/EVOLUTION)
- Operational surface: [Control UI](/web/control-ui)
