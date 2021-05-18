from setuptools import setup
from Cython.Build import cythonize

setup(
    #package_dir={'MB_Calendar': 'MB_Calendar'},
    ext_modules = cythonize("Planner/c_utils.pyx")
)
