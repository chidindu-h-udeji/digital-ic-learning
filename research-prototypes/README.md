# research-prototypes

Learning exercises on research papers in hardware design automation. Each project re-implements or re-runs part of a paper's experiment at small scale, and reports what reproduced, what didn't, and what was not checked.

## Projects

Each project README opens with a short summary of what was found.

- [gramm-repro](gramm-repro/): re-implementation of the GRAMM CGRA mapper (Zhou, Stojilović, Anderson). The ordering of the paper's variants reproduces; the size of the PathFinder gain does not (44% here against 97% in the paper).
- [pattern-to-rtl-gen](pattern-to-rtl-gen/): flat vs. decomposed pattern matching (Garg & Boutros, arXiv:2607.16058), run at reduced scale with Yosys. The decomposed design uses fewer LUTs only at high repetition (best case 1.34×).
- [route-confidence-study](route-confidence-study/): ML confidence for FPGA routability (Gunter et al., MLCAD '24). The test halves of Tables 2 and 3 reproduce exactly from the authors' artifact; Table 4 only approximately.
- [sirop-repro](sirop-repro/): the dot-product example of the Sirop HLS IR (Hildebrand & Dubach, LCTES '26), written in RTL and compared with the authors' compiler. Structure and latency match (841 cycles at N = 840); the generated reduce keeps a `first_step` flag that appears redundant for a sum.

## How AI assistance was used

All projects here were built with AI assistance (Claude, Anthropic), in the same way each time, unless a project README says otherwise:

- **The AI** proposed the plan and order of work, wrote most of the code, tests and README drafts, and explained the papers and results in conversation.
- **I** chose the papers, ran every script, test and sweep on my own machine, and compared results against the authors' published numbers, released artifacts or independent checkers. I reviewed and edited each README.
- **Verification and limits.** Correctness was checked by running tests, independent checkers and comparisons against the authors' numbers, not by reading every line; I have not audited all of the generated code. Each project README says what is mine and what is the authors', which results were checked against an outside reference, and what was not checked.

## Third-party material

The papers, artifacts and backends studied belong to their authors and are not included. Licenses and exact versions are noted in each project's README.