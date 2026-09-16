from pathlib import Path
import hashlib, json, re, shutil, subprocess, sys

ROOT = Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
EVIDENCE = Path(__file__).parent
BRANCH = 'work/cursor-ui/redmi-v6-audit-20260913'
CANDIDATE = 'UAW-CURSOR-SKU-METADATA-20260915'
RELATIVE = 'apps/mobile/build/cursor-review-r66.25'
OUTPUT = ROOT / RELATIVE
PREBUILD = 'docs/quality/cursor-redmi-v6-audit-20260913/PREBUILD.md'
RUNTIME_CHANGED = {
 'apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart',
 'apps/mobile/lib/ui_v2/buy/buy_v2_design.dart',
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
preservation = record('combined-behavior-preservation-03.json')
assert preservation['exitCode'] == 0 and preservation['preservedOwnerCount'] == 3044
assert preservation['protectedReferenceSelector'] == 'exclude-tags protected-reference'
for owner, digest in preservation['sourceHashes'].items():
 assert sha(ROOT / owner) == digest, 'Source/reference changed after qualification: ' + owner
copies.append('combined-behavior-preservation-03.json')
for name in ('analysis-06', 'combined-behavior-05', 'combined-behavior-06'):
 receipt = record(name + '.result.json')
 assert receipt['stage'] == name and receipt['exitCode'] == 0
 assert receipt['sourceHashes'] == preservation['sourceHashes']
 assert sha(EVIDENCE / (name + '.log')) == receipt['logSha256']
 terminal = 'No issues found!' if name == 'analysis-06' else '+2364 ~27: All tests passed!'
 assert terminal in read(EVIDENCE / (name + '.log')).splitlines()[-1]
 copies += [name + '.log', name + '.result.json']
visual = record('local-layout-qualification-v6.json')
assert visual['passed'] == 20 and visual['failed'] == 0
assert sha(EVIDENCE / visual['log']) == visual['logSha256']
for owner, digest in visual['normalizedOwnerHashes'].items():
 assert hashlib.sha256((ROOT / owner).read_text(encoding='utf-8-sig').encode('utf-8')).hexdigest().upper() == digest
for name, digest in visual['images'].items():
 assert sha(EVIDENCE / name) == digest
copies += ['focused-08.log', 'local-layout-qualification-v6.json']
required = {
 'sku-admission-check-approved-ui-locks.log': 'Approved UI reference and production locks passed.',
 'sku-admission-check-buy-protected-baseline.log': 'Protected Buy integrated review qualification passed:',
 'sku-admission-check-buy-backend-contract-boundary.log': 'Buy backend contract boundary passed:',
 'sku-admission-check-buy-data-egress-boundary.log': 'Buy data-egress integrated review boundary passed:',
 'sku-admission-negative.log': 'SKU admission: exact source accepted; five negative cases rejected;',
 'prebuild-profile-01.log': 'CURSOR_UI_REVIEW_BUILD_PROFILE_TESTS_PASSED',
 'sku-prebuild-brand.log': 'Brand integrity gate passed for surface: App',
 'prebuild-clean-support-01.log': 'Flutter tracked-support cleanliness guard passed.',
 'sku-prebuild-windows-compatibility.log': 'Windows PowerShell 5.1 compatibility gate passed:',
 'sku-prebuild-incremental.log': 'Incremental ticket gate passed:',
 'prebuild-memory-pwsh7-02.log': 'Codex regression memory passed: entries=4587; applicable=222; phase=build; buildMode=debug.',
}
for name, terminal in required.items():
 assert terminal in read(EVIDENCE / name), 'Missing gate evidence: ' + name
copies += list(required)
admission = record('sku-admission-negative.result.json')
assert admission['source'] == source and len(admission['cases']) == 6
assert [case['rejected'] for case in admission['cases']] == [False, True, True, True, True, True]
copies.append('sku-admission-negative.result.json')

owners = git('ls-files', '--', 'apps/mobile/lib', 'apps/mobile/android', 'apps/mobile/assets', 'apps/mobile/pubspec.yaml', 'apps/mobile/pubspec.lock').splitlines()
prior = {line[66:]: line[:64] for line in read(ROOT / 'apps/mobile/build/cursor-review-r66.24/source-manifest.txt').splitlines()}
assert len(owners) == 326 and set(owners) == set(prior)
current = {owner: sha(ROOT / owner) for owner in owners}
assert {owner for owner in owners if current[owner] != prior[owner]} == RUNTIME_CHANGED
old = json.loads(read(ROOT / 'apps/mobile/build/cursor-review-r66.24/machine-state.json'))
state = {key: old[key] for key in ('schemaVersion', 'contractId', 'premiumMotionPolicy', 'promotion')}
state.update(machineState='prebuild_passed', buildAuthorization='approved_for_one_build', preBuildValidation={'state':'passed','evidence':PREBUILD})
state['candidate'] = dict(gateProfile='uaw_cursor_ui_review_debug', versionCode=2026091501, id=CANDIDATE, versionName='1.0.0-r66.25', branch=BRANCH, buildMode='debug', head=head)
state['applicationSource'] = source
state['requiredRuntimeDefines'] = dict(MOOLSOCIAL_UI_REVIEW_ONLY='true', MOOLSOCIAL_DEVICE_REVIEW='true', MOOLSOCIAL_USE_EMULATORS='true', MOOLSOCIAL_CANDIDATE_ID=CANDIDATE)
mapping = {
 'format-analysis': ['analysis-06.log'], 'focused-tests':['focused-08.log','local-layout-qualification-v6.json'],
 'positive-release-gates': list(required),
 'protected-boundary-disposition':['combined-behavior-preservation-03.json','sku-admission-negative.result.json'],
 'buy-regression-1':['combined-behavior-05.log','combined-behavior-05.result.json'],
 'buy-regression-2':['combined-behavior-06.log','combined-behavior-06.result.json'],
 'clean-state-regression':['prebuild-clean-support-01.log'],
 'wrapper-self-test':['prebuild-profile-01.log'], 'package-isolation':['prebuild-profile-01.log'],
}
state['preBuildGates'] = [dict(id=g['id'], state='passed', evidence=[PREBUILD]+[RELATIVE+'/evidence/'+name for name in mapping.get(g['id'],[])]) for g in old['preBuildGates']]
state['postBuildGates'] = [dict(id=name, state='pending', evidence=['docs/quality/cursor-redmi-v6-audit-20260913/UAT.md']) for name in (
 'artifact-package-version-signer-checksum','installed-apk-checksum-equality','redmi-data-preserving-upgrade',
 'redmi-SKU-M01-through-M05-presentations','redmi-directly-affected-return-restoration','child-defects-and-original-disposition','final-evidence-git-handoff')]
state['premiumMotionPolicy']['applied'] = ['existing_finite_navigation_and_quantity_transitions']
state['premiumMotionPolicy']['state'] = 'local_source_checks_passed_Redmi_qualification_pending'
state['qualificationLimits'] = [
 '22_original_RV6_defects_and_D005_C01_device_closures_preserved_on_prior_evidenced_APKs',
 'five_new_SKU_tickets_source_qualified_Redmi_device_verification_pending',
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
