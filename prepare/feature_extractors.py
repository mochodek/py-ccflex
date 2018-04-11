import logging
import csv
import re

module_logger = logging.getLogger('pyccflex.prepare')


class LineFeaturesExtractionController(object):
    """
    Reads a csv file with lines and manages features extraction for each line.
    """

    def __init__(self, extractors, input_file, output_path, sep=",",
                 add_decision_class=False, add_contents=False):
        self.logger = logging.getLogger('pyccflex.common.configuration.LineFeaturesExtractionController')
        self.extractors = extractors
        self.input_file = input_file
        self.output_file = output_path
        self.sep = sep
        self.feature_names = ["id"]
        self.add_decision_class = add_decision_class
        self.add_contents = add_contents
        for extractor in extractors:
            self.feature_names.extend(extractor.feature_names)
        if add_decision_class:
            self.feature_names.append("class_name")
            self.feature_names.append("class_value")
        if add_contents:
            self.feature_names.append("contents")

    def extract(self):
        with open(self.input_file, 'rt', encoding="utf-8") as in_file:
            reader = csv.DictReader(in_file, delimiter=self.sep, quotechar='"', quoting=csv.QUOTE_MINIMAL)
            with open(self.output_file, 'w', newline='', encoding="utf-8") as out_file:
                writer = csv.DictWriter(out_file, fieldnames=self.feature_names,
                                        delimiter=self.sep, quotechar='"', quoting=csv.QUOTE_MINIMAL)
                writer.writeheader()
                for i, row in enumerate(reader):
                    if i % 10000 == 0:
                        self.logger.info("Extracting features from {}".format(row['id']))
                    features = {"id": row['id']}
                    if self.add_contents:
                        features["contents"] = row['contents']
                    for extractor in self.extractors:
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

    def __init__(self, features_desc):
        self.logger = logging.getLogger('pyccflex.common.configuration.WholeWordCountingFeatureExtraction')
        self.feature_desc = features_desc
        for feature in features_desc:
            feature['re'] = []
            for feature_string in feature['string']:
                feature['re'].append(re.compile("(?<!\\w)" + feature_string + "(?!\\w)"))

        self.feature_names = [f['name'] for f in features_desc]

    def extract(self, text):
        features = {}
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
        feature = text.count("//") + text.count("/*")
        if text.strip().startswith("* "):
            feature += 1
        return {'comment': feature}


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
        self.feature_names = [x if x != separator else to_replace for x in self.feature_names]

    def extract(self, text):
        features = self.count_vect.transform([text]).todense().tolist()[0]
        return dict(zip(self.feature_names, features))
