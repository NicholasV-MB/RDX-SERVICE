from cx_Freeze import setup, Executable
import requests
import sys

# sys.argv.append('build')
sys.argv.append('bdist_msi')
executable = Executable( script = "Planner.py", base="Win32GUI")

required_modules = ["json", "sys", "datetime", "requests", "os",  "itertools", "operator"]

# Add certificate to the build
options = {
    "build_exe": { 
        'include_files' : [(requests.certs.where(), 'cacert.pem'), "coordinates.json", "routes.json"],
        "includes": required_modules,
        "include_msvcr": True
    }
}



setup(
    name="Planner",
    version = "0",
    requires = required_modules,
    options = options,
    executables = [executable]
)