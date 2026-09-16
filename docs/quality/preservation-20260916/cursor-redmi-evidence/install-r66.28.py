from pathlib import Path
import subprocess,json,hashlib,re,datetime,xml.etree.ElementTree as ET
root=Path(r'C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913');e=Path(__file__).parent;serial='TG8HCYTGGQT885OF';pkg='com.moolsocial.app.cursorreview'
apk=root/'apps/mobile/build/cursor-review-r66.28/artifacts/uaw-cursor-sku-rows-media-20260916-device-review-debug.apk'
sha=lambda b:hashlib.sha256(b).hexdigest().upper()
assert sha(apk.read_bytes())=='B3172EFB64135D606CD249F751617FE21AB065E50996FE459AEEF991CA7946A8'
assert not (e/'r66.28-installation-receipt.json').exists()
def adb(*args):return subprocess.run(['adb','-s',serial,*args],capture_output=True,check=True).stdout
def snapshot():
 raw=adb('shell','dumpsys','package',pkg).decode();fields={}
 for key in ['userId','dataDir','firstInstallTime','versionCode','versionName']:
  m=re.search(r'^\s*'+key+r'=([^\r\n]+)',raw,re.M);assert m,key;fields[key]=m[1].strip()
 pref={p:sha(adb('shell','run-as',pkg,'cat',p)) for p in ['shared_prefs/FlutterSharedPreferences.xml','files/datastore/FlutterSharedPreferences.preferences_pb']}
 xml=ET.fromstring(adb('shell','run-as',pkg,'cat','shared_prefs/FlutterSharedPreferences.xml'));language=[n.text for n in xml if n.attrib.get('name')=='flutter.moolsocial.ui_review.language.v1']
 return {'fields':fields,'preferenceHashes':pref,'fontScale':adb('shell','settings','get','system','font_scale').decode().strip(),'reviewLanguage':language}
before=snapshot();assert before['fields']['versionName']=='1.0.0-r66.27-cursorreview'
with (e/'r66.28-before-upgrade.json').open('x',encoding='utf-8') as f:json.dump(before,f,indent=2)
r=subprocess.run(['adb','-s',serial,'install','-r',str(apk)],capture_output=True)
with (e/'r66.28-install.log').open('xb') as f:f.write(r.stdout+r.stderr)
assert r.returncode==0 and b'Success' in r.stdout,(r.returncode,r.stderr)
after=snapshot();assert after['fields']['versionName']=='1.0.0-r66.28-cursorreview' and after['fields']['versionCode'].startswith('2026091601 ')
for key in ['userId','dataDir','firstInstallTime']:assert before['fields'][key]==after['fields'][key],key
assert before['preferenceHashes']==after['preferenceHashes'] and before['reviewLanguage']==after['reviewLanguage'] and before['fontScale']==after['fontScale']
installed=adb('shell','pm','path',pkg).decode().strip();assert installed.startswith('package:/data/app/') and installed.endswith('/base.apk')
installedSha=adb('shell','sha256sum',installed.removeprefix('package:')).decode().split()[0].upper();assert installedSha==sha(apk.read_bytes())
d={'candidate':'UAW-CURSOR-SKU-ROWS-MEDIA-20260916','sourceHead':'e450af636f61e86abbcbb9fd3acb1fe34d2696dc','applicationSource':'f0fc06a92bb43627ec4ca952e8996a888ec96ac2','apk':str(apk),'packageId':pkg,'versionName':'1.0.0-r66.28-cursorreview','versionCode':2026091601,'signerSha256':'CBDFC5969AD51ED570AFB1CF2FE60377E559D43F59D59E2AB66CCAF78EA9AC25','apkSha256':sha(apk.read_bytes()),'bytes':apk.stat().st_size,'sourceManifestSha256':'3146E3ED92EC4810B2BDBB62D1C1A0A9B5A281CCED741E95743E9B5D17BE2224','runtimeProfile':'CursorUiReview','buildMode':'debug','promotable':False,'permittedDevice':serial,'installation':'data_preserving_upgrade_succeeded','deviceVerification':'twelve_SKU_records_pending_device_qualification','installedChecksumEqual':True,'installedApkSha256':installedSha,'installedAt':datetime.datetime.now().astimezone().isoformat(),'fontScale':after['fontScale'],'packagePreservationFieldsUnchanged':True,'preferenceHashesUnchanged':True,'reviewLanguageUnchanged':True,'before':before,'after':after,'uiPreservationVerification':'pending actual launch and affected journeys','preUpgradeObservation':'r66.27 resumed with empty Shop body in captures019/020; Saved badge1 retained; no data cleared'}
p=e/'r66.28-installation-receipt.json'
with p.open('x',encoding='utf-8') as f:json.dump(d,f,indent=2)
print(json.dumps({'installed':True,'checksumEqual':True,'dataPreserved':True,'receiptSha256':sha(p.read_bytes()),'apkSha256':installedSha}))
