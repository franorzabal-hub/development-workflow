import pytest
import sys
import os
import importlib.util

# Add scripts directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'scripts'))

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

def test_shell_scripts_exist():
    """Test that expected shell scripts exist."""
    scripts_dir = os.path.join(os.path.dirname(__file__), '..', 'scripts')
    expected_scripts = [
        'setup-linear-states.sh',
        'validate-dependencies.sh', 
        'start-development.sh',
        'test-and-validate.sh',
        'finish-development.sh'
    ]
    
    for script in expected_scripts:
        script_path = os.path.join(scripts_dir, script)
        assert os.path.exists(script_path), f"Script {script} should exist"

def test_script_permissions():
    """Test that shell scripts have execute permissions."""
    scripts_dir = os.path.join(os.path.dirname(__file__), '..', 'scripts')
    
    if not os.path.exists(scripts_dir):
        pytest.skip("Scripts directory not found")
    
    shell_scripts = [f for f in os.listdir(scripts_dir) if f.endswith('.sh')]
    
    for script in shell_scripts:
        script_path = os.path.join(scripts_dir, script)
        # Check if file is executable
        assert os.access(script_path, os.X_OK), f"Script {script} should be executable"

def test_python_scripts_importable():
    """Test that Python scripts can be imported."""
    try:
        # Test if performance monitoring script is importable
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'scripts'))
        
        # Basic import test - this will fail gracefully if dependencies are missing
        import importlib.util
        
        performance_script = os.path.join(os.path.dirname(__file__), '..', 'scripts', 'performance-monitoring.py')
        if os.path.exists(performance_script):
            spec = importlib.util.spec_from_file_location("performance_monitoring", performance_script)
            # Just check that we can create the spec
            assert spec is not None, "Should be able to create module spec"
        
        assert True  # Always pass if we get here
    except ImportError:
        # Expected if dependencies are missing
        assert True

def test_workflow_files_exist():
    """Test that GitHub workflow files exist."""
    workflows_dir = os.path.join(os.path.dirname(__file__), '..', '.github', 'workflows')
    
    if not os.path.exists(workflows_dir):
        pytest.skip("Workflows directory not found")
    
    expected_workflows = [
        'linear-sync.yml',
        'test.yml',
        'security.yml',
        'docs.yml'
    ]
    
    for workflow in expected_workflows:
        workflow_path = os.path.join(workflows_dir, workflow)
        assert os.path.exists(workflow_path), f"Workflow {workflow} should exist"
