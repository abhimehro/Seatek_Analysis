import pathlib
from code_health_scanner import read_file_safe


def test_pathlib_null():
    path = pathlib.Path("test\0.txt")
    assert read_file_safe(path) == []
