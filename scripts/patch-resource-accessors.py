#!/usr/bin/env python3
"""Patch SPM-generated resource_bundle_accessor.swift files.

SPM's generated Bundle.module accessor only checks Bundle.main.bundleURL,
which points to the .app root. macOS code signing requires resources to be
inside Contents/Resources/, so we patch the accessors to also check
Bundle.main.resourceURL.
"""

import glob
import sys

build_dir = sys.argv[1] if len(sys.argv) > 1 else ".build/arm64-apple-macosx/release"

old = "let preferredBundle = Bundle(path: mainPath)"
new = (
    "let resourcePath = (Bundle.main.resourceURL ?? Bundle.main.bundleURL)"
    ".appendingPathComponent((mainPath as NSString).lastPathComponent).path\n"
    "        let preferredBundle = Bundle(path: mainPath) ?? Bundle(path: resourcePath)"
)

pattern = f"{build_dir}/*.build/DerivedSources/resource_bundle_accessor.swift"
for path in glob.glob(pattern):
    content = open(path).read()
    if old in content:
        open(path, "w").write(content.replace(old, new))
