from pathlib import Path
import hashlib,json
root=Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
evidence=Path(__file__).parent
out=evidence/'current-source-qualification-01.json'
assert not out.exists(), 'Preserve existing qualification receipt'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest().upper()
def read(p):
 b=p.read_bytes()
 return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
p=evidence/'combined-behavior-preservation-03.json'
s=json.loads(read(p))
assert s['exitCode']==0 and s['preservedOwnerCount']==3044
assert len(s['sourceHashes'])==3044
for owner,digest in s['sourceHashes'].items():
 assert sha(root/owner)==digest,owner
results=[]
for stage in ('analysis-06','combined-behavior-05','combined-behavior-06'):
 receipt=evidence/(stage+'.result.json')
 r=json.loads(read(receipt))
 assert r['stage']==stage and r['exitCode']==0 and r['sourceHashes']==s['sourceHashes']
 log=evidence/(stage+'.log')
 assert sha(log)==r['logSha256']
 terminal=read(log).splitlines()[-1]
 assert ('No issues found!' if stage=='analysis-06' else '+2364 ~27: All tests passed!') in terminal
 results.append(dict(stage=stage,exitCode=0,logSha256=sha(log),receiptSha256=sha(receipt),terminal=terminal))
r=dict(state='current_source_analysis_and_two_combined_runs_passed',stages=results,preservedOwnerCount=3044,preservationReceiptSha256=sha(p),protectedReferenceSelector=s['protectedReferenceSelector'],limits=['27 inherited skips per combined run are not passes','10 protected-reference cases excluded; frozen reference drift retained separately','Device qualification pending; no APK built by this verifier'])
out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8')
print(json.dumps(r))
