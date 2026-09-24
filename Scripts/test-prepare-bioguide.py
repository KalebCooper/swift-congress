#!/usr/bin/env python3
"""Exercise archive rejection boundaries without reaching any provider."""

import importlib.util
import json
import pathlib
import tempfile
import unittest
import warnings
import zipfile

spec = importlib.util.spec_from_file_location("prepare", pathlib.Path(__file__).with_name("prepare-bioguide.py"))
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


class ArchiveTests(unittest.TestCase):
    def test_corrupt_crc(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "profiles.zip"
            with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_STORED) as output:
                output.writestr("A000375.json", json.dumps({"usCongressBioId": "A000375"}))
            data = bytearray(archive.read_bytes())
            data[30 + len("A000375.json")] ^= 1
            archive.write_bytes(data)
            with self.assertRaises(zipfile.BadZipFile):
                prepare.prepare(archive, root / "stage", "recorded", "official")
            self.assertFalse((root / "stage").exists())

    def test_invalid_entries(self):
        for names in (["../A000375.json"], ["/A000375.json"], ["A000375.json", "A000375.json"]):
            with self.subTest(names=names), tempfile.TemporaryDirectory() as temporary:
                root = pathlib.Path(temporary)
                archive = root / "profiles.zip"
                with warnings.catch_warnings(), zipfile.ZipFile(archive, "w") as output:
                    warnings.simplefilter("ignore", UserWarning)
                    for name in names:
                        output.writestr(name, json.dumps({"usCongressBioId": "A000375"}))
                with self.assertRaises(ValueError):
                    prepare.prepare(archive, root / "stage", "recorded", "official")
                self.assertFalse((root / "stage").exists())

    def test_mismatched_identifier(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "profiles.zip"
            with zipfile.ZipFile(archive, "w") as output:
                output.writestr("A000375.json", json.dumps({"usCongressBioId": "B001323"}))
            with self.assertRaises(ValueError):
                prepare.prepare(archive, root / "stage", "recorded", "official")
            self.assertFalse((root / "stage").exists())

    def test_symbolic_link(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "profiles.zip"
            entry = zipfile.ZipInfo("A000375.json")
            entry.create_system = 3
            entry.external_attr = 0o120777 << 16
            with zipfile.ZipFile(archive, "w") as output:
                output.writestr(entry, "elsewhere")
            with self.assertRaises(ValueError):
                prepare.prepare(archive, root / "stage", "recorded", "official")

    def test_uncompressed_size_limit(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "profiles.zip"
            with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as output:
                output.writestr("A000375.json", b"x" * (4 * 1024 * 1024 + 1))
            with self.assertRaises(ValueError):
                prepare.prepare(archive, root / "stage", "recorded", "official")


if __name__ == "__main__":
    unittest.main()
