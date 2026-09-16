import datetime
import hashlib
import json
import pathlib
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

root = pathlib.Path(__file__).parent / 'captures'
root.mkdir(exist_ok=True)
proof = pathlib.Path(__file__).parent / 'installation-receipt.json'
assert hashlib.sha256(proof.read_bytes()).hexdigest().upper() == '01502AFB9FBD621E777FB2220803A4D2F662E8DAB4390D48FEC380457099A885'
installed = json.loads(proof.read_text())
assert installed['installedChecksumEqual'] and installed['versionCode'] == 2026091405
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
assert b'versionCode=2026091405 ' in identity
assert b'versionName=1.0.0-r66.24-cursorreview' in identity
time.sleep(2)
foreground = adb('shell', 'dumpsys', 'activity', 'activities').stdout
assert any(b'com.moolsocial.app.cursorreview/' in line for line in foreground.splitlines() if b'topResumedActivity=' in line)
remote = '/sdcard/rv624-' + label
adb('shell', 'screencap', '-p', remote + '.png')
adb('pull', remote + '.png', str(base) + '.png')
dump = adb('shell', 'uiautomator', 'dump', remote + '.xml')
base.with_suffix('.stderr.txt').write_bytes(dump.stderr)
adb('pull', remote + '.xml', str(base) + '.xml')
tree = ET.parse(base.with_suffix('.xml'))
record = {'sourceHead': installed['sourceHead'], 'apkSha256': installed['apkSha256'], 'installationReceiptSha256': '01502AFB9FBD621E777FB2220803A4D2F662E8DAB4390D48FEC380457099A885', 'fontScale': adb('shell', 'settings', 'get', 'system', 'font_scale').stdout.decode().strip(), 'label': label, 'serial': serial, 'version': '1.0.0-r66.24-cursorreview', 'capturedAt': datetime.datetime.now().astimezone().isoformat(), 'uiautomatorExit': dump.returncode, 'stderrBytes': len(dump.stderr), 'files': {ext: hashlib.sha256(base.with_suffix(ext).read_bytes()).hexdigest() for ext in ['.png', '.xml', '.stderr.txt']}}
base.with_suffix('.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print(json.dumps(record))
for node in tree.iter('node'):
    if node.get('content-desc') or node.get('text'):
        print(ascii((node.get('content-desc'), node.get('text'), node.get('bounds'))))
