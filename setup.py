from setuptools import setup

setup(name='pyccflex',
      version='0.1',
      description='Python Flexible Code Classifier',
      url='https://github.com/mochodek/py-ccflex',
      author='',
      author_email='',
      license='Apache-2.0',
      packages=['common', 'prepare'],
      install_requires=[
          'pandas',
          'numpy'
      ],
      scripts=[
            'bin/create-storage',
            'bin/extract-lines2csv',
            'bin/basic-manual-features'],
      zip_safe=False)
