import os
from pathlib import Path
import shutil
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch

from lessons_cache import resolve_lessons_dir


class LessonsCacheTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source'
        self.source.mkdir()
        (self.source / 'nested').mkdir()
        (self.source / 'nested/a.md').write_text('first', encoding='utf-8')
        self.cache = self.root / 'cache'
        env = patch.dict(os.environ, {'LESSONS_CACHE_DIR': str(self.cache)})
        env.start()
        self.addCleanup(env.stop)

    def test_snapshot_preserves_relative_names_and_warm_avoids_source_reads(self):
        snapshot = resolve_lessons_dir(self.source)
        self.assertNotEqual(snapshot, self.source)
        self.assertEqual((snapshot / 'nested/a.md').read_text(), 'first')
        original_open = Path.open

        def guarded_open(path, *args, **kwargs):
            if path.is_relative_to(self.source):
                raise AssertionError('unexpected source read')
            return original_open(path, *args, **kwargs)

        with patch.object(Path, 'open', guarded_open), patch(
            'shutil.copy2', side_effect=AssertionError('unexpected copy')
        ):
            self.assertEqual(resolve_lessons_dir(self.source), snapshot)

    def test_change_add_and_delete_produce_fresh_snapshots(self):
        first = resolve_lessons_dir(self.source)
        (self.source / 'nested/a.md').write_text('changed')
        second = resolve_lessons_dir(self.source)
        self.assertNotEqual(first, second)
        self.assertEqual((second / 'nested/a.md').read_text(), 'changed')
        (self.source / 'new.md').write_text('added')
        third = resolve_lessons_dir(self.source)
        self.assertEqual((third / 'new.md').read_text(), 'added')
        (self.source / 'nested/a.md').unlink()
        fourth = resolve_lessons_dir(self.source)
        self.assertFalse((fourth / 'nested/a.md').exists())
        self.assertEqual((first / 'nested/a.md').read_text(), 'first')

    def test_missing_source_never_returns_stale_snapshot(self):
        resolve_lessons_dir(self.source)
        shutil.rmtree(self.source)
        self.assertEqual(resolve_lessons_dir(self.source), self.source)

    def test_concurrent_publishers_return_complete_snapshot(self):
        with ThreadPoolExecutor(max_workers=8) as pool:
            results = list(pool.map(resolve_lessons_dir, [self.source] * 16))
        self.assertEqual(len(set(results)), 1)
        self.assertNotEqual(results[0], self.source)
        self.assertEqual((results[0] / 'nested/a.md').read_text(), 'first')

    def test_corrupt_cached_file_falls_back(self):
        snapshot = resolve_lessons_dir(self.source)
        (snapshot / 'nested/a.md').write_text('corrupted')
        self.assertEqual(resolve_lessons_dir(self.source), self.source)

    def test_source_change_during_copy_does_not_publish_stale_snapshot(self):
        original_copy = shutil.copy2

        def changing_copy(source, target):
            original_copy(source, target)
            source.write_text('changed during copy')

        with patch('shutil.copy2', changing_copy):
            self.assertEqual(resolve_lessons_dir(self.source), self.source)
        self.assertEqual(list(self.cache.iterdir()), [])

    def test_incomplete_snapshot_falls_back(self):
        snapshot = resolve_lessons_dir(self.source)
        (snapshot / '.complete.json').unlink()
        self.assertEqual(resolve_lessons_dir(self.source), self.source)

    def test_unwritable_cache_falls_back(self):
        with patch('tempfile.mkdtemp', side_effect=PermissionError):
            self.assertEqual(resolve_lessons_dir(self.source), self.source)

    def test_cache_path_is_file_falls_back(self):
        self.cache.write_text('not a directory')
        self.assertEqual(resolve_lessons_dir(self.source), self.source)

    def test_local_source_without_override_is_untouched(self):
        with patch.dict(os.environ):
            os.environ.pop('LESSONS_CACHE_DIR', None)
            self.assertEqual(resolve_lessons_dir(self.source), self.source)


if __name__ == '__main__':
    unittest.main()
