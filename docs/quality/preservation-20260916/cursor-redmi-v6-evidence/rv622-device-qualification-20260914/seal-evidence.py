import csv
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent
repo = Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
register = repo / 'docs/quality/cursor-redmi-v6-audit-20260913/EVIDENCE.csv'
manifest = root / 'capture-manifest.json'
assert not manifest.exists(), 'Preserve existing sealed manifest'
metadata = sorted(root.glob('[0-9][0-9][0-9]-*.json'))
assert len(metadata) == 22
reviewed = {4, 5, 8, 11, 12, 14, 18, 20, 21, 22}
rows = []
files = []
for item in metadata:
    data = json.loads(item.read_text(encoding='utf-8-sig'))
    label = item.stem
    assert data['label'] == label
    assert data['device'] == 'TG8HCYTGGQT885OF'
    assert data['apkSha256'] == '4EC88FAF583797B60220CC2795CB5690D1F8779130B037CCCF75E98AA1699A16'
    for ext in ('png', 'xml', 'json'):
        path = item.with_suffix('.' + ext)
        digest = hashlib.sha256(path.read_bytes()).hexdigest().upper()
        if ext != 'json':
            assert digest == data[ext + 'Sha256']
        files.append({'path': path.name, 'sha256': digest, 'bytes': path.stat().st_size})
    number = int(label[:3])
    classification = 'physical-device-reviewed' if number in reviewed else 'physical-device-setup'
    if number == 3:
        classification = 'physical-device-transition-not-acceptance'
    rows.append(['rv622-' + label, 'UAW-CURSOR-REDMI-RV6-LANGUAGE-20260914', data['device'], item.with_suffix('.png').as_posix(), data['pngSha256'], item.with_suffix('.png').stat().st_size, classification])
for path in sorted(root.glob('*.log')):
    files.append({'path': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest().upper(), 'bytes': path.stat().st_size})
with register.open(newline='', encoding='utf-8-sig') as handle:
    existing = list(csv.DictReader(handle))
assert len(existing) == 1392, len(existing)
assert not any(row['capture_id'].startswith('rv622-') for row in existing)
with register.open('a', newline='', encoding='utf-8') as handle:
    csv.writer(handle, quoting=csv.QUOTE_ALL).writerows(rows)
manifest.write_text(json.dumps({'device': 'TG8HCYTGGQT885OF', 'originalsClosed': 19, 'childClosed': 'RV6-D005-C01', 'externalLinkUnverified': ['RV6-D009', 'RV6-D010', 'RV6-D014'], 'files': files}, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'captureRowsAdded': len(rows), 'boundFiles': len(files), 'manifestSha256': hashlib.sha256(manifest.read_bytes()).hexdigest().upper()}))
