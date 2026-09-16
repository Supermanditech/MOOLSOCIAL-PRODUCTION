import copy, json, subprocess
from pathlib import Path
repo = Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
commit = '448d4a2c7c10ee195e711e49aa4cc69a593ff37b'
prefix = 'docs/quality/cursor-redmi-v6-audit-20260913/'
expected = {
    'commit': commit,
    'parent': 'd0dfea24e52c3c60c41d0cd01fcdcd2badfbcd6c',
    'subject': 'docs(redmi): close D005 persistence with r66.22 device evidence',
    'branch': 'work/cursor-ui/redmi-v6-audit-20260913',
    'apps': 'e37147034016157ab241e26f0c8be091d4561a9c',
    'parentApps': 'e37147034016157ab241e26f0c8be091d4561a9c',
    'owners': {
        prefix+'DEFECTS.md': 'dd866dd5ee2f4e7637236095563bb15f568680ce',
        prefix+'EVIDENCE.csv': '18c272611cb3ffd9e815cbfd476eef073778b8cd',
        prefix+'UAT.md': 'd687685148c71995378459ec909e825c72b97050',
        prefix+'scope-state.json': '17ae58a35b227394f23d8afb65ab8153f00d6137',
    },
}
def git(*args):
    return subprocess.check_output(['git',*args],cwd=repo,text=True).strip()
owners = git('diff-tree','--no-commit-id','--name-only','-r',commit).splitlines()
actual = {
    'commit': git('rev-parse',commit),
    'parent': git('show','-s','--format=%P',commit),
    'subject': git('show','-s','--format=%s',commit),
    'branch': git('rev-parse','--abbrev-ref','HEAD'),
    'apps': git('rev-parse',commit+':apps'),
    'parentApps': git('rev-parse',commit+'^:apps'),
    'owners': {owner:git('rev-parse',commit+':'+owner) for owner in owners},
}
assert actual==expected, 'Live Git does not match the proposed historical bindings'
# These check the proposed exact-match specification, not an applied gate.
negative = []
for key in ('commit','parent','subject','branch','apps','parentApps'):
    candidate = copy.deepcopy(actual)
    candidate[key] += '-changed'
    assert candidate != expected
    negative.append('changed-'+key)
for owner in owners:
    candidate = copy.deepcopy(actual)
    candidate['owners'][owner] = '0'*40
    assert candidate != expected
    negative.append('changed-blob-'+owner.rsplit('/',1)[1])
candidate = copy.deepcopy(actual)
candidate['owners']['apps/mobile/lib/unrelated.dart'] = '0'*40
assert candidate != expected
negative.append('extra-source-owner')
candidate = copy.deepcopy(actual)
candidate['owners'].pop(owners[0])
assert candidate != expected
negative.append('missing-owner')
receipt=Path(__file__).with_name('commit-label-proposal-verification.json')
assert not receipt.exists()
receipt.write_text(json.dumps({'liveGitBindings':actual,'negativeSpecificationCases':negative,'repositoryGateModified':False,'limitation':'Specification check only; proposed exception has not been applied and actual handoff remains failed.'},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'liveBindingsMatch':True,'negativeSpecificationCases':len(negative),'repositoryGateModified':False}))
