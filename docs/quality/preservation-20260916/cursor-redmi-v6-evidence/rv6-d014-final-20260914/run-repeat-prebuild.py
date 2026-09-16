import pathlib
import subprocess

root = pathlib.Path('C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913')
evidence = pathlib.Path(__file__).parent
source = '41412f56a4af4d75e2976dc04843dd293ae4869d'
steps = [
    ('build-profile', 'test-cursor-ui-review-build-profile.ps1', ['-RepositoryRoot', str(root)]),
    ('brand', 'check-brand-integrity.ps1', ['-Surface', 'App', '-IntegratedReviewSourceCommit', source]),
    ('clean-support', 'test-flutter-clean-support.ps1', []),
    ('windows-compatibility', 'check-windows-powershell-compatibility.ps1', ['-RepositoryRoot', str(root), '-IntegratedReviewSourceCommit', source]),
    ('incremental', 'check-cross-agent-incremental-ticket-gate.ps1', ['-Phase', 'pre_build', '-Lane', 'cursor_ui', '-TicketId', 'UAW-CURSOR-REDMI-V6-AUDIT-20260913', '-UiScope', 'buy.redmi_v6_audit', '-CandidateVersionName', '1.0.0-r66.24', '-CandidateVersionCode', '2026091405', '-PackageId', 'com.moolsocial.app.cursorreview', '-RepositoryRoot', str(root)]),
    ('regression-memory', 'check-codex-development-regression-memory.ps1', ['-Phase', 'build', '-BuildMode', 'debug', '-RepositoryRoot', str(root), '-EvidenceArchiveRoot', 'C:/GUARANTEED OUTCOME/MOOLSOCIAL-ARCHIVE-DIRTY-WORKTREES-20260904']),
]
for name, script, args in steps:
    if name == 'clean-support':
        fixture = root / 'tmp/rel-build-clean-fixture'
        assert fixture.resolve().is_relative_to((root / 'tmp').resolve())
        assert not fixture.exists(), 'Preserve an existing support fixture'
    log = evidence / ('repeat-prebuild-' + name + '.log')
    assert not log.exists(), 'Preserve existing prebuild evidence'
    with log.open('xb') as output:
        result = subprocess.run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(root / 'scripts' / script), *args], cwd=root, stdout=output, stderr=subprocess.STDOUT)
    print(name, 'exit', result.returncode, 'log', str(log), flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)
