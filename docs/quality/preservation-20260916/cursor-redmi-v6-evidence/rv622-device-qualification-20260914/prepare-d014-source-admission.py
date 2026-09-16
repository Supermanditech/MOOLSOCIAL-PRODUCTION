"""Prepare exact source admission for review; never modify the worktree."""
from pathlib import Path
import difflib
import hashlib
import json
import subprocess

ROOT = Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
OUT = Path(__file__).parent / 'd014-source-admission-proposal'
SOURCE = '4221158fead95a89047e3408aaeb11c9a12dd135'
OLD = '3c30ba11521db6bb1a1ec6995b181a81df1a6b34'
SCREEN_HASH = 'C00636022B4C0AEC1CB662F4D2FE28C0B20366358BE9E1E19CE7329848BE4CCA'

def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args], text=True).strip()

def digest(value):
    return hashlib.sha256(value.encode()).hexdigest().upper()

def replace_once(value, before, after):
    assert value.count(before) == 1, before
    return value.replace(before, after, 1)

assert git('rev-parse', 'HEAD') == SOURCE
assert git('branch', '--show-current') == 'work/cursor-ui/redmi-v6-audit-20260913'
boundaries = ['apps', 'backend', 'contracts', 'packages', 'package.json', 'package-lock.json', 'pubspec.yaml', 'pubspec.lock']
delta = git('diff', '--name-only', OLD, SOURCE, '--', *boundaries).splitlines()
assert delta == ['apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart', 'apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart']
assert digest((ROOT / delta[0]).read_text(encoding='utf-8')) == SCREEN_HASH
assert not OUT.exists(), 'Preserve existing proposal'

owners = [
    'scripts/check-approved-ui-locks.ps1',
    'scripts/check-buy-protected-baseline.ps1',
    'scripts/check-buy-backend-contract-boundary.ps1',
    'scripts/check-buy-data-egress-boundary.ps1',
]
before = {owner: (ROOT / owner).read_text(encoding='utf-8') for owner in owners}
after = dict(before)
owner = owners[0]
anchor = f"    if ($LASTEXITCODE -eq 0) {{ $redmiSource = '{OLD}' }}\n"
after[owner] = replace_once(before[owner], anchor, anchor +
    '    # Exact reproduced D014 nested product-return correction.\n' +
    f"    & git -C $root merge-base --is-ancestor '{SOURCE}' HEAD\n" +
    f"    if ($LASTEXITCODE -eq 0) {{ $redmiSource = '{SOURCE}' }}\n")
owner = owners[1]
after[owner] = replace_once(before[owner], f"    '{OLD}'\n", f"    '{OLD}',\n    '{SOURCE}'\n")
owner = owners[2]
anchor = "          $soundSourceHash -ceq '94B7A6AE4F5B24CAE5B14795310E1A5DAE5D13147C6FCFC02CB1F034640BCDF6'\n"
after[owner] = replace_once(before[owner], anchor, anchor +
    '        ) -or (\n' +
    '          # D014 changes only nested return handling; preserve exact sound source binding.\n' +
    f"          $IntegratedReviewSourceCommit -ceq '{SOURCE}' -and\n" +
    f"          $soundSourceHash -ceq '{SCREEN_HASH}'\n")
owner = owners[3]
after[owner] = replace_once(before[owner], f"'{OLD}'))", f"'{OLD}', '{SOURCE}'))")

coordinator = 'scripts/check-codex-subagent-coordination-policy.ps1'
before[coordinator] = (ROOT / coordinator).read_text(encoding='utf-8')
after[coordinator] = before[coordinator]
for owner in owners:
    after[coordinator] = replace_once(after[coordinator],
        f"'{owner}' = '{digest(before[owner])}'",
        f"'{owner}' = '{digest(after[owner])}'")
# No commit-label exception or source/owner expansion is included.
start = '    # BEGIN founder SUCCESSOR BUILD admission 20260914\n'
end = '    # END founder SUCCESSOR BUILD admission 20260914\n'
def outside_block(value):
    prefix, rest = value.split(start)
    _, suffix = rest.split(end)
    return prefix + suffix
assert outside_block(before[coordinator]) == outside_block(after[coordinator])

OUT.mkdir()
records = []
patch = []
for owner in [*owners, coordinator]:
    (OUT / Path(owner).name).write_text(after[owner], encoding='utf-8', newline='\n')
    patch.extend(difflib.unified_diff(before[owner].splitlines(True), after[owner].splitlines(True), fromfile='a/' + owner, tofile='b/' + owner))
    records.append({'owner': owner, 'beforeNormalizedSha256': digest(before[owner]), 'afterNormalizedSha256': digest(after[owner])})
(OUT / 'source-admission.patch').write_text(''.join(patch), encoding='utf-8', newline='\n')
(OUT / 'manifest.json').write_text(json.dumps({
    'status': 'prepared_not_applied_not_gate_qualified', 'source': SOURCE,
    'previousSource': OLD, 'appDelta': delta, 'owners': records,
    'commitLabelExceptionIncluded': False, 'coordinatorOutsideAdmissionUnchanged': True,
    'deviceClosureEstablished': False,
}, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'preparedOwners': len(records), 'source': SOURCE, 'applied': False, 'directory': str(OUT)}))
