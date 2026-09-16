"""Prepare one r66.23 candidate after verified prerequisites; does not build."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys

ROOT = Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
EVIDENCE = Path(__file__).parent
SOURCE = '4221158fead95a89047e3408aaeb11c9a12dd135'
BRANCH = 'work/cursor-ui/redmi-v6-audit-20260913'
CANDIDATE = 'UAW-CURSOR-REDMI-RV6-D014-20260914'
RELATIVE = 'apps/mobile/build/cursor-review-r66.23'
PREBUILD = 'docs/quality/cursor-redmi-v6-audit-20260913/PREBUILD.md'
PRIOR = ROOT / 'apps/mobile/build/cursor-review-r66.22'
OUTPUT = ROOT / RELATIVE

def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args], text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()

assert len(sys.argv) == 2, 'Supply the exact committed prebuild evidence HEAD'
head = sys.argv[1]
assert git('rev-parse', 'HEAD') == head
assert git('branch', '--show-current') == BRANCH
assert not git('status', '--porcelain=v1'), 'Preserve dirty source'
assert git('ls-remote', '--exit-code', 'origin', 'refs/heads/' + BRANCH).split()[0] == head
assert not OUTPUT.exists(), 'Preserve existing candidate'
assert CANDIDATE in (ROOT / PREBUILD).read_text(encoding='utf-8')
assert not git('diff', '--name-only', SOURCE, '--', 'apps', 'backend', 'contracts', 'packages', 'package.json', 'package-lock.json', 'pubspec.yaml', 'pubspec.lock')

copies = []
for cycle in (1, 2):
    log = EVIDENCE / f'd014-combined-cycle{cycle}.log'
    receipt_path = EVIDENCE / f'd014-combined-cycle{cycle}.result.json'
    receipt = json.loads(receipt_path.read_text(encoding='utf-8-sig'))
    assert receipt['source'] == SOURCE and receipt['exitCode'] == 0
    assert receipt['cycle'] == cycle and receipt['sourceAfter'] == 'equal'
    assert receipt['supportRestoration'] == 'completed'
    assert sha(log) == receipt['logSha256']
    assert '+2339 ~27: All tests passed!' in log.read_text(encoding='utf-8-sig').splitlines()[-1]
    copies += [log.name, receipt_path.name]

required = {
    'd014-qualified-screen.log': 'All tests passed!',
    'd014-qualified-matrix.log': 'All tests passed!',
    'd014-qualified-analysis.log': 'No issues found!',
    'd014-admission-check-approved-ui-locks.log': 'Approved UI reference and production locks passed.',
    'd014-admission-check-buy-protected-baseline.log': 'Protected Buy integrated review qualification passed:',
    'd014-admission-check-buy-backend-contract-boundary.log': 'Buy backend contract boundary passed:',
    'd014-admission-check-buy-data-egress-boundary.log': 'Buy data-egress integrated review boundary passed:',
    'd014-admission-negative.log': 'D014 admission: exact source accepted; five negative cases rejected;',
    'd014-prebuild-build-profile.log': 'CURSOR_UI_REVIEW_BUILD_PROFILE_TESTS_PASSED',
    'd014-prebuild-brand.log': 'Brand integrity gate passed for surface: App',
    'd014-prebuild-clean-support.log': 'Flutter tracked-support cleanliness guard passed.',
    'd014-prebuild-windows-compatibility.log': 'Windows PowerShell 5.1 compatibility gate passed:',
    'd014-prebuild-incremental.log': 'Incremental ticket gate passed:',
    'd014-prebuild-regression-memory.log': 'Codex regression memory passed: entries=4584; applicable=222; phase=build; buildMode=debug.',
}
for name, terminal in required.items():
    assert terminal in (EVIDENCE / name).read_text(encoding='utf-8-sig'), name
copies += list(required)

owners = git('ls-files', '--', 'apps/mobile/lib', 'apps/mobile/android', 'apps/mobile/assets', 'apps/mobile/pubspec.yaml', 'apps/mobile/pubspec.lock').splitlines()
prior = {line[66:]: line[:64] for line in (PRIOR / 'source-manifest.txt').read_text(encoding='utf-8-sig').splitlines()}
assert len(owners) == 326 and set(owners) == set(prior)
current = {owner: sha(ROOT / owner) for owner in owners}
assert [owner for owner in owners if current[owner] != prior[owner]] == ['apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart']
state = json.loads((PRIOR / 'machine-state.json').read_text(encoding='utf-8-sig'))
state.pop('finalEvidenceHead', None)
state['candidate'].update(id=CANDIDATE, head=head, versionName='1.0.0-r66.23', versionCode=2026091404)
state['requiredRuntimeDefines']['MOOLSOCIAL_CANDIDATE_ID'] = CANDIDATE
state['machineState'] = 'prebuild_passed'
state['buildAuthorization'] = 'approved_for_one_build'
state['preBuildValidation'] = {'state': 'passed', 'evidence': PREBUILD}
for gate in state['preBuildGates']:
    gate['state'] = 'passed'
    gate['evidence'] = [PREBUILD]
    mapping = {
        'buy-regression-1': 'd014-combined-cycle1.log',
        'buy-regression-2': 'd014-combined-cycle2.log',
        'format-analysis': 'd014-qualified-analysis.log',
        'focused-tests': 'd014-qualified-screen.log',
        'clean-state-regression': 'd014-prebuild-clean-support.log',
        'wrapper-self-test': 'd014-prebuild-build-profile.log',
        'package-isolation': 'd014-prebuild-build-profile.log',
    }
    if gate['id'] in mapping:
        gate['evidence'].append(RELATIVE + '/evidence/' + mapping[gate['id']])
for gate in state['postBuildGates']:
    gate['state'] = 'pending'
    gate['evidence'] = ['docs/quality/cursor-redmi-v6-audit-20260913/UAT.md']
    if gate['id'] == 'final-evidence-git-handoff':
        gate['state'] = 'failed'
        gate['reason'] = 'Historical commit 448d4a2c uses an incorrect subject prefix; exception not approved or applied.'
state['premiumMotionPolicy']['applied'] = ['existing_nested_product_transition_with_stale_return_cancellation']
state['qualificationLimits'] = [
    '21_original_device_closures_and_D005_C01_preserved_on_prior_evidenced_APKs',
    'D014_corrected_source_locally_qualified_successor_device_replay_pending',
    '27_inherited_capture_skips_are_not_passes',
    'historical_commit_label_handoff_failure_remains_open',
    'review_only_no_production_backend_provider_or_integration_qualification',
    'one_corrective_APK_only_Redmi_TG8HCYTGGQT885OF_data_preserving_install',
]

OUTPUT.mkdir()
manifest = OUTPUT / 'source-manifest.txt'
manifest.write_text(''.join(current[owner] + '  ' + owner + '\n' for owner in sorted(owners)), encoding='utf-8', newline='\n')
state['source'] = {'fileCount': len(owners), 'manifestPath': RELATIVE + '/source-manifest.txt', 'manifestSha256': sha(manifest)}
(OUTPUT / 'evidence').mkdir()
records = []
for name in copies:
    destination = OUTPUT / 'evidence' / name
    shutil.copyfile(EVIDENCE / name, destination)
    assert sha(destination) == sha(EVIDENCE / name)
    records.append({'file': name, 'sha256': sha(destination), 'bytes': destination.stat().st_size})
(OUTPUT / 'machine-state.json').write_text(json.dumps(state, indent=2) + '\n', encoding='utf-8')
(OUTPUT / 'evidence-copy-receipt.json').write_text(json.dumps(records, indent=2) + '\n', encoding='utf-8')
assert not git('status', '--porcelain=v1'), 'Candidate preparation introduced Git dirt'
print(json.dumps({'candidate': CANDIDATE, 'sourceHead': head, 'runtimeFiles': len(owners), 'manifestSha256': sha(manifest), 'built': False, 'handoffPassed': False}))
