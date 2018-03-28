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
          'numpy',
          'graphviz',
          'scikit-learn'
      ],
      scripts=[
          'bin/create-storage',
          'bin/lines2csv',
          'bin/basic-manual-features',
          'bin/classify',
          'bin/generate_html',
          'bin/classify_c50_r',
          'bin/classify_CART'],
      zip_safe=False)
