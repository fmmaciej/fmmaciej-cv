#!/usr/bin/env python3
"""Download and verify an official Eisvogel release for build.sh."""

import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys
import zipfile

RELEASES = "https://api.github.com/repos/Wandmalfarbe/pandoc-latex-template/releases"
TEMPLATES = Path(__file__).resolve().parents[1] / "src/templates"


def download(url):
    return subprocess.check_output([
        "curl", "--fail", "--silent", "--show-error", "--location",
        "--connect-timeout", "15", "--max-time", "180", url,
    ])


def prepare(version, directory):
    manifest = TEMPLATES / "eisvogel.version.json"
    if manifest.exists():
        recorded = json.loads(manifest.read_text())
        current = hashlib.sha256((TEMPLATES / "eisvogel.latex").read_bytes()).hexdigest()
        if current != recorded["template_sha256"]:
            raise ValueError("Local template changes detected; move them to partials before updating.")

    endpoint = "latest" if version == "latest" else "tags/v" + version.removeprefix("v")
    release = json.loads(download(f"{RELEASES}/{endpoint}"))
    if release["draft"] or release["prerelease"]:
        raise ValueError("Choose a stable release.")
    version = release["tag_name"].removeprefix("v")
    archive_name = f"Eisvogel-{version}.zip"
    asset = next((asset for asset in release["assets"] if asset["name"] == archive_name), None)
    if asset is None:
        raise ValueError(f"Release {version} does not contain {archive_name}.")
    archive = download(asset["browser_download_url"])
    checksum = hashlib.sha256(archive).hexdigest()
    if asset.get("digest") != "sha256:" + checksum:
        raise ValueError("Missing or mismatched archive SHA-256.")
    with zipfile.ZipFile(io.BytesIO(archive)) as released:
        name = f"Eisvogel-{version}/eisvogel.latex"
        if released.namelist().count(name) != 1:
            raise ValueError("Archive must contain exactly one standalone template.")
        template = released.read(name)

    directory.mkdir(parents=True)
    (directory / "eisvogel.latex").write_bytes(template)
    (directory / "eisvogel.version.json").write_text(json.dumps({
        "version": version,
        "archive_url": asset["browser_download_url"],
        "archive_sha256": checksum,
        "template_sha256": hashlib.sha256(template).hexdigest(),
    }, indent=2) + "\n")
    print(f"Prepared Eisvogel {version} for trial builds.")


if __name__ == "__main__":
    try:
        prepare(sys.argv[1], Path(sys.argv[2]))
    except (OSError, ValueError, KeyError, zipfile.BadZipFile,
            subprocess.CalledProcessError) as error:
        sys.exit(f"Update failed: {error}")
