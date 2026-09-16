import pathlib
import subprocess

root = pathlib.Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
evidence = pathlib.Path(__file__).parent
source = '41412f56a4af4d75e2976dc04843dd293ae4869d'
steps = [
    ('check-approved-ui-locks', []),
    ('check-buy-protected-baseline', ['-RepositoryRoot', str(root), '-IntegratedReviewSourceCommit', source]),
    ('check-buy-backend-contract-boundary', ['-RepositoryRoot', str(root), '-IntegratedReviewSourceCommit', source]),
    ('check-buy-data-egress-boundary', ['-RepositoryRoot', str(root), '-IntegratedReviewSourceCommit', source]),
    ('negative', []),
]
for name, args in steps:
    script = evidence / 'test-repeat-source-admission.ps1' if name == 'negative' else root / 'scripts' / (name + '.ps1')
    log = evidence / ('repeat-admission-' + name + '.log')
    assert not log.exists(), 'Preserve existing admission evidence'
    with log.open('xb') as output:
        result = subprocess.run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(script), *args], cwd=root, stdout=output, stderr=subprocess.STDOUT)
    print(name, 'exit', result.returncode, 'log', str(log), flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)
