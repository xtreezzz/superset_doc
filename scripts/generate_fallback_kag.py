#!/usr/bin/env python3
"""Generate a minimal non-empty JSON knowledge graph from a local source tree.

Nodes:
- directory
- file

Edges:
- contains (directory -> child)
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", "venv", "dist", "build"}
SKIP_FILES = {".DS_Store"}


def node_id(path: Path) -> str:
    return str(path.as_posix())


def build_graph(root: Path) -> dict:
    nodes = []
    edges = []

    def add_node(path: Path, kind: str) -> None:
        nodes.append(
            {
                "id": node_id(path),
                "kind": kind,
                "name": path.name or "/",
            }
        )

    add_node(root, "directory")

    for current in sorted(root.rglob("*")):
        rel = current.relative_to(root)
        parts = set(rel.parts)
        if parts & SKIP_DIRS:
            continue
        if current.name in SKIP_FILES:
            continue

        kind = "directory" if current.is_dir() else "file"
        add_node(current, kind)

        parent = current.parent
        edges.append(
            {
                "type": "contains",
                "from": node_id(parent),
                "to": node_id(current),
            }
        )

    return {"nodes": nodes, "edges": edges}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    root = Path(args.root).resolve()
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    graph = build_graph(root)
    output.write_text(json.dumps(graph, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"[fallback-kag] wrote graph to {output}")
    print(f"[fallback-kag] nodes={len(graph['nodes'])} edges={len(graph['edges'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
