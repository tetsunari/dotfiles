"""Local immutable snapshots for lessons stored on a Windows UNC share."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile


def _scan(directory):
    if not directory.is_dir() or directory.is_symlink():
        raise OSError('Lessons directory unavailable')
    entries = []

    def fail(error):
        raise error

    for root, dirs, files in os.walk(directory, onerror=fail):
        for name in dirs:
            if (Path(root) / name).is_symlink():
                raise OSError('Linked lessons directory')
        for name in files:
            if not name.endswith('.md'):
                continue
            path = Path(root) / name
            if path.is_symlink():
                raise OSError('Linked lesson file')
            stat = path.stat()
            entries.append([path.relative_to(directory).as_posix(), stat.st_size,
                            stat.st_mtime_ns, stat.st_ctime_ns])
    return sorted(entries)


def _complete(snapshot, entries):
    metadata = json.loads((snapshot / '.complete.json').read_text(encoding='utf-8'))
    return metadata['source'] == entries and metadata['cached'] == _scan(snapshot)


def resolve_lessons_dir(source: Path) -> Path:
    override = os.environ.get('LESSONS_CACHE_DIR')
    if not override and not (os.name == 'nt' and str(source).startswith(('\\\\', '//'))):
        return source
    temporary = None
    try:
        entries = _scan(source)
        identity = json.dumps([str(source.absolute()), entries], ensure_ascii=True).encode()
        signature = hashlib.sha256(identity).hexdigest()
        cache = Path(override) if override else Path.home() / '.claude/cache/lessons'
        snapshot = cache / signature
        if snapshot.exists():
            return snapshot if _complete(snapshot, entries) else source
        cache.mkdir(parents=True, exist_ok=True)
        temporary = Path(tempfile.mkdtemp(prefix='.building-', dir=cache))
        for relative, *_ in entries:
            target = temporary / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source / relative, target)
        if _scan(source) != entries:
            return source
        metadata = {'source': entries, 'cached': _scan(temporary)}
        (temporary / '.complete.json').write_text(json.dumps(metadata), encoding='utf-8')
        try:
            temporary.rename(snapshot)
            temporary = None
        except OSError:
            if not snapshot.is_dir():
                raise
        return snapshot if _complete(snapshot, entries) else source
    except (OSError, ValueError, TypeError, KeyError):
        return source
    finally:
        if temporary is not None:
            shutil.rmtree(temporary, ignore_errors=True)


if __name__ == '__main__':
    print(resolve_lessons_dir(Path(sys.argv[1])).as_posix())
