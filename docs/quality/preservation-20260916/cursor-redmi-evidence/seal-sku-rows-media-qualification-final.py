from pathlib import Path
import datetime,hashlib,json,re,subprocess
root=Path(r"C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913")
e=Path(__file__).parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest().upper()
def read(p):return p.read_text(encoding="utf-8-sig")
prior=json.loads(read(e/"current-source-qualification-03.json"))
before=json.loads(read(e/"sku-rows-media-combined-before-07.json"))
source=before["sourceHashes"]
assert len(source)==3044
assert {name:sha(root/name) for name in source}==source
tracked=subprocess.check_output(["git","ls-files","-z","--","apps/mobile/lib","apps/mobile/test","apps/backend","backend","contracts","packages"],cwd=root)
assert hashlib.sha256(tracked).hexdigest().upper()==before["trackedPathDigest"]
runs={};receipts={}
for stage in ["sku-final-analysis-12","sku-rows-media-combined-07","sku-rows-media-combined-08"]:
 p=e/(stage+".result.json");d=json.loads(read(p));log=e/(stage+".log")
 assert d["exitCode"]==0 and d["passed"] is True and d["sourceHashes"]==source
 assert sha(log)==d["logSha256"]
 lines=read(log).splitlines();assert lines[-1]=="0"
 terminal=lines[-2]
 r={"log":log.name,"sha256":sha(log),"terminal":terminal,"exitCode":0}
 if "combined" in stage:
  match=re.fullmatch(r"[0-9:]+ \+(\d+) ~(\d+): All tests passed!",terminal)
  assert match and tuple(map(int,match.groups()))==(2454,27),terminal
  r.update(passed=2454,skipped=27,failed=0)
 elif "provider" in stage:
  assert "+18: All tests passed!" in terminal
  r.update(passed=18,skipped=0,failed=0)
 else:assert "No issues found!" in terminal
 runs[stage]=r;receipts[p.name]=sha(p)
d={"recordedAtUtc":datetime.datetime.now(datetime.timezone.utc).isoformat(),"state":"local_source_qualified_device_pending","tickets":prior["tickets"],"preservedOwnerCount":3044,"sourceHashes":source,"runs":runs,"combinedReceipts":receipts,"priorQualification":{"path":"current-source-qualification-03.json","sha256":sha(e/"current-source-qualification-03.json"),"applicationSource":"64ca4d757cffc1cc1fa575b84004cd827e6695ab","scope":"Preserved prior SKU/M02/navigation evidence; final combined runs qualify current row-removal and compact-photo correction."},"focusedQualification":{"path":"sku-rows-media-focused-02.json","sha256":sha(e/"sku-rows-media-focused-02.json"),"scope":"Final 30 focused cases and actual PNGs, with preserved prior media/gesture and failed-regression provenance; combined runs qualify all final source bytes."},"limits":["27 inherited skips per run and ten protected-reference exclusions are not passes","No source-stage or simulated-media fixture is relabeled as Redmi or provider-publication closure","Current application source commit, successor APK and remaining twelve-record Redmi qualification pending","No backend, OPPO, production deployment or integration scope"]}
assert len(d["tickets"])==12
out=e/"current-source-qualification-04.json"
with out.open("x",encoding="utf-8") as f:json.dump(d,f,indent=2)
assert json.loads(read(out))==d
print(json.dumps({"qualified":True,"sourceOwners":3044,"eachCombinedPassed":2454,"eachCombinedSkipped":27,"receiptSha256":sha(out)}))
