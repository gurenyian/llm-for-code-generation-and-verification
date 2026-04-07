# Remote Ubuntu Runner

Use this when the actual KLEE execution happens on a remote Ubuntu machine.

## Config

Create a `remote_runner_config.json` based on `templates/remote_runner_config.json`.

Important:

- `private_key_path` must point to the **local** private key file.
- `authorized_keys` is not a private key; it is the public-key authorization file on the remote machine.
- If you need a proxy, configure it in the SSH client or PowerShell invocation you use locally.

## Typical flow

1. Generate `specs/<func>.json`.
2. Generate `klee/oda_stubs.c` from the spec.
3. Copy or generate `klee/harness_<func>.c` from the generic template.
4. Run the remote script to compile and execute KLEE on Ubuntu.
5. Pull back `klee-out-*`, `.ktest`, and coverage stats.
