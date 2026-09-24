#!/usr/bin/env python3
"""Validate and extract a supplied official all-profile ZIP into a new staging directory."""

import argparse
import hashlib
import json
import pathlib
import re
import shutil
import stat
import zipfile


def prepare(archive, destination, retrieved_at, source_url):
    if destination.exists():
        raise ValueError("Destination must not already exist")
    if archive.stat().st_size > 64 * 1024 * 1024:
        raise ValueError("Compressed archive exceeds 64 MiB")
    archive_digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    with zipfile.ZipFile(archive) as source:
        entries = source.infolist()
        if not 0 < len(entries) <= 30000:
            raise ValueError("Invalid profile count")
        names = set()
        total = 0
        for entry in entries:
            if not re.fullmatch(r"[A-Za-z0-9_-]+\.json", entry.filename):
                raise ValueError("Archive must contain only relative profile filenames")
            if entry.filename in names or stat.S_ISLNK(entry.external_attr >> 16):
                raise ValueError("Duplicate or symbolic-link archive entry")
            if entry.flag_bits & 1 or not 0 < entry.file_size <= 4 * 1024 * 1024:
                raise ValueError("Encrypted or oversized profile")
            names.add(entry.filename)
            total += entry.file_size
            if total > 512 * 1024 * 1024:
                raise ValueError("Uncompressed archive exceeds 512 MiB")
        destination.mkdir(parents=True)
        try:
            inventory = []
            identifiers = set()
            for entry in entries:
                # ZipExtFile verifies CRC while reading; a strict bound also limits actual output.
                with source.open(entry) as stream:
                    data = stream.read(4 * 1024 * 1024 + 1)
                if len(data) != entry.file_size:
                    raise ValueError("Incorrect profile length")
                profile = json.loads(data)
                identifier = profile.get("usCongressBioId")
                if identifier != pathlib.Path(entry.filename).stem or identifier in identifiers:
                    raise ValueError("Missing, mismatched, or duplicate Bioguide identifier")
                identifiers.add(identifier)
                (destination / entry.filename).write_bytes(data)
                inventory.append(dict(byteCount=len(data), filename=entry.filename,
                                      identifier=identifier, sha256=hashlib.sha256(data).hexdigest()))
            manifest = dict(archiveSHA256=archive_digest, entries=inventory,
                            profileCount=len(inventory), retrievedAt=retrieved_at, sourceURL=source_url)
            (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        except Exception:
            # Only this newly created staging directory is removed after a failed extraction.
            shutil.rmtree(destination)
            raise
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=pathlib.Path)
    parser.add_argument("destination", type=pathlib.Path)
    parser.add_argument("--retrieved-at", required=True, help="Actual archive retrieval instant")
    parser.add_argument("--source-url", default="https://bioguide.congress.gov/search")
    arguments = parser.parse_args()
    result = prepare(arguments.archive, arguments.destination, arguments.retrieved_at, arguments.source_url)
    print(f"Validated {result['profileCount']} unique profiles; archive SHA-256 {result['archiveSHA256']}")
