# Template Reuse for ODA/KLEE

This folder contains reusable artifacts for new API tests.

## Files

- `harness_template.c`: generic harness skeleton
- `function_spec_template.json`: per-function configuration schema
- `harness_pathcombinew_template.c`: a concrete example template for path-combining APIs
- `apply_template.py`: small helper to stamp out per-function files

## Recommended workflow

1. Create a new function spec from `function_spec_template.json`.
2. Run the analyzer to fill dependencies and predicates.
3. Feed the spec to the LLM stub generator.
4. Emit a harness from the template.
5. Run KLEE and feed results back into the LLM if coverage is incomplete.
