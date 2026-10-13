"""Exercise the profile installer's user-file preservation boundaries."""
from pathlib import Path
import subprocess
import tempfile
import unittest

PROJECT = Path(__file__).resolve().parent.parent
INSTALLER = PROJECT / 'tools/install-flow-profile'

class FlowProfileInstallTests(unittest.TestCase):
    def install(self, home, *args):
        return subprocess.run([str(INSTALLER), '--home', str(home), *args],
                              text=True, capture_output=True)

    def test_dry_run_does_not_create_or_replace_files(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root) / 'home'
            existing = home / '.config/niri/config.kdl'
            existing.parent.mkdir(parents=True)
            existing.write_text('original\n')
            result = self.install(home, '--dry-run')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(existing.read_text(), 'original\n')
            self.assertFalse((home / '.local').exists())

    def test_install_preserves_original_file_and_renders_home_with_spaces(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root) / 'home with spaces'
            existing = home / '.config/niri/config.kdl'
            existing.parent.mkdir(parents=True)
            existing.write_text('original\n')
            result = self.install(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            backups = list((home / '.local/state/nextraos-flow/backups').glob('*/.config/niri/config.kdl'))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), 'original\n')
            self.assertNotIn('@HOME@', existing.read_text())
            self.assertIn(str(home), existing.read_text())

    def test_directory_link_outside_home_is_rejected_before_writing(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root) / 'home'
            outside = Path(root) / 'outside'
            home.mkdir(); outside.mkdir()
            (home / '.config').symlink_to(outside, target_is_directory=True)
            result = self.install(home)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(list(outside.iterdir()), [])
            self.assertFalse((home / '.local').exists())

    def test_backup_directory_link_outside_home_is_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root) / 'home'
            outside = Path(root) / 'outside'
            outside.mkdir()
            state = home / '.local/state'
            state.mkdir(parents=True)
            (state / 'nextraos-flow').symlink_to(outside, target_is_directory=True)
            result = self.install(home)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(list(outside.iterdir()), [])
            self.assertFalse((home / '.config').exists())
