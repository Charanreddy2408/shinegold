#!/usr/bin/env python3
"""Fix l10n scope and const issues after auto-migration."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"


def fix_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    # Bare l10n. -> context.l10n. (but not context.l10n. already, not AppLocalizations)
    text = re.sub(r"(?<![\w.])l10n\.", "context.l10n.", text)

    # Remove now-redundant final l10n = context.l10n;
    text = re.sub(r"\n\s*final l10n = context\.l10n;\n", "\n", text)

    # Invalid const with context.l10n inside — strip const from common widgets
    # const Foo( ... context.l10n ... ) is hard; strip const ShineEmptyState / InputDecoration / etc.
    for widget in [
        "ShineEmptyState",
        "GradientHeader",
        "InputDecoration",
        "SnackBar",
        "Text",
        "AdminMenuTile",
        "ShineNavItem",
        "FriendlyErrorBanner",
        "SectionHeader",
        "DashboardSectionHeader",
        "InfoMetricTile",
        "StatusChip",
    ]:
        # const WidgetName( -> WidgetName( when file uses context.l10n nearby — blunt but safe
        text = text.replace(f"const {widget}(", f"{widget}(")

    # const Icon( is fine; leave it
    # Fix double context.context.l10n if any
    text = text.replace("context.context.l10n.", "context.l10n.")

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    n = 0
    for path in ROOT.rglob("*.dart"):
        if "l10n" in str(path).replace("\\", "/"):
            continue
        if fix_file(path):
            n += 1
            print(path.relative_to(ROOT.parent))
    print(f"fixed {n} files")


if __name__ == "__main__":
    main()
