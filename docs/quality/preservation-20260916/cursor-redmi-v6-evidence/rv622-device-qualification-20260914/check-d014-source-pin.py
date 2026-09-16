import hashlib, json, re, subprocess
from pathlib import Path
repo = Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
owner = 'scripts/check-codex-subagent-coordination-policy.ps1'
before = subprocess.check_output(['git','show','HEAD:'+owner], cwd=repo).decode().replace('\r\n','\n')
after = (repo/owner).read_text(encoding='utf-8')
pattern = r'\$fixtureHashes = @\{(.*?)\n      \}'
def pins(text):
    block = re.search(pattern, text, re.S)
    assert block
    return dict(re.findall(r"'([^']+)' = '([A-F0-9]{64})'", block.group(1)))
old, new = pins(before), pins(after)
assert len(old)==5 and len(new)==7
added = set(new)-set(old)
assert added == {'apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart','apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart'}
assert all(new[k]==v for k,v in old.items())
restored = after
for key in added:
    restored = restored.replace("        '"+key+"' = '"+new[key]+"'\n", '')
restored = restored.replace('      # Founder-approved RV6 fixture, D005-C01 and reproduced D014 correction:\n      # exact seven-file source delta within the existing owner claim only.', '      # Founder-approved RV6 fixture plus D005-C01: exact five-file source delta only.')
assert restored==before, 'Unrelated checker change'
policy = json.loads((repo/'config/codex-subagent-coordination-policy.json').read_text(encoding='utf-8-sig'))
claim = next(c for c in policy['activeClaims'] if c['task']=='/root/cursor_redmi_v6_audit_20260913')
assert len(claim['owners'])==49 and set(new)<=set(claim['owners'])
for key, sha in new.items():
    assert hashlib.sha256((repo/key).read_text(encoding='utf-8').encode()).hexdigest().upper()==sha
receipt = Path(__file__).with_name('d014-source-pin-check.json')
assert not receipt.exists()
result = {'existingPinsPreserved':5,'newOwnedPins':2,'ownerClaimCount':49,'allSevenSourceHashesMatch':True,'otherCheckerTextUnchanged':True}
receipt.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result))
