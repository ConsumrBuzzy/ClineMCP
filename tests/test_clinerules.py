"""Tests for clinerules.py — 4 tests from directive §3."""

from clinemcp.clinerules import ensure_clinerules


class TestEnsureClinerules:
    """Tests for ensure_clinerules function."""

    def test_ensure_clinerules_returns_existing(self, tmp_path):
        """Verify existing .clinerules is returned unchanged."""
        # Create existing .clinerules
        clinerules_path = tmp_path / ".clinerules"
        existing_content = "# Existing rules\nCustom content here."
        clinerules_path.write_text(existing_content, encoding="utf-8")

        result = ensure_clinerules(str(tmp_path))

        assert result["existed"] is True
        assert result["path"] == str(clinerules_path)
        assert result["content"] == existing_content
        assert result["stack"] is None
        assert result["error"] is None

    def test_ensure_clinerules_generates_when_missing(self, tmp_path):
        """Verify .clinerules is generated when missing."""
        result = ensure_clinerules(str(tmp_path))

        assert result["existed"] is False
        assert result["path"] == str(tmp_path / ".clinerules")
        assert result["content"] is not None
        assert len(result["content"]) > 0
        assert result["error"] is None

        # Verify file was actually written
        clinerules_path = tmp_path / ".clinerules"
        assert clinerules_path.exists()
        assert clinerules_path.read_text(encoding="utf-8") == result["content"]

    def test_ensure_clinerules_detects_python_stack(self, tmp_path):
        """Verify python stack is detected from pyproject.toml."""
        # Create pyproject.toml
        (tmp_path / "pyproject.toml").write_text("[project]\nname = 'test'", encoding="utf-8")

        result = ensure_clinerules(str(tmp_path))

        assert result["existed"] is False
        assert result["stack"] == "python"
        assert "pytest" in result["content"]
        assert "uv run pytest --tb=no -q" in result["content"]

    def test_ensure_clinerules_returns_error_for_invalid_path(self, tmp_path):
        """Verify error is returned for non-existent path."""
        non_existent = tmp_path / "nonexistent"
        result = ensure_clinerules(str(non_existent))

        assert result["existed"] is False
        assert result["path"] is None
        assert result["content"] is None
        assert result["stack"] is None
        assert result["error"] is not None
        assert "does not exist or is not a directory" in result["error"]
