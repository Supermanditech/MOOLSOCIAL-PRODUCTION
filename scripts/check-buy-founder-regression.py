"""Buy acceptance evidence gate. Runs before implementation, build and closure.

Evidence checks prevent missing/stale/partial acceptance, not every possible bug.
No application code or device state is changed by this checker.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

LEDGER = 'config/buy-founder-regression.json'
BRANCH = 'work/cursor-ui/buy-ready-20260921'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args]).decode().strip()


def file_at(root, relative):
    path = (root / relative).resolve()
    require(path.is_relative_to(root.resolve()), 'Evidence escapes repository')
    require(path.is_file(), 'Missing file: ' + relative)
    return path


def fingerprint(root):
    names = git(root, 'ls-files', 'apps/mobile/lib', 'apps/mobile/test',
                'apps/mobile/assets', 'apps/mobile/android', 'apps/mobile/pubspec.yaml',
                'apps/mobile/pubspec.lock').splitlines()
    require(bool(names), 'No source inputs')
    return hashlib.sha256('\n'.join(
        name + ':' + hashlib.sha256(file_at(root, name).read_bytes()).hexdigest()
        for name in sorted(names)).encode()).hexdigest()


def checked_evidence(root, record):
    path = file_at(root, record['path'])
    require(hashlib.sha256(path.read_bytes()).hexdigest() == record['sha256'],
            'Evidence checksum mismatch: ' + record['path'])
    return path


def flutter_pass(root, evidence, exact_name):
    path = checked_evidence(root, evidence)
    events = [json.loads(line) for line in path.read_text(encoding='utf-8-sig').splitlines()
              if line.startswith('{')]
    starts = {e['test']['id']: e['test']['name'] for e in events if e.get('type') == 'testStart'}
    require(any(e.get('type') == 'done' and e.get('success') is True for e in events),
            'Missing successful Flutter machine-log completion')
    require(not any(e.get('type') == 'error' or
                    (e.get('type') == 'testDone' and e.get('result') != 'success')
                    for e in events), 'Failed test in local evidence')
    require(any(e.get('type') == 'testDone' and starts.get(e.get('testID')) == exact_name
                and e.get('result') == 'success' and not e.get('skipped', False)
                for e in events), 'Exact regression scenario was not executed: ' + exact_name)


def validate(root, data, phase, current_source=None):
    require(data['schemaVersion'] == 1, 'Unknown ledger schema')
    require(data['baseline'] == 'aa1300df51b4971475af761757b269a128f44aa3', 'Baseline changed')
    tickets = data['tickets']
    require(len({t['id'] for t in tickets}) == len(tickets), 'Duplicate ticket')
    by_id = {t['id']: t for t in tickets}
    require(set('R6634-C0'+str(i) for i in range(1, 6)) <= set(by_id), 'Known child removed')
    core = [{'id': t['id'], 'founderRequirement': t['founderRequirement'],
             'parents': t['parents'], 'cases': [{k: c[k] for k in
             ['id', 'route', 'state', 'expected']} for c in t['cases']]}
            for t in tickets if t['id'] in {'R6634-C0'+str(i) for i in range(1, 6)}]
    require(hashlib.sha256(json.dumps(core, sort_keys=True).encode()).hexdigest() ==
            'bb9b82ce7b9832dd47749147cd8c69224e40e152f425172aadd545c8c40ba890',
            'Founder scenario matrix removed or weakened; preserve the recorded contract')
    require(set(data['selected']) <= set(by_id), 'Unknown selected ticket')
    all_cases = set()
    for t in tickets:
        require(t['status'] in ['open', 'in_progress', 'local_passed', 'closed'], 'Invalid status')
        require(t['founderRequirement'] and t['parents'] and t['cases'], 'Incomplete requirement')
        require(t['owners'], 'Missing affected owners')
        for owner in t['owners']:
            file_at(root, owner)
        for case in t['cases']:
            require(case['id'] not in all_cases, 'Duplicate scenario')
            all_cases.add(case['id'])
            require(case['route'] and case['state'] and case['expected'], 'Incomplete scenario')
        for child in t.get('children', []):
            require(child in by_id, 'Unregistered child')
        if t['status'] == 'closed':
            validate_ticket(root, t, by_id, current_source or fingerprint(root), 'close')
    selected = [by_id[i] for i in data['selected']]
    if phase in ['implementation', 'build', 'close']:
        require(selected, 'No selected ticket: record exact founder scenarios before editing')
    if phase == 'implementation':
        for t in selected:
            require(t['reproduction'], 'Missing original failure evidence')
            checked_evidence(root, t['reproduction'])
            for case in t['cases']:
                file_at(root, case['testFile'])
                require(case.get('testName'), 'Name the behavior regression before editing')
    if phase in ['pre_commit', 'build', 'close']:
        changed = git(root, 'diff', '--name-only', data['baseline'], '--',
                      'apps/mobile/lib', 'apps/mobile/test').splitlines()
        if phase == 'pre_commit' and not changed:
            return
        require(selected, 'Application delta has no selected founder ticket')
        owners = {p for t in selected for p in t['owners']}
        require(set(changed) <= owners, 'Changed application owner missing from affected-route ledger')
        for t in selected:
            validate_ticket(root, t, by_id, current_source or fingerprint(root), phase)


def validate_ticket(root, ticket, by_id, source, phase):
    for case in ticket['cases']:
        result = case.get('local')
        require(result and result.get('sourceSha256') == source, 'Missing/stale local scenario: ' + case['id'])
        flutter_pass(root, result, case['testName'])
        if phase != 'close':
            continue
        device = case.get('device')
        require(device and device.get('sourceSha256') == source, 'Missing/stale Redmi scenario: ' + case['id'])
        require(device.get('serial') == 'TG8HCYTGGQT885OF', 'Wrong acceptance device')
        require(device.get('passed') is True and device.get('visualReviewed') is True,
                'Device or visual inspection incomplete')
        built = checked_evidence(root, device['builtApk'])
        installed = checked_evidence(root, device['installedApk'])
        require(device['builtApk']['sha256'] == device['installedApk']['sha256'], 'Installed APK differs')
        require(built.suffix == '.apk' and installed.suffix == '.apk', 'Not APK evidence')
        png = checked_evidence(root, device['screenshot'])
        require(png.read_bytes().startswith(b'\x89PNG\r\n\x1a\n'), 'Not a screenshot')
        checked_evidence(root, device['hierarchy'])
    if phase == 'close':
        require(all(by_id[c]['status'] == 'closed' for c in ticket.get('children', [])), 'Open child blocks parent closure')
        require(not ticket.get('dependencies'), 'Dependency blocks full closure')
        require(ticket.get('founderApproval'), 'Founder visual approval is separate and required')
        checked_evidence(root, ticket['founderApproval'])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--phase', choices=['setup', 'implementation', 'pre_commit', 'build', 'close'], required=True)
    parser.add_argument('--fingerprint', action='store_true')
    args = parser.parse_args()
    if args.fingerprint:
        print(fingerprint(args.root))
        return
    if git(args.root, 'branch', '--show-current') != BRANCH:
        print('Buy founder gate: other lane; existing lane gates unchanged.')
        return
    data = json.loads(file_at(args.root, LEDGER).read_text(encoding='utf-8-sig'))
    validate(args.root, data, args.phase)
    print('Buy founder regression gate passed: ' + args.phase)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit('Buy founder regression gate BLOCKED: ' + str(error))
