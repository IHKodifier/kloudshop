---
trigger: always_on
---

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- BEFORE reading files, answering architecture questions, or modifying code, you MUST read `graphify-out/GRAPH_REPORT.md` to map out god nodes, community boundaries, and file linkages.
- Focus exclusively on the specific code file nodes and dependencies identified by the graph data. DO NOT run broad repository file crawls, regex greps, or full-corpus text dumps unless the information cannot be found within the graphify-out/ files (such as for brand-new, unindexed changes).
- If `graphify-out/wiki/index.md` exists, navigate it first instead of inspecting raw source files blindly.
- If the graphify MCP server is active, utilize dedicated tools like `query_graph`, `get_node`, and `shortest_path` for precise architecture navigation.
- After modifying code files in this session, DO NOT run standard update commands. Instead, execute `graphify vscode-build .` to patch the graph current using fast, local AST parsing with 0% remote LLM token cost.
- For Unimplemented Features: When tasked with building new sprint features, analyze the "Inferred Nodes" and unlinked placeholders within the graph data to identify where the new logic is mathematically expected to plug into the existing architecture boundaries.
- Quality Control for Specs: BEFORE generating or modifying any code based on files in `./specifications/`, you MUST cross-reference the markdown requirements against each other. If you find any self-contradictory statements, conflicting business rules, or logical mismatches across specification files, HALT and report the specific contradiction to the user for clarification before burning tokens on code generation.
