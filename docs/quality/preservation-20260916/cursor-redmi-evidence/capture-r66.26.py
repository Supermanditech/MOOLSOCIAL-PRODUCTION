import datetime
import hashlib
import json
import pathlib
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

root = pathlib.Path(__file__).parent / 'r66.26-captures'
root.mkdir(exist_ok=True)
proof = pathlib.Path(__file__).parent / 'r66.26-installation-receipt.json'
assert len(sys.argv) == 3, 'Supply unique capture label and verified installation receipt SHA256'
receipt_sha = sys.argv[2]
assert len(receipt_sha) == 64 and all(c in '0123456789ABCDEF' for c in receipt_sha)
assert hashlib.sha256(proof.read_bytes()).hexdigest().upper() == receipt_sha
installed = json.loads(proof.read_text(encoding='utf-8-sig'))
assert installed['packageId'] == 'com.moolsocial.app.cursorreview'
assert installed['applicationSource'] == 'd6d9890fa7754a38a05b183bc8ca6e89eccf22cc'
assert installed['installedChecksumEqual'] and installed['versionCode'] == 2026091502
label = sys.argv[1]
assert label.replace('-', '').isalnum()
base = root / label
assert not any(root.glob(label + '.*')), 'Evidence label already exists'
serial = 'TG8HCYTGGQT885OF'

def adb(*args):
    result = subprocess.run(['adb', '-s', serial, *args], capture_output=True)
    if result.returncode:
        raise RuntimeError((args, result.returncode, result.stderr))
    return result

identity = adb('shell', 'dumpsys', 'package', 'com.moolsocial.app.cursorreview').stdout
assert b'versionCode=2026091502 ' in identity
assert b'versionName=1.0.0-r66.26-cursorreview' in identity
time.sleep(2)
foreground = adb('shell', 'dumpsys', 'activity', 'activities').stdout
assert any(b'com.moolsocial.app.cursorreview/' in line for line in foreground.splitlines() if b'topResumedActivity=' in line)
remote = '/sdcard/sku626-' + label
adb('shell', 'screencap', '-p', remote + '.png')
adb('pull', remote + '.png', str(base) + '.png')
dump = adb('shell', 'uiautomator', 'dump', remote + '.xml')
base.with_suffix('.stderr.txt').write_bytes(dump.stderr)
adb('pull', remote + '.xml', str(base) + '.xml')
tree = ET.parse(base.with_suffix('.xml'))
record = {'sourceHead': installed['sourceHead'], 'apkSha256': installed['apkSha256'], 'installationReceiptSha256': receipt_sha, 'fontScale': adb('shell', 'settings', 'get', 'system', 'font_scale').stdout.decode().strip(), 'label': label, 'serial': serial, 'version': '1.0.0-r66.26-cursorreview', 'capturedAt': datetime.datetime.now().astimezone().isoformat(), 'uiautomatorExit': dump.returncode, 'stderrBytes': len(dump.stderr), 'files': {ext: hashlib.sha256(base.with_suffix(ext).read_bytes()).hexdigest() for ext in ['.png', '.xml', '.stderr.txt']}}
base.with_suffix('.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print(json.dumps(record))
print(json.dumps({'hierarchyNodes': len(list(tree.iter('node'))), 'hierarchySaved': str(base.with_suffix('.xml'))}))
