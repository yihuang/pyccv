#!/usr/bin/env python
from distutils.core import setup
from distutils.extension import Extension

ext_modules = [ Extension("ccv", [
                    "ccv.c",
                    "deps/ccv/lib/ccv_bbf.c",
                    "deps/ccv/lib/ccv_cache.c",
                    "deps/ccv/lib/ccv_io.c",
                    "deps/ccv/lib/ccv_memory.c",
                    "deps/ccv/lib/ccv_resample.c",
                    "deps/ccv/lib/ccv_util.c",
                    "deps/ccv/lib/3rdparty/sha1/sha1.c",
                ],
                include_dirs=["deps/ccv/lib"],
                define_macros=[("HAVE_LIBPNG", 1), ("HAVE_LIBJPEG", 1)],
                libraries=["png", "jpeg"],
                )
              ]

setup(
    name = 'ccv',
    version = '1.0.2',
    packages=['ccv'],
    ext_modules = ext_modules,
    author='huangyi',
    author_email='yi.codeplayer@gmail.com',
    url = 'https://github.com/yihuang/pyccv',
    description = 'python binding of ccv library, written with cython.',
    long_description='',
)