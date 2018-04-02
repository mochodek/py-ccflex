from setuptools import setup

setup(name='pyccflex',
      version='0.2',
      description='Python Flexible Code Classifier',
      url='https://github.com/mochodek/py-ccflex',
      author='',
      author_email='',
      license='Apache-2.0',
      packages=['common', 'prepare'],
      install_requires=[
          'pandas',
          'numpy',
          'scikit-learn'
      ],
      scripts=[
          'bin/create_workspace',
          'bin/lines2csv',
          'bin/predefined_manual_features',
          'bin/generate_html',
          'bin/classify',
          'bin/merge_results',
          'bin/vocabulary_extractor',
          'bin/bag_of_words'],
      zip_safe=False)
