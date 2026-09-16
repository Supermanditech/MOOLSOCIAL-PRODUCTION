from pathlib import Path
import hashlib, json, re, shutil, subprocess, sys

ROOT = Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
EVIDENCE = Path(__file__).parent
BRANCH = 'work/cursor-ui/redmi-v6-audit-20260913'
CANDIDATE = 'UAW-CURSOR-SKU-NAVIGATION-20260915'
RELATIVE = 'apps/mobile/build/cursor-review-r66.27'
OUTPUT = ROOT / RELATIVE
PREBUILD = 'docs/quality/cursor-redmi-v6-audit-20260913/PREBUILD.md'
RUNTIME_CHANGED = {
 'apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart',
 'apps/mobile/lib/ui_v2/buy/buy_v2_views.dart',
}

def git(*args):
 return subprocess.check_output(['git', '-C', str(ROOT), *args], text=True, encoding='utf-8').strip()
def sha(path):
 return hashlib.sha256(path.read_bytes()).hexdigest().upper()
def read(path):
 data = path.read_bytes()
 return data.decode('utf-16' if data.startswith((b'\xff\xfe', b'\xfe\xff')) else 'utf-8-sig')
def record(name):
 return json.loads(read(EVIDENCE / name))

assert len(sys.argv) == 3, 'Supply exact application-source commit and final prebuild evidence HEAD'
source, head = sys.argv[1:]
assert re.fullmatch('[a-f0-9]{40}', source) and re.fullmatch('[a-f0-9]{40}', head)
assert git('rev-parse', 'HEAD') == head and git('branch', '--show-current') == BRANCH
assert not git('status', '--porcelain=v1'), 'Preserve existing Git dirt'
assert git('ls-remote', '--exit-code', 'origin', 'refs/heads/' + BRANCH).split()[0] == head
subprocess.run(['git', '-C', str(ROOT), 'merge-base', '--is-ancestor', source, head], check=True)
assert not git('diff', '--name-only', source, '--', 'apps', 'backend', 'contracts', 'packages', 'package.json', 'package-lock.json', 'pubspec.yaml', 'pubspec.lock')
assert not OUTPUT.exists(), 'Preserve existing candidate'
assert CANDIDATE in read(ROOT / PREBUILD) and source in read(ROOT / PREBUILD)

copies = []
qualification = record('current-source-qualification-03.json')
assert qualification['state'] == 'local_source_qualified_device_pending'
assert qualification['preservedOwnerCount'] == 3044 and len(qualification['tickets']) == 12
for owner, digest in qualification['sourceHashes'].items():
 assert sha(ROOT / owner) == digest, 'Source changed after qualification: ' + owner
copies.append('current-source-qualification-03.json')

for field in ('priorQualification', 'focusedQualification'):
 bound = qualification[field]
 assert sha(EVIDENCE / bound['path']) == bound['sha256']
 copies.append(bound['path'])
for name in ('sku-swipe-test-03.log', 'sku-navigation-store-02.log', 'sku-navigation-search-01.log'):
 assert 'All tests passed!' in read(EVIDENCE / name).splitlines()[-1]
 copies.append(name)
for name, digest in qualification['combinedReceipts'].items():
 assert sha(EVIDENCE / name) == digest
 copies.append(name)

for name, run in qualification['runs'].items():
 assert sha(EVIDENCE / run['log']) == run['sha256']
 assert read(EVIDENCE / run['log']).splitlines()[-2:] == [run['terminal'], '0']
 copies.append(run['log'])
for name in ('sku-navigation-combined-01', 'sku-navigation-combined-02'):
 receipt = record(name + '.result.json')
 assert receipt['stage'] == name and receipt['exitCode'] == 0
 assert receipt['passed'] is True
 assert qualification['runs'][name]['passed'] == 2429 and qualification['runs'][name]['skipped'] == 27 and qualification['runs'][name]['failed'] == 0
 assert receipt['sourceHashes'] == qualification['sourceHashes']
 assert sha(EVIDENCE / (name + '.log')) == receipt['logSha256']
 assert read(EVIDENCE / (name + '.log')).splitlines()[-1] == '0'
 assert '+2429 ~27: All tests passed!' in read(EVIDENCE / (name + '.log')).splitlines()[-2]
 assert sha(EVIDENCE / (name + '.result.json')) == qualification['combinedReceipts'][name + '.result.json']
 copies.append(name + '.result.json')
prebuild = record('navigation-prebuild-checks.json')
assert prebuild['source'] == source and prebuild['sourceOwnersPreserved'] == 3044
assert prebuild['sourceQualificationReceiptSha256'] == sha(EVIDENCE / 'current-source-qualification-03.json')
required = prebuild['checks']
assert len(required) == 11
for name, check in required.items():
 assert check['exitCode'] == 0 and sha(EVIDENCE / name) == check['sha256']
 assert check['requiredMarker'] in read(EVIDENCE / name)
copies += list(required) + ['navigation-prebuild-checks.json', 'DEVICE-QUALIFICATION-PLAN-r66.27.md']
admission = record('navigation-admission-negative.result.json')
assert admission['source'] == source and len(admission['cases']) == 6
assert [case['rejected'] for case in admission['cases']] == [False, True, True, True, True, True]
assert sha(EVIDENCE / 'navigation-admission-negative.result.json') == prebuild['negativeReceiptSha256']
copies.append('navigation-admission-negative.result.json')

owners = git('ls-files', '--', 'apps/mobile/lib', 'apps/mobile/android', 'apps/mobile/assets', 'apps/mobile/pubspec.yaml', 'apps/mobile/pubspec.lock').splitlines()
prior = {line[66:]: line[:64] for line in read(ROOT / 'apps/mobile/build/cursor-review-r66.26/source-manifest.txt').splitlines()}
assert len(owners) == 326 and set(owners) == set(prior)
current = {owner: sha(ROOT / owner) for owner in owners}
assert {owner for owner in owners if current[owner] != prior[owner]} == RUNTIME_CHANGED
old = json.loads(read(ROOT / 'apps/mobile/build/cursor-review-r66.26/machine-state.json'))
state = {key: old[key] for key in ('schemaVersion', 'contractId', 'premiumMotionPolicy', 'promotion')}
state.update(machineState='prebuild_passed', buildAuthorization='approved_for_one_build', preBuildValidation={'state':'passed','evidence':PREBUILD})
state['candidate'] = dict(gateProfile='uaw_cursor_ui_review_debug', versionCode=2026091503, id=CANDIDATE, versionName='1.0.0-r66.27', branch=BRANCH, buildMode='debug', head=head)
state['applicationSource'] = source
state['requiredRuntimeDefines'] = dict(MOOLSOCIAL_UI_REVIEW_ONLY='true', MOOLSOCIAL_DEVICE_REVIEW='true', MOOLSOCIAL_USE_EMULATORS='true', MOOLSOCIAL_CANDIDATE_ID=CANDIDATE)
mapping = {
 'format-analysis': ['sku-navigation-final-analysis-01.log'],
 'focused-tests': ['current-source-qualification-03.json', 'sku-twelve-navigation-focused-01.json', 'sku-swipe-test-03.log', 'sku-navigation-store-02.log', 'sku-navigation-search-01.log'],
 'positive-release-gates': list(required),
 'protected-boundary-disposition': ['current-source-qualification-03.json', 'navigation-admission-negative.result.json'],
 'buy-regression-1': ['sku-navigation-combined-01.log', 'sku-navigation-combined-01.result.json'],
 'buy-regression-2': ['sku-navigation-combined-02.log', 'sku-navigation-combined-02.result.json'],
 'clean-state-regression': ['navigation-prebuild-clean-support.log'],
 'wrapper-self-test': ['navigation-prebuild-profile.log'],
 'package-isolation': ['navigation-prebuild-profile.log'],
}
state['preBuildGates'] = [dict(id=g['id'], state='passed', evidence=[PREBUILD]+[RELATIVE+'/evidence/'+name for name in mapping.get(g['id'],[])]) for g in old['preBuildGates']]
state['postBuildGates'] = [dict(id=name, state='pending', evidence=['docs/quality/cursor-redmi-v6-audit-20260913/UAT.md']) for name in (
 'artifact-package-version-signer-checksum','installed-apk-checksum-equality','redmi-data-preserving-upgrade',
 'redmi-twelve-SKU-records-presentations','redmi-directly-affected-return-restoration','child-defects-and-original-disposition','final-evidence-git-handoff')]
state['premiumMotionPolicy']['applied'] = ['existing_finite_navigation_and_quantity_transitions']
state['premiumMotionPolicy']['state'] = 'local_source_checks_passed_Redmi_qualification_pending'
state['qualificationLimits'] = [
 '22_original_RV6_defects_and_D005_C01_device_closures_preserved_on_prior_evidenced_APKs',
 'twelve_existing_SKU_records_source_qualified_Redmi_device_verification_pending',
 '27_inherited_skips_and_10_protected_reference_exclusions_are_not_passes',
 'frozen_golden_design_drift_preserved_and_disclosed_separately_no_reference_replacement',
 'review_only_no_production_backend_provider_or_integration_qualification',
 'Redmi_TG8HCYTGGQT885OF_only_data_preserving_upgrade',
]
OUTPUT.mkdir()
manifest = OUTPUT / 'source-manifest.txt'
manifest.write_text(''.join(current[owner]+'  '+owner+'\n' for owner in sorted(owners)),encoding='utf-8',newline='\n')
state['source'] = dict(fileCount=len(owners),manifestPath=RELATIVE+'/source-manifest.txt',manifestSha256=sha(manifest))
(OUTPUT/'evidence').mkdir()
records = []
for name in dict.fromkeys(copies):
 destination = OUTPUT/'evidence'/name
 shutil.copyfile(EVIDENCE/name,destination)
 assert sha(destination) == sha(EVIDENCE/name)
 records.append(dict(file=name,sha256=sha(destination),bytes=destination.stat().st_size))
(OUTPUT/'machine-state.json').write_text(json.dumps(state,indent=2)+'\n',encoding='utf-8')
(OUTPUT/'evidence-copy-receipt.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
assert not git('status','--porcelain=v1'), 'Candidate preparation introduced Git dirt'
print(json.dumps(dict(candidate=CANDIDATE,sourceHead=head,applicationSource=source,runtimeFiles=len(owners),manifestSha256=sha(manifest),built=False,deviceVerified=False)))
