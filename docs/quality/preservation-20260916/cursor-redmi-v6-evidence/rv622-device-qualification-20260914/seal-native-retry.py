import csv, hashlib, json
from pathlib import Path
root = Path(__file__).resolve().parent
register = Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913/docs/quality/cursor-redmi-v6-audit-20260913/EVIDENCE.csv')
manifest = root / 'native-retry-manifest.json'
assert not manifest.exists()
files, rows = [], []
for number in range(32, 40):
    matches = list(root.glob(f'{number:03d}-*.json'))
    assert len(matches) == 1
    path = matches[0]
    data = json.loads(path.read_text(encoding='utf-8-sig'))
    assert data['device'] == 'TG8HCYTGGQT885OF' and data['versionCode'] == 2026091403
    for ext in ('png', 'xml', 'json'):
        item = path.with_suffix('.' + ext)
        sha = hashlib.sha256(item.read_bytes()).hexdigest().upper()
        if ext != 'json':
            assert sha == data[ext + 'Sha256']
        files.append({'file': item.name, 'sha256': sha, 'bytes': item.stat().st_size})
    rows.append(['rv622-' + path.stem, 'UAW-CURSOR-REDMI-RV6-LANGUAGE-20260914', data['device'], path.with_suffix('.png').as_posix(), data['pngSha256'], path.with_suffix('.png').stat().st_size, 'physical-device-reviewed'])
with register.open(encoding='utf-8-sig', newline='') as handle:
    old = list(csv.DictReader(handle))
assert len(old) == 1423
assert not set(r[0] for r in rows).intersection(r['capture_id'] for r in old)
with register.open('a', encoding='utf-8', newline='') as handle:
    csv.writer(handle, quoting=csv.QUOTE_ALL).writerows(rows)
manifest.write_text(json.dumps({'scope':'Explicit user-approved native retries; D009/D010 passed, D014 destination lost', 'files':files}, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'rowsAdded':len(rows),'filesVerified':len(files),'manifestSha256':hashlib.sha256(manifest.read_bytes()).hexdigest().upper()}))
