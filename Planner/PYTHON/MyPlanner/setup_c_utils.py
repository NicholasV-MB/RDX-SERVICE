from setuptools import setup
from Cython.Build import cythonize
import pathlib


setup(
    #package_dir={'MB_Calendar': 'MB_Calendar'},
    ext_modules = cythonize(str(pathlib.Path(__file__).parent.absolute())+"\\utils.pyx")
)
