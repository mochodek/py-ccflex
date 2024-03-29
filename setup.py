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
          'scikit-learn',
          'modAL',
          'ggplot'
      ],
      scripts=[
          'bin/create_workspace',
          'bin/lines2csv',
          'bin/predefined_manual_features',
          'bin/generate_html',
          'bin/classify',
          'bin/merge_results',
          'bin/vocabulary_extractor',
          'bin/bag_of_words',
          'bin/merge_inputs',
          'bin/add_seq_context',
          'bin/select_features',
          'bin/active_learning',
          'bin/copy_builtin_training_file',
          'bin/extract_block_features_from_class',
          'bin/extract_block_features_from_features',
          'bin/remove_columns',
          'bin/find_similar',
          'bin/copy_feature_file',
          'bin/apply_features_selection',
          'bin/delete_processing_file',
          'bin/lines_oracle',
          'bin/evaluate_accuracy',
          'bin/sample_lines'],
      zip_safe=False)
