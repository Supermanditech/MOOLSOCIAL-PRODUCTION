from pathlib import Path
import hashlib,json,subprocess,sys
root=Path(r'C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
e=Path(r'C:\GUARANTEED OUTCOME\MOOLSOCIAL-CURSOR-BUY-UAT-20260905\sku-metadata-redmi-20260914')
source='64ca4d757cffc1cc1fa575b84004cd827e6695ab'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest().upper()
def read(p):
 b=p.read_bytes()
 return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
q=json.loads(read(e/'current-source-qualification-03.json'))
assert len(q['tickets'])==12 and len(q['sourceHashes'])==3044
def preserved():
 for owner,digest in q['sourceHashes'].items():assert sha(root/owner)==digest,owner
preserved()
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==source
assert not (root/'apps/mobile/build/cursor-review-r66.27').exists()
jobs=[
 ('navigation-admission-check-approved-ui-locks','powershell','scripts/check-approved-ui-locks.ps1',[],'Approved UI reference and production locks passed.'),
 ('navigation-admission-check-buy-protected-baseline','powershell','scripts/check-buy-protected-baseline.ps1',['-RepositoryRoot',str(root),'-IntegratedReviewSourceCommit',source],'Protected Buy integrated review qualification passed:'),
 ('navigation-admission-check-buy-backend-contract-boundary','powershell','scripts/check-buy-backend-contract-boundary.ps1',['-RepositoryRoot',str(root),'-IntegratedReviewSourceCommit',source],'Buy backend contract boundary passed:'),
 ('navigation-admission-check-buy-data-egress-boundary','powershell','scripts/check-buy-data-egress-boundary.ps1',['-RepositoryRoot',str(root),'-IntegratedReviewSourceCommit',source],'Buy data-egress integrated review boundary passed:'),
 ('navigation-admission-negative','powershell',str(e/'test-sku-navigation-source-admission.ps1'),['-source',source],'SKU admission: exact source accepted; five negative cases rejected;'),
 ('navigation-prebuild-profile','powershell','scripts/test-cursor-ui-review-build-profile.ps1',['-RepositoryRoot',str(root)],'CURSOR_UI_REVIEW_BUILD_PROFILE_TESTS_PASSED'),
 ('navigation-prebuild-brand','powershell','scripts/check-brand-integrity.ps1',['-Surface','App','-IntegratedReviewSourceCommit',source],'Brand integrity gate passed for surface: App'),
 ('navigation-prebuild-clean-support','powershell','scripts/test-flutter-clean-support.ps1',[],'Flutter tracked-support cleanliness guard passed.'),
 ('navigation-prebuild-windows-compatibility','powershell','scripts/check-windows-powershell-compatibility.ps1',['-RepositoryRoot',str(root),'-IntegratedReviewSourceCommit',source],'Windows PowerShell 5.1 compatibility gate passed:'),
 ('navigation-prebuild-incremental','pwsh','scripts/check-cross-agent-incremental-ticket-gate.ps1',['-Phase','pre_build','-Lane','cursor_ui','-TicketId','UAW-CURSOR-SKU-METADATA-20260914','-UiScope','buy.sku_metadata','-CandidateVersionName','1.0.0-r66.27','-CandidateVersionCode','2026091503','-PackageId','com.moolsocial.app.cursorreview','-RepositoryRoot',str(root)],'Incremental ticket gate passed:'),
 ('navigation-prebuild-memory','powershell','scripts/check-codex-development-regression-memory.ps1',['-Phase','build','-BuildMode','debug','-RepositoryRoot',str(root),'-EvidenceArchiveRoot',r'C:\GUARANTEED OUTCOME\MOOLSOCIAL-ARCHIVE-DIRTY-WORKTREES-20260904'],'Codex regression memory passed: entries=4589; applicable=224; phase=build; buildMode=debug.')
]
checks={}
for name,shell,script,args,marker in jobs:
 log=e/(name+'.log');result=e/(name+'.execution.json')
 assert not log.exists() and not result.exists(),'Preserve prior evidence: '+name
 if name=='navigation-prebuild-clean-support':
  assert not (root/'tmp/rel-build-clean-fixture').exists(),'Preserve any existing fixture; do not delete it'
 command=[shell,'-NoProfile','-ExecutionPolicy','Bypass','-File',script]+args
 print('START '+name,flush=True)
 with log.open('xb') as f:
  proc=subprocess.run(command,cwd=root,stdout=f,stderr=subprocess.STDOUT)
 text=read(log)
 passed=proc.returncode==0 and marker in text
 record={'command':command,'exitCode':proc.returncode,'sha256':sha(log),'requiredMarker':marker,'passed':passed}
 with result.open('x',encoding='utf-8') as f:json.dump(record,f,indent=2)
 print(json.dumps({'stage':name,'exitCode':proc.returncode,'passed':passed,'logSha256':sha(log),'tail':text.splitlines()[-3:]}),flush=True)
 if not passed:sys.exit(proc.returncode or 1)
 preserved()
 checks[log.name]={'sha256':sha(log),'requiredMarker':marker,'exitCode':0}
negative=e/'navigation-admission-negative.result.json'
n=json.loads(read(negative))
assert n['source']==source and [case['rejected'] for case in n['cases']]==[False,True,True,True,True,True]
record={'source':source,'checks':checks,'negativeReceiptSha256':sha(negative),'sourceQualificationReceiptSha256':sha(e/'current-source-qualification-03.json'),'sourceOwnersPreserved':3044,'acceptedFor':'twelve-record r66.27 Cursor Review prebuild','deviceClosure':False}
out=e/'navigation-prebuild-checks.json'
with out.open('x',encoding='utf-8') as f:json.dump(record,f,indent=2)
print(json.dumps({'allChecksPassed':len(checks),'receiptSha256':sha(out),'sourceOwnersPreserved':3044}),flush=True)
