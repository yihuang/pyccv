#!/usr/bin/env python
from distutils.core import setup
from distutils.extension import Extension

try:
    from Cython.Distutils import build_ext
    have_cython = True
except ImportError:
    have_cython = False

c_files = [
    "deps/ccv/lib/ccv_bbf.c",
    "deps/ccv/lib/ccv_cache.c",
    "deps/ccv/lib/ccv_io.c",
    "deps/ccv/lib/ccv_memory.c",
    "deps/ccv/lib/ccv_resample.c",
    "deps/ccv/lib/ccv_util.c",
    "deps/ccv/lib/3rdparty/sha1/sha1.c",
]

if have_cython:
    ccv_files = ["ccv.pyx"]
    cmdclass = {'build_ext': build_ext}
    extra_args = {
        'define_macros': [("HAVE_LIBPNG", 1), ("HAVE_LIBJPEG", 1)],
        'libraries': ["png", "jpeg"],
    }
else:
    ccv_files = ["ccv.c"]
    cmdclass = {}
    extra_args = {}

ext_modules = [ Extension(
                    "ccv",
                    ccv_files + c_files,
                    include_dirs=["deps/ccv/lib"],
                    extra_compile_args=['-ffast-math', '-fPIC'],
                    **extra_args
                )
              ]

setup(
    name = 'ccv',
    version = '1.0.0',
    packages=['ccv'],
    ext_modules = ext_modules,
    author='huangyi',
    author_email='yi.codeplayer@gmail.com',
    url = 'https://github.com/yihuang/pyccv',
    description = 'python binding of ccv library, written with cython.',
    cmdclass=cmdclass,
    long_description='',
)
