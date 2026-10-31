# SPDX-License-Identifier: MPL-2.0
import os,pathlib,sys,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
if os.environ.get('HSL_TEST_LIBRARIES'):sys.path.insert(0,os.environ['HSL_TEST_LIBRARIES'])
sys.path.insert(0,str(ROOT/'tests'))
suite=unittest.defaultTestLoader.discover(str(ROOT/'tests'))
result=unittest.TextTestRunner(verbosity=2).run(suite)
sys.exit(0 if result.wasSuccessful()else 1)
