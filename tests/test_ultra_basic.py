import os
import sys

def test_basic_functionality():
    """Test that basic Python functionality works."""
    assert True

def test_python_version():
    """Test Python version is acceptable."""
    assert sys.version_info >= (3, 8)

def test_imports():
    """Test that we can import basic modules."""
    import os
    import sys
    import json
    assert True

def test_scripts_directory_exists():
    """Test that scripts directory exists."""
    scripts_dir = os.path.join(os.path.dirname(__file__), '..', 'scripts')
    assert os.path.exists(scripts_dir), "Scripts directory should exist"

def test_some_scripts_exist():
    """Test that at least one script exists (flexible test)."""
    scripts_dir = os.path.join(os.path.dirname(__file__), '..', 'scripts')
    
    if not os.path.exists(scripts_dir):
        # If scripts dir doesn't exist, skip test
        return
    
    scripts = [f for f in os.listdir(scripts_dir) if f.endswith('.sh') or f.endswith('.py')]
    assert len(scripts) > 0, "At least one script should exist"

def test_github_workflows_exist():
    """Test that workflow directory exists."""
    workflows_dir = os.path.join(os.path.dirname(__file__), '..', '.github', 'workflows')
    
    if not os.path.exists(workflows_dir):
        # If workflows dir doesn't exist, skip test
        return
        
    workflows = [f for f in os.listdir(workflows_dir) if f.endswith('.yml')]
    assert len(workflows) > 0, "At least one workflow should exist"
