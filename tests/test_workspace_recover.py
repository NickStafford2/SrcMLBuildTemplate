"""Host-side recovery safety checks using disposable local Git repositories."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


HELPER = Path(__file__).resolve().parents[1] / 'bin/workspace-recover'


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='workspace-recover-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source'
        self.git('init', '-b', 'main', str(self.source))
        self.git('-C', str(self.source), '-c', 'user.name=Recovery Test',
                 '-c', 'user.email=recovery@example.invalid', 'commit', '--allow-empty', '-m', 'base')
        self.commit = self.git('-C', str(self.source), 'rev-parse', 'HEAD').stdout.strip()
        self.git('-C', str(self.source), 'branch', 'profiler')
        self.workspace = self.root / 'workspace'
        (self.workspace / 'bin').mkdir(parents=True)
        shutil.copyfile(HELPER, self.workspace / 'bin/workspace-recover')
        self.entry = dict(path='srcMove', url=str(self.source), branch='main', commit=self.commit)
        self.save([self.entry])

    def git(self, *args):
        return subprocess.run(['git', *args], text=True, capture_output=True, check=True)

    def save(self, entries):
        (self.workspace / 'workspace.recovery.json').write_text(json.dumps(
            dict(schema_version=1, repositories=entries)))

    def recover(self, *args):
        return subprocess.run([sys.executable, str(self.workspace / 'bin/workspace-recover'), *args],
                              text=True, capture_output=True)

    def test_preview_does_not_clone(self):
        self.assertEqual(self.recover().returncode, 0)
        self.assertFalse((self.workspace / 'srcMove').exists())

    def test_clone_pins_older_commit_and_preserves_additional_branch(self):
        self.git('-C', str(self.source), '-c', 'user.name=Recovery Test',
                 '-c', 'user.email=recovery@example.invalid', 'commit', '--allow-empty', '-m', 'newer')
        self.entry['additional_refs'] = [dict(remote='personal', url=str(self.source),
                                             branch='profiler', commit=self.commit)]
        self.save([self.entry])
        result = self.recover('--apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git('-C', str(self.workspace / 'srcMove'), 'rev-parse', 'HEAD').stdout.strip(), self.commit)
        self.assertEqual(self.recover('--verify').returncode, 0)

    def test_existing_dirty_tree_is_not_modified(self):
        self.assertEqual(self.recover('--apply').returncode, 0)
        checkout = self.workspace / 'srcMove'
        (checkout / 'work.txt').write_text('keep my work')
        self.git('-C', str(checkout), 'add', 'work.txt')
        result = self.recover('--apply')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((checkout / 'work.txt').read_text(), 'keep my work')
        self.assertEqual(self.git('-C', str(checkout), 'diff', '--cached', '--name-only').stdout.strip(), 'work.txt')

    def test_existing_non_repository_and_wrong_origin_are_rejected(self):
        (self.workspace / 'srcMove').mkdir()
        self.assertNotEqual(self.recover('--apply').returncode, 0)
        (self.workspace / 'srcMove').rmdir()
        self.assertEqual(self.recover('--apply').returncode, 0)
        self.git('-C', str(self.workspace / 'srcMove'), 'remote', 'set-url', 'origin', str(self.root / 'other'))
        self.assertNotEqual(self.recover('--verify').returncode, 0)

    def test_private_checkout_is_opt_in_and_path_cannot_escape(self):
        thesis = dict(self.entry, path='thesis-workspace')
        self.save([thesis])
        self.assertEqual(self.recover('--apply').returncode, 0)
        self.assertFalse((self.workspace / 'thesis-workspace').exists())
        self.assertEqual(self.recover('--include-thesis', '--apply').returncode, 0)
        self.save([dict(self.entry, path='../escape')])
        self.assertNotEqual(self.recover('--apply').returncode, 0)
        self.assertFalse((self.root / 'escape').exists())

    def test_capture_requires_committed_work_and_keeps_snapshot_on_failure(self):
        self.assertEqual(self.recover('--apply').returncode, 0)
        checkout = self.workspace / 'srcMove'
        self.git('-C', str(checkout), '-c', 'user.name=Recovery Test',
                 '-c', 'user.email=recovery@example.invalid', 'commit', '--allow-empty', '-m', 'reviewed')
        self.assertEqual(self.recover('--capture').returncode, 0)
        snapshot = self.workspace / 'workspace.recovery.json'
        saved = snapshot.read_bytes()
        captured = json.loads(saved)['repositories'][0]['commit']
        self.assertNotEqual(captured, self.commit)
        (checkout / 'work.txt').write_text('uncommitted')
        self.git('-C', str(checkout), 'add', 'work.txt')
        self.assertNotEqual(self.recover('--capture').returncode, 0)
        self.assertEqual(snapshot.read_bytes(), saved)


if __name__ == '__main__':
    unittest.main()
