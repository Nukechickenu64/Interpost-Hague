# Copilot Repository Instructions

## No Unit Tests

Unit-test work is not wanted in this BYOND repository. This rule applies to every task, including bug fixes and regressions.

- Never create, add, modify, run, troubleshoot, recommend, or delegate unit tests.
- Never create or compile unit-test harnesses, temporary test projects, or isolated regression-test daemons.
- Never invoke commands, scripts, tasks, or CI workflows that execute unit tests, even indirectly.
- Do not treat existing tests, CI configuration, or general testing guidance as permission to perform unit-test work.
- Do not propose unit tests as follow-up work or request permission to run them.
- Leave existing unit tests and CI configuration unchanged unless the user explicitly requests a change to this policy.

## Allowed Validation

- Use normal BYOND project compilation and focused static/code inspection when appropriate.
- Describe relevant manual in-game checks when runtime verification is needed.
- Report validation limitations honestly; do not substitute unit tests for unavailable manual verification.