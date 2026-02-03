import os
import tomllib
import re
from setuptools import setup
from pathlib import Path
from typing import Dict


def load_env_file(env_path: Path) -> Dict[str, str]:
    """
    Load environment variables from a file with support for `${VAR}` substitution.

    Reads the file line by line, ignoring comments and empty lines. Each line
    must be of the form `KEY=VALUE`. References like `${OTHER_VAR}` are
    substituted using variables already read or the current OS environment.

    Args:
        env_path (Path): Full path to the `.env` file, including the filename.

    Returns:
        Dict[str, str]: Mapping of environment variable names to their values.
    """
    env_vars = {}
    var_pattern = re.compile(r"\$\{(\w+)\}")  # pattern for ${VAR} substitution
    with open(env_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            # substitute ${VAR} with current env value if available
            value = var_pattern.sub(lambda m: env_vars.get(m.group(1), os.environ.get(m.group(1), "")), value)
            env_vars[key] = value
    return env_vars


# Read the project data from pyproject.toml
with open("pyproject.toml", "rb") as f:
    pyproject_data = tomllib.load(f)

# Read OpenFactory version from .ofaenv
env_file = Path(__file__).parent / ".ofaenv"
env_vars = load_env_file(env_file)
openfactory_version = env_vars.get("OPENFACTORY_VERSION")

setup(
    name=pyproject_data["project"]["name"],
    version=pyproject_data["project"]["version"],
    python_requires=pyproject_data["project"]["requires-python"],
    install_requires=[
        f"OpenFactory @ git+https://github.com/openfactoryio/openfactory-core.git@{openfactory_version}"
    ],
    extras_require=pyproject_data.get("project", {}).get("optional-dependencies", {}),
)
