# External seats and Lua extensions

The engine's opt-in `ExternalAgentEndpoint` carries `AIRequest` / `AIResult`
values across a seat-scoped asynchronous boundary. See the matching engine
`docs/external-agents.md` for lifecycle, validation, and adapter integration.

Existing SmartAI callbacks remain available for ordinary robot seats. An external
seat bypasses those callbacks for the coordinator's play, use-card, choice,
selection, discard, skill-order, and response decisions. Jink, Peach, and
Nullification use the same response gate. A disconnected external seat waits
indefinitely unless the host explicitly selected `SmartAIFallback` for that seat.
Never describe that fallback as external-agent coverage.

An extension must expose legal actions through the existing value projection
and card/skill validators. Do not supply raw Lua userdata, room tags, opponent
hand identities, hidden roles, deck order, or other seats' private skill state
to an adapter. An incomplete conversion projection is not permission to execute
an invented action. Unsupported actions can remain pending until the adapter
provides a supported answer, the host chooses its preconfigured fallback policy,
or the session is cancelled.

The deterministic mock adapter is implemented in the engine and uses only the
request values. It passes play and optional prompts, takes the first offered
mandatory choice, and selects the required number of offered cards or players.
It is a boundary test, not a competitive strategy. There is no Jev, LLM, or
Hermes provider dependency, API key, token budget, or network client in this
companion. Provider call/cost budgets belong to a separately hosted adapter.

The engine also ships a loopback-only JSON-lines transport and a separate Python
mock client. See its version-1 wire contract and runnable `qsanguosha_external_agent_host`
example in `docs/external-agents.md`. The transport serializes only the existing
seat projection and reuses authoritative reply validation. Its random seat
capability is memory-only and passed by private pipe; no provider credentials are
created. Reconnection remains in-process, with durable restart recovery deferred.

Parse this companion with the engine's modified Lua 5.4.8, not a setup/stock Lua
5.2.4 executable: the engine intentionally permits unreachable statements after
`return`. `sgs10th.lua` requires the engine SWIG exposure of the existing
`CorrectSkillResult.noEffect` and `useAmount` methods. The engine's focused test
executes its actual correction callback to verify those methods and branch results.
