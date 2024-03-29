import logging
import csv
import re
import sys

from prepare.vocabularies import code_stop_words_tokenizer, token_signature

module_logger = logging.getLogger('pyccflex.prepare')

max_int = sys.maxsize
while True:
    # decrease the max_int value by factor 10 
    # as long as the OverflowError occurs.
    try:
        csv.field_size_limit(max_int)
        break
    except OverflowError:
        max_int = int(max_int/10)
module_logger.debug(f"Setting csv field size to {max_int}")

class LineFeaturesExtractionController(object):
    """
    Reads a csv file with lines and manages features extraction for each line.
    """

    def __init__(self, extractors, input_file, output_path, sep=",", max_line_length=1000,
                 add_decision_class=False, add_contents=False, verbosity=100000):
        self.logger = logging.getLogger('pyccflex.common.configuration.LineFeaturesExtractionController')
        self.extractors = extractors
        self.input_file = input_file
        self.output_file = output_path
        self.sep = sep
        self.feature_names = ["id"]
        self.add_decision_class = add_decision_class
        self.add_contents = add_contents
        self.max_line_length = max_line_length
        for extractor in extractors:
            self.feature_names.extend(extractor.feature_names)
        if add_decision_class:
            self.feature_names.append("class_name")
            self.feature_names.append("class_value")
        if add_contents:
            self.feature_names.append("contents")
        self.verbosity = verbosity

    def extract(self):
        with open(self.input_file, 'rt', encoding="utf-8", errors="ignore") as in_file:
            reader = csv.DictReader(in_file, delimiter=self.sep, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
            with open(self.output_file, 'w', newline='', encoding="utf-8") as out_file:
                writer = csv.DictWriter(out_file, fieldnames=self.feature_names,
                                        delimiter=self.sep, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
                writer.writeheader()
                for i, row in enumerate(reader, start=1):
                    if self.verbosity == 0 or i % self.verbosity == 0:
                        self.logger.info("Extracting features from {}".format(row['id']))
                    features = {"id": row['id']}
                    row['contents'] = row['contents'] if len(row['contents']) < self.max_line_length else row['contents'][:self.max_line_length]
                    if self.add_contents:
                        features["contents"] = row['contents']
                    for extractor in self.extractors:
                        #try:
                        #    extracted_features = func_timeout(60, extractor.extract, args=(row['contents']))
                        #except FunctionTimedOut:
                        #    self.logger.debug( f"Extracting features from for and {row['contents']} exceeded 60s.")
                        #    extracted_features = extractor.extract("")
                        #except Exception as e:
                            # Handle any exceptions that doit might raise here
                        #    pass
                        extracted_features = extractor.extract(row['contents'])
                        features.update(extracted_features)
                    if self.add_decision_class:
                        features["class_name"] = row['class_name']
                        features["class_value"] = row['class_value']
                    writer.writerow(features)



class SubstringCountingFeatureExtraction(object):
    """
    Extracts features by counting number of occurrences of a substring in a string.
    """

    def __init__(self, features_desc):
        self.logger = logging.getLogger('pyccflex.common.configuration.SubstringCountingFeatureExtraction')
        self.feature_desc = features_desc
        self.feature_names = [f['name'] for f in features_desc]

    def extract(self, text):
        features = {}
        for feature in self.feature_desc:
            features[feature['name']] = 0
            for feature_string in feature['string']:
                features[feature['name']] += text.count(feature_string)
        return features


class WholeWordCountingFeatureExtraction(object):
    """
    Extracts features by counting number of occurrences of a word not directly surrounded by other words.
    """

    def __init__(self, features_desc, max_line_length=150):
        self.logger = logging.getLogger('pyccflex.common.configuration.WholeWordCountingFeatureExtraction')
        self.feature_desc = features_desc
        self.max_line_length = max_line_length
        for feature in features_desc:
            feature['re'] = []
            for feature_string in feature['string']:
                feature['re'].append(re.compile("(?<!\\w)" + feature_string + "(?!\\w)"))

        self.feature_names = [f['name'] for f in features_desc]

    def extract(self, text):
        features = {}
        text = text if len(text) < self.max_line_length else text[:self.max_line_length]
        for feature in self.feature_desc:
            features[feature['name']] = 0
            for feature_re in feature['re']:
                #print(f"{feature['re']} -> {text}")
                features[feature['name']] += len(feature_re.findall(text))
        return features

class TokenizedWholeWordCountingFeatureExtraction(object):
    """
    Extracts features by counting number of occurrences of a word not directly surrounded by other words.
    """

    def __init__(self, features_desc, max_line_length=300):
        self.logger = logging.getLogger('pyccflex.common.configuration.WholeWordCountingFeatureExtraction')
        self.feature_desc = features_desc
        self.max_line_length = max_line_length
        for feature in features_desc:
            feature['re'] = []
            for feature_string in feature['string']:
                feature['re'].append(re.compile("^"+feature_string+"$"))

        self.feature_names = [f['name'] for f in features_desc]

    def extract(self, text):
        features = {}
        text = text if len(text) < self.max_line_length else text[:self.max_line_length]
        tokens = code_stop_words_tokenizer(text)
        for feature in self.feature_desc:
            features[feature['name']] = 0
            for token in tokens:
                token = token if len(token) < 50 else token[:50]
                for feature_re in feature['re']:
                    features[feature['name']] += 1 if feature_re.match(token) is not None else 0
        return features

class RegexpCountingFeatureExtraction(object):
    """
    Extracts features by counting number of occurrences of regexp in the line.
    """

    def __init__(self, features_desc, max_line_length=150):
        self.logger = logging.getLogger('pyccflex.common.configuration.RegexpCountingFeatureExtraction')
        self.feature_desc = features_desc
        self.max_line_length = max_line_length
        for feature in features_desc:
            feature['re'] = []
            for feature_string in feature['string']:
                feature['re'].append(re.compile(feature_string))

        self.feature_names = [f['name'] for f in features_desc]

    def extract(self, text):
        features = {}
        text = text if len(text) < self.max_line_length else text[:self.max_line_length]
        for feature in self.feature_desc:
            features[feature['name']] = 0
            for feature_re in feature['re']:
                features[feature['name']] += len(feature_re.findall(text))
        return features

class CommentFeatureExtraction(object):
    """
       Extracts number of comments in the text
       """

    def __init__(self):
        self.logger = logging.getLogger('pyccflex.common.configuration.CommentFeatureExtraction')
        self.feature_names = ['comment']

    def extract(self, text):
        feature = text.count("//") + text.count("/*") + text.count("*/")
        return {'comment': feature}

class WholeLineCommentFeatureExtraction(object):
    """
       Extracts number of comments in the text
       """

    def __init__(self):
        self.logger = logging.getLogger('pyccflex.common.configuration.CommentFeatureExtraction')
        self.feature_names = ['whole_line_comment']

    def extract(self, text):
        pattern = re.compile("^(\\s)*//.*$")
        feature = 0 if pattern.search(text) is None else 1
        return {'whole_line_comment': feature}

class PythonWholeLineCommentFeatureExtraction(object):
    """
       Extracts number of comments in the text
       """

    def __init__(self):
        self.logger = logging.getLogger('pyccflex.common.configuration.PythonCommentFeatureExtraction')
        self.feature_names = ['whole_line_comment']

    def extract(self, text):
        pattern = re.compile("^(\\s)*#.*$")
        feature = 0 if pattern.search(text) is None else 1
        return {'whole_line_comment': feature}

		
class BlankLineFeatureExtraction(object):
    """
       Returns 1 if a line is blank (contains white characters only or is empty).
       """

    def __init__(self):
        self.logger = logging.getLogger('pyccflex.common.configuration.BlankLineFeatureExtraction')
        self.feature_names = ['blank_line']

    def extract(self, text):
        pattern = re.compile("^(\\s)*$")
        feature = 0 if pattern.search(text) is None else 1
        return {'blank_line': feature}

class WordCountFeatureExtraction(object):
    """
       Extracts number of words in the text
       """

    def __init__(self):
        self.logger = logging.getLogger('pyccflex.common.configuration.WordCountFeatureExtraction')
        self.feature_names = ['no_words']

    def extract(self, text):
        return {'no_words': len(text.split())}


class CharCountFeatureExtraction(object):
    """
       Extracts number of characters in the text
       """

    def __init__(self):
        self.logger = logging.getLogger('pyccflex.common.configuration.CharCountFeatureExtraction')
        self.feature_names = ['no_chars']

    def extract(self, text):
        return {'no_chars': len(text)}


class CountVectorizerBasedFeatureExtraction(object):
    """
    Extracts features using the provided CountVectorizer.
    """

    def __init__(self, count_vect, separator, to_replace):
        self.logger = logging.getLogger('pyccflex.common.configuration.CountVectorizerBasedFeatureExtraction')
        self.count_vect = count_vect
        self.feature_names = sorted(count_vect.vocabulary_.keys(), key=count_vect.vocabulary_.get)
        #self.feature_names = [x.encode('utf-8') if separator not in x else "\"{}\"".format(x.encode('utf-8')) for x in self.feature_names]
        self.feature_names = [x if separator != x else to_replace for x in self.feature_names]

    def extract(self, text):
        features = self.count_vect.transform([text]).todense().tolist()[0]
        return dict(zip(self.feature_names, features))
