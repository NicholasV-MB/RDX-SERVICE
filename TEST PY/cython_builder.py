from distutils.core import setup
from distutils.extension import Extension

from Cython.Distutils import build_ext

import shutil, sys

# sys.argv.append("build_ext")
# sys.argv.append("--inplace")

src_dir="Hello.py"
dst_dir="Hello.pyx"
shutil.copy(src_dir,dst_dir)

'''setup(
    cmdclass = {'build_ext': build_ext},
    ext_modules = [Extension("helloworld",["Hello.pyx"])] 
    )'''

