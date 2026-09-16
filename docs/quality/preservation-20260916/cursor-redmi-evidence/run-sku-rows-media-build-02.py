from pathlib import Path
import subprocess,json,hashlib,time,sys
root=Path(r'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913');e=Path(__file__).parent
q=json.loads((e/'current-source-qualification-04.json').read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest().upper()
def preserved():assert all(sha(root/n)==h for n,h in q['sourceHashes'].items())
args=['pwsh','-NoProfile','-ExecutionPolicy','Bypass','-File','scripts/build-buy-device-review.ps1','-CandidateId','UAW-CURSOR-SKU-ROWS-MEDIA-20260916','-BuildName','1.0.0-r66.28','-BuildNumber','2026091601','-SourceFingerprint','3146E3ED92EC4810B2BDBB62D1C1A0A9B5A281CCED741E95743E9B5D17BE2224','-ArtifactDirectory','apps/mobile/build/cursor-review-r66.28/artifacts','-BuildMode','debug','-MachineStatePath','apps/mobile/build/cursor-review-r66.28/machine-state.json','-RuntimeProfile','CursorUiReview','-EvidenceArchiveRoot',r'C:/GUARANTEED OUTCOME/MOOLSOCIAL-ARCHIVE-DIRTY-WORKTREES-20260904']
for stage,extra in [('rows-media-wrapper-preflight-02',['-PreflightOnly']),('rows-media-wrapper-build',[])]:
 preserved();log=e/(stage+'.log');receipt=e/(stage+'.result.json');assert not log.exists() and not receipt.exists()
 print('START '+stage,flush=True);proc=subprocess.Popen(args+extra,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);tail=[];last=0
 with log.open('xb') as f:
  for line in iter(proc.stdout.readline,b''):
   f.write(line);f.flush();text=line.decode('utf-8',errors='replace').strip();tail=(tail+[text])[-12:]
   if time.monotonic()-last>35:print(text,flush=True);last=time.monotonic()
 code=proc.wait();preserved();passed=code==0
 if extra:passed=passed and 'Device-review APK preflight passed without artifact build:' in log.read_text(encoding='utf-8',errors='replace')
 record={'stage':stage,'exitCode':code,'passed':passed,'source':'f0fc06a92bb43627ec4ca952e8996a888ec96ac2','seal':'e450af636f61e86abbcbb9fd3acb1fe34d2696dc','preservedOwnerCount':3044,'logSha256':sha(log),'terminalTail':tail}
 with receipt.open('x',encoding='utf-8') as f:json.dump(record,f,indent=2)
 print(json.dumps({**record,'receiptSha256':sha(receipt)}),flush=True)
 if not passed:sys.exit(code or 1)
