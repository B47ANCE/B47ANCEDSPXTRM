#!/usr/bin/env python3
"""Disposable preflight fixtures, independent of developer consumer checkouts."""
from pathlib import Path
import tempfile
import unittest
from check_test_readiness import check


class ReadinessTests(unittest.TestCase):
    def test_missing_mod_id_and_case(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            shared = root / "media/lua/shared/ProjectNightfall"
            shared.mkdir(parents=True)
            (root / "mod.info").write_text("id=ProjectNightfall\nrequire=medWorks\n", encoding="utf-8")
            (shared / "Load.lua").write_text('require "ProjectNightfall/canonical"\nrequire "Sandbox/Apocalypse"', encoding="utf-8")
            (shared / "Canonical.lua").write_text("return {}", encoding="utf-8")
            issues = check({"nightfall": (root, root)})
            self.assertEqual(len(issues), 2)
            self.assertTrue(any("required Mod ID medWorks" in issue for issue in issues))
            self.assertTrue(any("case-incorrect" in issue for issue in issues))
            (shared / "Load.lua").write_text('require "ProjectNightfall/Canonical"', encoding="utf-8")
            medical = root / "medical"
            medical.mkdir()
            (medical / "mod.info").write_text("id=medWorks\n", encoding="utf-8")
            self.assertEqual(check({"nightfall": (root, root), "medical": (medical, medical)}), [])
            (shared / "Load.lua").write_text('require "experienceWorks/API"', encoding="utf-8")
            self.assertTrue(any("retired experienceWorks" in issue for issue in check({"nightfall": (root, root)})))


if __name__ == "__main__":
    unittest.main()
