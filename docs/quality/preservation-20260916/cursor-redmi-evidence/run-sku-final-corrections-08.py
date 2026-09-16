from pathlib import Path
import hashlib,json,subprocess,sys,time
root=Path(r'C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
e=Path(r'C:\GUARANTEED OUTCOME\MOOLSOCIAL-CURSOR-BUY-UAT-20260905\sku-metadata-redmi-20260914')
prior=json.loads((e/'current-source-qualification-03.json').read_text(encoding='utf-8-sig'))
owners=sorted(prior['sourceHashes'])
assert len(owners)==3044
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest().upper()
def snapshot(): return {name:sha(root/name) for name in owners}
baseline=snapshot()
changed=[name for name in owners if baseline[name]!=prior['sourceHashes'][name].upper()]
assert set(changed)=={'apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart','apps/mobile/test/ui_v2/buy/buy_v2_partner_catalogue_test.dart','apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart','apps/mobile/test/ui_v2/buy/buy_v2_product_variant_selection_test.dart','apps/mobile/test/ui_v2/buy/buy_v2_product_continuity_test.dart'},changed
tracked=subprocess.run(['git','ls-files','-z','--','apps/mobile/lib','apps/mobile/test','apps/backend','backend','contracts','packages'],cwd=root,capture_output=True,check=True).stdout
before=e/'sku-final-corrections-before-08.json'
with before.open('x',encoding='utf-8') as f:
 json.dump({'sourceHashes':baseline,'changedFromR6627':changed,'trackedPathDigest':hashlib.sha256(tracked).hexdigest().upper()},f,indent=2)
tests="test/ui_v2/buy test/ui_v2/profile/global_privacy_preferences_v2_test.dart test/ui_v2/profile/global_personal_profile_v2_test.dart test/ui_v2/profile/global_security_v2_test.dart test/chat_settings_hub_test.dart test/app/ui_review_language_store_test.dart"
visual=' --dart-define=BUY_R663_VISUAL_CAPTURE=true --dart-define="BUY_R663_VISUAL_DIRECTORY=C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/sku-metadata-redmi-20260914/sku-final-visual-08"'
jobs=[
 ('sku-final-analysis-08','analyze --no-pub lib/ui_v2/buy/buy_v2_catalogue.dart test/ui_v2/buy/buy_v2_partner_catalogue_test.dart test/ui_v2/buy/buy_v2_screen_test.dart test/ui_v2/buy/buy_v2_product_variant_selection_test.dart test/ui_v2/buy/buy_v2_product_continuity_test.dart','No issues found!'),
 ('sku-final-return-08','test --no-pub test/ui_v2/buy/buy_v2_product_continuity_test.dart --name "R66 Compare returns through source|R66 Saved return retains the vertical browsing position" --reporter expanded','All tests passed!'),
 ('sku-final-badge-08','test --no-pub test/ui_v2/buy/buy_v2_scoped_cart_checkout_dock_continuity_test.dart --plain-name "R664 Saved badge fits"'+visual+' --reporter expanded','All tests passed!'),
 ('sku-final-screen-08','test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --name "R66 landscape .* retains usable product actions|Masala Ghar storefront is compact"'+visual+' --reporter expanded','All tests passed!'),
 ('sku-final-media-08','test --no-pub test/ui_v2/buy/buy_v2_product_variant_selection_test.dart --plain-name "SKU media grid"'+visual+' --reporter expanded','All tests passed!')
]
for stage, flutterArgs, marker in jobs:
 log=e/(stage+'.log');receipt=e/(stage+'.result.json')
 assert not log.exists() and not receipt.exists()
 assert snapshot()==baseline
 command=". './scripts/invoke-flutter-with-clean-support.ps1'; Invoke-MoolSocialFlutterWithCleanSupport -RepositoryRoot '"+str(root)+"' -Invocation { Push-Location './apps/mobile'; try { & flutter "+flutterArgs+" } finally { Pop-Location } }; exit $LASTEXITCODE"
 print('START '+stage,flush=True)
 process=subprocess.Popen(['powershell','-NoProfile','-Command',command],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 last=0;tail=[]
 with log.open('xb') as output:
  for line in iter(process.stdout.readline,b''):
   output.write(line);output.flush()
   decoded=line.decode('utf-8',errors='replace').strip()
   tail=(tail+[decoded])[-12:]
   if time.monotonic()-last>40 or 'All tests passed!' in decoded or '[E]' in decoded:
    print(decoded,flush=True);last=time.monotonic()
 code=process.wait()
 assert snapshot()==baseline,'Source changed during run'
 actual=subprocess.run(['git','ls-files','-z','--','apps/mobile/lib','apps/mobile/test','apps/backend','backend','contracts','packages'],cwd=root,capture_output=True,check=True).stdout
 assert actual==tracked,'Tracked source path set changed'
 success=code==0 and any(marker in line for line in tail)
 result={'stage':stage,'exitCode':code,'passed':success,'requiredMarker':marker,'sourceHashes':baseline,'preservedOwnerCount':len(baseline),'logSha256':sha(log),'terminalTail':tail,'limits':['27 inherited skips are not passes','protected-reference exclusion unchanged; no frozen reference edits']}
 with receipt.open('x',encoding='utf-8') as f:json.dump(result,f,indent=2)
 print(json.dumps({'stage':stage,'exitCode':code,'passed':success,'logSha256':sha(log),'receiptSha256':sha(receipt),'tail':tail[-3:]}),flush=True)
 if not success:sys.exit(code or 1)
print('Final five-failure corrections and media visual checks passed; 3044 source owners preserved.',flush=True)
