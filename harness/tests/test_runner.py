import importlib.util
import json
import struct
import tempfile
import unittest
import zlib
from pathlib import Path

spec = importlib.util.spec_from_file_location('runner', Path(__file__).parents[1] / 'runner.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


def png(path, value=0):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 2, 2, 8, 2, 0, 0, 0))
                     + chunk(b'IDAT', zlib.compress((b'\0' + bytes([value]) * 6) * 2)) + chunk(b'IEND', b''))


class GateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name).resolve()
        (self.root / 'harness').mkdir()
        (self.root / 'lib').mkdir()
        (self.root / 'lib/main.dart').write_text('version1')
        png(self.root / 'ref.png')
        manifest = {'max_attempts': 3, 'min_visual_score': 98, 'visual_dimensions': ['geometry'],
                    'units': [{'id': 'S01', 'reference': 'ref.png', 'criteria': ['tests']}]}
        runner.write(self.root / 'harness/manifest.json', manifest)
        self.h = runner.Harness(self.root)

    def tearDown(self):
        self.temp.cleanup()

    def report(self):
        folder = self.h.begin()
        data = runner.read(self.h.template())
        data.update(verdict='PASS', implementer='executor-session', functional_reviewer='qa-session',
                    visual_reviewer='visual-session', open_findings=[], criteria={'tests': True},
                    visual_scores={'geometry': 99}, capture={'viewport': [2, 2], 'reference_crop': [0, 0, 2, 2], 'dpr': 1, 'text_scale': 1})
        for name in data['artifacts']:
            path = folder / (name + ('.png' if name in ['actual', 'reference_crop', 'comparison', 'alternate_viewport'] else '.md'))
            if path.suffix == '.png':
                png(path, 10 if name == 'actual' else 0)
            else:
                path.write_text('Evidence in isolated test fixture')
            data['artifacts'][name] = path.relative_to(self.root).as_posix()
        for i, check in enumerate(data['checks']):
            path = folder / f'check-{i}.log'
            path.write_text('test fixture only: exit 0')
            check.update(exit_code=0, log=path.relative_to(self.root).as_posix())
        return data, folder / 'review.json'

    def test_valid_evidence_advances(self):
        data, path = self.report()
        runner.write(path, data)
        self.assertEqual(self.h.submit(path), [])
        self.assertIsNone(self.h.current())

    def test_template_cannot_pass(self):
        self.h.begin()
        self.assertTrue(self.h.validate(runner.read(self.h.template())))

    def test_changed_code_rejected(self):
        data, _ = self.report()
        (self.root / 'lib/main.dart').write_text('version2')
        self.assertTrue(any('Hash' in e for e in self.h.validate(data)))

    def test_missing_evidence_rejected(self):
        data, _ = self.report()
        data['artifacts']['actual'] = 'missing.png'
        self.assertTrue(self.h.validate(data))

    def test_path_escape_rejected(self):
        data, _ = self.report()
        data['artifacts']['actual'] = 'ref.png'
        self.assertTrue(any('fora da tentativa' in e for e in self.h.validate(data)))

    def test_independent_review_required(self):
        data, _ = self.report()
        data['visual_reviewer'] = data['implementer']
        self.assertTrue(any('independentes' in e for e in self.h.validate(data)))

    def test_three_failures_block(self):
        for _ in range(3):
            data, path = self.report()
            data['verdict'] = 'FAIL'
            runner.write(path, data)
            self.assertTrue(self.h.submit(path))
        self.assertIsNotNone(self.h.state['blocked'])
        with self.assertRaises(ValueError):
            self.h.begin()

    def test_image_copy_rejected(self):
        data, _ = self.report()
        data['artifacts']['actual'] = data['artifacts']['reference_crop']
        self.assertTrue(any('cópia' in e for e in self.h.validate(data)))

    def test_wrong_unit_and_nonfinite_score_rejected(self):
        data, _ = self.report()
        data['unit'] = 'S99'
        data['visual_scores']['geometry'] = float('nan')
        errors = self.h.validate(data)
        self.assertTrue(any('incorreta' in e for e in errors))
        self.assertTrue(any('Nota' in e for e in errors))

    def test_failed_check_rejected(self):
        data, _ = self.report()
        data['checks'][0]['exit_code'] = 1
        self.assertTrue(any('não passou' in e for e in self.h.validate(data)))


if __name__ == '__main__':
    unittest.main()
