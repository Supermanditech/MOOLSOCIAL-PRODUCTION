"""Positive and rejection tests; no application or device mutation."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch, Mock

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('gate', ROOT/'scripts/check-buy-founder-regression.py')
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class FounderGateTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT/gate.LEDGER).read_text())
        self.ticket = copy.deepcopy(self.data['tickets'][0])
        self.ticket['cases'] = [self.ticket['cases'][0]]
        self.case = self.ticket['cases'][0]
        self.case['testName'] = 'exact cart scenario'
        self.case['local'] = {'sourceSha256': 'current'}

    def test_setup_preserves_open_cases(self):
        gate.validate(ROOT, self.data, 'setup')

    def test_implementation_requires_selection(self):
        self.data['selected'] = []
        with self.assertRaisesRegex(ValueError, 'No selected ticket'):
            gate.validate(ROOT, self.data, 'implementation')

    def test_implementation_requires_named_behavior_test(self):
        self.data['selected'] = ['R6634-C01']
        self.data['tickets'][0]['cases'][0]['testName'] = ''
        with self.assertRaisesRegex(ValueError, 'Name the behavior'):
            gate.validate(ROOT, self.data, 'implementation')

    def test_scenario_removal_rejected(self):
        self.data['tickets'][0]['cases'].pop()
        with self.assertRaisesRegex(ValueError, 'matrix removed'):
            gate.validate(ROOT, self.data, 'setup')

    def test_changed_expectation_rejected(self):
        self.data['tickets'][0]['cases'][0]['expected'] = 'button exists'
        with self.assertRaisesRegex(ValueError, 'matrix removed'):
            gate.validate(ROOT, self.data, 'setup')

    def test_stale_source_rejected(self):
        with self.assertRaisesRegex(ValueError, 'stale local'):
            gate.validate_ticket(ROOT, self.ticket, {}, 'new source', 'build')

    def test_local_pass_does_not_close_device_gap(self):
        with patch.object(gate, 'flutter_pass'), self.assertRaisesRegex(ValueError, 'stale Redmi'):
            gate.validate_ticket(ROOT, self.ticket, {}, 'current', 'close')

    def test_current_local_evidence_allows_build_stage(self):
        with patch.object(gate, 'flutter_pass') as proof:
            gate.validate_ticket(ROOT, self.ticket, {}, 'current', 'build')
            proof.assert_called_once()

    def machine_log(self, skipped=False, result='success', name='exact cart scenario'):
        events = [{'type':'testStart','test':{'id':1,'name':name}},
                  {'type':'testDone','testID':1,'result':result,'skipped':skipped},
                  {'type':'done','success':result == 'success'}]
        return '\n'.join(json.dumps(x) for x in events)

    def test_exact_executed_test_passes(self):
        with patch.object(gate, 'checked_evidence', return_value=Mock(
                read_text=Mock(return_value=self.machine_log()))):
            gate.flutter_pass(ROOT, {}, 'exact cart scenario')

    def test_skipped_test_cannot_pass(self):
        with patch.object(gate, 'checked_evidence', return_value=Mock(
                read_text=Mock(return_value=self.machine_log(skipped=True)))), self.assertRaises(ValueError):
            gate.flutter_pass(ROOT, {}, 'exact cart scenario')

    def test_different_test_cannot_substitute(self):
        with patch.object(gate, 'checked_evidence', return_value=Mock(
                read_text=Mock(return_value=self.machine_log(name='unrelated')))), self.assertRaises(ValueError):
            gate.flutter_pass(ROOT, {}, 'exact cart scenario')

    def test_failed_log_rejected(self):
        with patch.object(gate, 'checked_evidence', return_value=Mock(
                read_text=Mock(return_value=self.machine_log(result='failure')))), self.assertRaises(ValueError):
            gate.flutter_pass(ROOT, {}, 'exact cart scenario')

    def test_path_escape_rejected(self):
        with self.assertRaisesRegex(ValueError, 'escapes'):
            gate.file_at(ROOT, '../unrelated')

    def test_missing_evidence_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Missing file'):
            gate.checked_evidence(ROOT, {'path':'absent-evidence.json','sha256':'0'*64})

    def test_open_child_blocks_closure(self):
        # No cases here to isolate parent-child closure semantics.
        self.ticket['cases'] = []
        self.ticket['children'] = ['new-child']
        with self.assertRaisesRegex(ValueError, 'Open child'):
            gate.validate_ticket(ROOT, self.ticket, {'new-child':{'status':'open'}}, 'current', 'close')

    def test_dependency_blocks_closure(self):
        self.ticket['cases'] = []
        self.ticket['dependencies'] = ['live-provider']
        with self.assertRaisesRegex(ValueError, 'Dependency'):
            gate.validate_ticket(ROOT, self.ticket, {}, 'current', 'close')

    def device_fixture(self):
        self.ticket['founderApproval'] = {'path': 'approval.md', 'sha256': 'proof'}
        self.case['device'] = {'sourceSha256': 'current', 'serial': 'TG8HCYTGGQT885OF',
            'passed': True, 'visualReviewed': True,
            'builtApk': {'path': 'built.apk', 'sha256': 'same'},
            'installedApk': {'path': 'installed.apk', 'sha256': 'same'},
            'screenshot': {'path': 'screen.png', 'sha256': 'proof'},
            'hierarchy': {'path': 'screen.xml', 'sha256': 'proof'}}

    def fake_checked_file(self, root, record):
        return Mock(suffix=Path(record['path']).suffix,
                    read_bytes=Mock(return_value=b'\x89PNG\r\n\x1a\n'))

    def test_complete_evidence_allows_closure(self):
        self.device_fixture()
        with patch.object(gate, 'flutter_pass'), patch.object(
                gate, 'checked_evidence', side_effect=self.fake_checked_file):
            gate.validate_ticket(ROOT, self.ticket, {}, 'current', 'close')

    def test_different_installed_apk_rejected(self):
        self.device_fixture()
        self.case['device']['installedApk']['sha256'] = 'different'
        with patch.object(gate, 'flutter_pass'), patch.object(
                gate, 'checked_evidence', side_effect=self.fake_checked_file), self.assertRaisesRegex(
                ValueError, 'Installed APK differs'):
            gate.validate_ticket(ROOT, self.ticket, {}, 'current', 'close')

    def test_wrong_device_rejected(self):
        self.device_fixture()
        self.case['device']['serial'] = 'emulator'
        with patch.object(gate, 'flutter_pass'), self.assertRaisesRegex(ValueError, 'Wrong acceptance'):
            gate.validate_ticket(ROOT, self.ticket, {}, 'current', 'close')

    def test_unreviewed_visual_rejected(self):
        self.device_fixture()
        self.case['device']['visualReviewed'] = False
        with patch.object(gate, 'flutter_pass'), self.assertRaisesRegex(ValueError, 'visual inspection'):
            gate.validate_ticket(ROOT, self.ticket, {}, 'current', 'close')

    def test_founder_approval_not_inferred_from_tests(self):
        self.device_fixture()
        self.ticket['founderApproval'] = None
        with patch.object(gate, 'flutter_pass'), patch.object(
                gate, 'checked_evidence', side_effect=self.fake_checked_file), self.assertRaisesRegex(
                ValueError, 'Founder visual approval'):
            gate.validate_ticket(ROOT, self.ticket, {}, 'current', 'close')


if __name__ == '__main__':
    unittest.main()
