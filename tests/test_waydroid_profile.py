import configparser
import importlib.machinery
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


launcher = load('android_launcher', ROOT / 'integrations/waydroid/files/.local/bin/waydroid-window')
repair = load('android_repair', ROOT / 'tools/repair-waydroid-vendor')


class WaydroidProfileTests(unittest.TestCase):
    def test_size_uses_logical_height_and_visible_output_bars(self):
        output = {'name': 'DP-1', 'logical': {'height': 1080}}
        config = {'bar': {'main': {'position': 'bottom', 'thickness': 48},
                          'other': {'position': 'top', 'thickness': 60}}}
        layers = [{'namespace': 'noctalia-bar-main', 'output': 'DP-1'},
                  {'namespace': 'noctalia-bar-other', 'output': 'DP-2'}]
        self.assertEqual(launcher.fit_size(output, config, 'layout {\n gaps 14\n}', layers), (430, 1004))
        output['logical']['height'] = 720
        self.assertEqual(launcher.fit_size(output, config, ' gaps 14', layers), (276, 644))
        self.assertEqual(launcher.fit_size(output, config, ' gaps 14', []), (297, 692))
        output['logical']['height'] = 200
        with self.assertRaises(RuntimeError):
            launcher.fit_size(output, config, ' gaps 14', layers)

    def fixture(self, root):
        images = root / 'images'
        images.mkdir()
        (images / 'vendor.img').write_bytes(b'original vendor')
        (images / 'system.img').write_bytes(b'untouched system')
        (root / 'data').mkdir()
        (root / 'data/app').write_bytes(b'untouched app')
        (root / 'waydroid.cfg').write_text(
            '[waydroid]\narch=x86_64\nvendor_type=MAINLINE\nimages_path=' + str(images) +
            '\n[properties]\npersist.waydroid.multi_windows=true\nro.hardware.egl=swiftshader\n')
        candidate = root / 'candidate.img'
        candidate.write_bytes(b'new vendor')
        return images, candidate

    def test_success_and_prior_stopped_service(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            images, candidate = self.fixture(root)
            calls = []
            backup = repair.apply(root, candidate, run=lambda *args: calls.append(args), active=False)
            cfg = repair.read_config(root)
            self.assertEqual(cfg['properties']['persist.waydroid.multi_windows'], 'false')
            self.assertNotIn('ro.hardware.egl', cfg['properties'])
            self.assertEqual(cfg['waydroid']['vendor_ota'], repair.OTA)
            self.assertEqual((images / 'vendor.img').read_bytes(), b'new vendor')
            self.assertEqual((backup / 'vendor.img').read_bytes(), b'original vendor')
            self.assertNotIn(('systemctl', 'start', repair.SERVICE), calls)
            self.assertEqual((images / 'system.img').read_bytes(), b'untouched system')
            self.assertEqual((root / 'data/app').read_bytes(), b'untouched app')

    def test_failed_upgrade_restores_vendor_config_and_running_service(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            images, candidate = self.fixture(root)
            original = (root / 'waydroid.cfg').read_bytes()
            calls = []
            def run(*args):
                calls.append(args)
                if args == ('waydroid', 'upgrade', '--offline') and calls.count(args) == 1:
                    raise RuntimeError('fixture upgrade failure')
            with self.assertRaisesRegex(RuntimeError, 'fixture upgrade failure'):
                repair.apply(root, candidate, run=run, active=True)
            self.assertEqual((root / 'waydroid.cfg').read_bytes(), original)
            self.assertEqual((images / 'vendor.img').read_bytes(), b'original vendor')
            self.assertEqual(calls[-1], ('systemctl', 'start', repair.SERVICE))
            self.assertEqual((root / 'data/app').read_bytes(), b'untouched app')

    def test_settings_only_leaves_vendor_and_ota(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            images, _ = self.fixture(root)
            backup = repair.apply(root, run=lambda *args: None, active=False)
            self.assertEqual((images / 'vendor.img').read_bytes(), b'original vendor')
            self.assertFalse((backup / 'vendor.img').exists())
            self.assertNotIn('vendor_ota', repair.read_config(root)['waydroid'])

    def test_bad_archive_and_wrong_arch_rejected_before_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, candidate = self.fixture(root)
            with self.assertRaisesRegex(ValueError, 'SHA256'):
                repair.verify_archive(candidate)
            cfg = root / 'waydroid.cfg'
            cfg.write_text(cfg.read_text().replace('arch=x86_64', 'arch=arm64'))
            calls = []
            with self.assertRaises(ValueError):
                repair.apply(root, candidate, run=lambda *args: calls.append(args), active=True)
            self.assertEqual(calls, [])
            self.assertFalse((root / 'backups').exists())

    def test_optional_install_renders_launcher_and_keeps_base_opt_in(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            subprocess.run([str(ROOT / 'tools/install-flow-profile'), '--home', tmp], check=True, capture_output=True)
            self.assertFalse((home / '.local/bin/waydroid-window').exists())
            subprocess.run([str(ROOT / 'tools/install-flow-profile'), '--with-waydroid', '--home', tmp], check=True, capture_output=True)
            entry = (home / '.local/share/applications/Waydroid.desktop').read_text()
            self.assertIn(f'Exec="{home}/.local/bin/waydroid-window"', entry)
            self.assertTrue((home / '.local/bin/waydroid-window').stat().st_mode & 0o111)


if __name__ == '__main__':
    unittest.main()
