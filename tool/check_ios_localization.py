#!/usr/bin/env python3
"""Check that the iOS bundle metadata is localized and wired into the target.

`CFBundleDisplayName` and `NSLocalNetworkUsageDescription` live in
`ios/Runner/Info.plist`, and the only way to translate them is
`InfoPlist.strings` per language, added to the Xcode project as a variant
group. Those edits are hand-made in `project.pbxproj` on a machine without
Xcode, so nothing catches a broken reference until someone opens the project.

This script checks what can be checked without Xcode: the project parses as an
OpenStep plist, every object reference resolves, the variant group holds the
expected languages, the files it points at exist and parse as `.strings`, the
build file is in the Runner target's Resources phase, and each language is a
known region of the project.

Usage: python3 tool/check_ios_localization.py [--languages en,ru]
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJECT = REPO_ROOT / 'ios' / 'Runner.xcodeproj' / 'project.pbxproj'
RUNNER_TARGET = '97C146ED1CF9000F007C117D'
VARIANTS_GROUP_NAME = 'InfoPlist.strings'
REQUIRED_KEYS = ('CFBundleDisplayName', 'NSLocalNetworkUsageDescription')

DELIMITERS = '{}()=;,'
WHITESPACE = ' \t\n\r'


class OpenStepParser:
    """Minimal parser for the OpenStep property list used by Xcode projects."""

    def __init__(self, text: str) -> None:
        self.text = text
        self.pos = 0

    def document(self) -> dict:
        value = self.value()
        self.skip()
        if self.pos != len(self.text):
            raise ValueError(f'trailing data at offset {self.pos}')
        return value

    def skip(self) -> None:
        while self.pos < len(self.text):
            char = self.text[self.pos]
            if char in WHITESPACE:
                self.pos += 1
            elif self.text.startswith('/*', self.pos):
                end = self.text.find('*/', self.pos + 2)
                if end < 0:
                    raise ValueError(f'unterminated comment at offset {self.pos}')
                self.pos = end + 2
            elif self.text.startswith('//', self.pos):
                end = self.text.find('\n', self.pos)
                self.pos = len(self.text) if end < 0 else end + 1
            else:
                return

    def value(self):
        self.skip()
        if self.pos >= len(self.text):
            raise ValueError('unexpected end of input')
        char = self.text[self.pos]
        if char == '{':
            return self.dictionary()
        if char == '(':
            return self.array()
        return self.scalar()

    def dictionary(self) -> dict:
        self.pos += 1  # {
        result = {}
        while True:
            self.skip()
            if self.text[self.pos] == '}':
                self.pos += 1
                return result
            key = self.scalar()
            self.skip()
            if self.text[self.pos] != '=':
                raise ValueError(f'expected "=" after {key!r} at offset {self.pos}')
            self.pos += 1
            result[key] = self.value()
            self.skip()
            if self.text[self.pos] != ';':
                raise ValueError(f'expected ";" after {key!r} at offset {self.pos}')
            self.pos += 1

    def array(self) -> list:
        self.pos += 1  # (
        result = []
        while True:
            self.skip()
            if self.text[self.pos] == ')':
                self.pos += 1
                return result
            result.append(self.value())
            self.skip()
            if self.text[self.pos] == ',':
                self.pos += 1
            elif self.text[self.pos] != ')':
                raise ValueError(f'expected "," or ")" at offset {self.pos}')

    def scalar(self) -> str:
        self.skip()
        if self.text[self.pos] == '"':
            self.pos += 1
            chunks = []
            while self.text[self.pos] != '"':
                if self.text[self.pos] == '\\':
                    chunks.append(self.text[self.pos:self.pos + 2])
                    self.pos += 2
                else:
                    chunks.append(self.text[self.pos])
                    self.pos += 1
            self.pos += 1
            return ''.join(chunks)
        start = self.pos
        while self.pos < len(self.text) and self.text[self.pos] not in WHITESPACE + DELIMITERS:
            self.pos += 1
        if start == self.pos:
            raise ValueError(f'unexpected {self.text[self.pos]!r} at offset {self.pos}')
        return self.text[start:self.pos]


def parse_strings(path: pathlib.Path) -> dict:
    """Parse an old-style `.strings` file: comments plus "key" = "value"; pairs."""
    body = re.sub(r'/\*.*?\*/', '', path.read_text(encoding='utf-8'), flags=re.S)
    pair = r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;'
    pairs = {m.group(1): m.group(2) for m in re.finditer(pair, body)}
    if re.sub(pair, '', body).strip():
        raise ValueError(f'{path}: unparsed content')
    return pairs


def check(languages: set[str]) -> list[str]:
    if not PROJECT.is_file():
        return [f'missing {PROJECT}']
    try:
        project = OpenStepParser(PROJECT.read_text(encoding='utf-8')).document()
    except ValueError as error:
        return [f'{PROJECT.name} does not parse: {error}']

    objects = project['objects']
    problems: list[str] = []

    def resolve(reference: str) -> dict | None:
        if reference not in objects:
            problems.append(f'dangling reference {reference}')
            return None
        return objects[reference]

    for identifier, obj in objects.items():
        if not re.fullmatch(r'[0-9A-F]{24}', identifier):
            problems.append(f'bad object id {identifier!r}')
        for field in ('fileRef', 'target', 'containerPortal', 'productReference',
                      'buildConfigurationList', 'targetProxy'):
            reference = obj.get(field)
            if isinstance(reference, str):
                resolve(reference)
        for field in ('children', 'files', 'buildPhases', 'targets', 'dependencies'):
            for reference in obj.get(field, []):
                resolve(reference)

    groups = [
        identifier for identifier, obj in objects.items()
        if obj.get('isa') == 'PBXVariantGroup' and obj.get('name') == VARIANTS_GROUP_NAME
    ]
    if len(groups) != 1:
        return problems + [f'expected exactly one {VARIANTS_GROUP_NAME} variant group, found {len(groups)}']
    group_id = groups[0]

    found = set()
    for reference in objects[group_id]['children']:
        file_ref = resolve(reference)
        if file_ref is None:
            continue
        found.add(file_ref['name'])
        path = REPO_ROOT / 'ios' / 'Runner' / file_ref['path']
        if not path.is_file():
            problems.append(f'missing {path.relative_to(REPO_ROOT)}')
            continue
        try:
            strings = parse_strings(path)
        except ValueError as error:
            problems.append(str(error))
            continue
        for key in REQUIRED_KEYS:
            if key not in strings:
                problems.append(f'{path.relative_to(REPO_ROOT)}: no {key}')
    if found != languages:
        problems.append(f'localized languages are {sorted(found)}, expected {sorted(languages)}')

    runner = resolve(RUNNER_TARGET)
    resources_wired = False
    for phase_id in runner.get('buildPhases', []) if runner else []:
        phase = resolve(phase_id)
        if phase is None or phase.get('isa') != 'PBXResourcesBuildPhase':
            continue
        for build_file_id in phase.get('files', []):
            build_file = resolve(build_file_id)
            if build_file and build_file.get('fileRef') == group_id:
                resources_wired = True
    if not resources_wired:
        problems.append(f'{VARIANTS_GROUP_NAME} is not in the Runner Resources build phase')

    project_object = next(obj for obj in objects.values() if obj.get('isa') == 'PBXProject')
    known = set(project_object.get('knownRegions', []))
    missing_regions = languages - known
    if missing_regions:
        problems.append(f'not in knownRegions: {sorted(missing_regions)}')

    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        '--languages',
        default='en,ru',
        help='comma-separated localizations expected in InfoPlist.strings (default: en,ru)',
    )
    arguments = parser.parse_args()
    languages = {part.strip() for part in arguments.languages.split(',') if part.strip()}

    problems = check(languages)
    if problems:
        print('\n'.join(f'FAIL: {problem}' for problem in problems))
        return 1
    print(f'ok: InfoPlist.strings ({", ".join(sorted(languages))}) wired into the Runner target')
    return 0


if __name__ == '__main__':
    sys.exit(main())
