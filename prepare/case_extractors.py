import abc
import logging
import os
import csv

import re

module_logger = logging.getLogger('pyccflex.prepare.case_extractors')


class BaseCaseExtractor(abc.ABC):
    """
    Base class for extracting cases / objects from code files. Intended for subclassing.
    """

    def __init__(self, code_location, output_file_path, decision_classes, sep=","):
        self.logger = logging.getLogger('pyccflex.common.configuration.BaseCaseExtractor')
        self.code_location = code_location
        self.locations = code_location.get("locations", [])
        self.output_file_path = output_file_path
        self.sep = sep
        self.decision_classes = decision_classes
        self.baseline_dir = code_location.get("baseline_dir", "/")

    def extract(self):
        with open(self.output_file_path, "w", newline='') as output_file:
            writer = csv.writer(output_file, delimiter=self.sep, quotechar='"', quoting=csv.QUOTE_MINIMAL)

            self._save_header(writer)
            self._extract_files(writer, self.locations)

    def _matches_any(self, filename, include):
        for pattern in include:
            if pattern.match(filename):
                return True
        return False

    def re_compiled(self, reg_exps):
        return [re.compile(x) for x in reg_exps]

    def _extract_files(self, writer, locations):
        for location in locations:
            path = location.get("path", None)
            include = self.re_compiled(location.get("include", []))
            exclude = self.re_compiled(location.get("exclude", []))
            if os.path.isfile(path):
                self.extract_cases_from_file(path, writer)
            else:
                files = [f for f in os.listdir(path) if os.path.isfile(os.path.join(os.path.normpath(path), f))]
                dirs = [f for f in os.listdir(path) if os.path.isdir(os.path.join(os.path.normpath(path), f))]

                for f in files:
                    file_path = os.path.join(os.path.normpath(path), f)
                    if self._matches_any(f, include) and not self._matches_any(f, exclude):
                        self.extract_cases_from_file(file_path, writer)
                    else:
                        self.logger.info("Skipping file {}".format(file_path))

                children_loc = [{"path": os.path.join(os.path.normpath(path), d),
                                 "include": include, "exclude": exclude} for d in dirs]
                self._extract_files(writer, children_loc)

    def _save_header(self, writer):
        header_row = self.header()
        print(header_row)
        writer.writerow(header_row)

    @abc.abstractmethod
    def header(self):
        """Returns header as a list."""
        return []

    @abc.abstractmethod
    def extract_cases_from_file(self, file_path, output_file):
        """Extracts and saves cases to the file."""


class LinesCaseExtractor(BaseCaseExtractor):
    """Extracts lines and stores them in a csv file."""

    def header(self):
        return ["id", "line", "contents", "class_name", "class_value", "path"]

    def extract_cases_from_file(self, file_path, writer):
        self.logger.info("Extracting file {}".format(file_path))

        file_relative_path = os.path.relpath(file_path, self.baseline_dir)

        with open(file_path, "r") as input_file:

            for number, line in enumerate(input_file, 1):
                decision_class_name = None
                decision_class_value = None
                for c in self.decision_classes.get("labeled", []):
                    if line.startswith(c['line_prefix']):
                        decision_class_name = c['name']
                        decision_class_value = c['value']
                        line = line[len(c['line_prefix']):]
                        break
                if decision_class_name is None:
                    default_class = self.decision_classes.get('default')
                    decision_class_name = default_class['name']
                    decision_class_value = default_class['value']

                row = ["{}:{}".format(file_relative_path, number),
                                     str(number),
                                     line.replace("\"", "\"\"").replace("\n", ""),
                                     decision_class_name,
                                     str(decision_class_value),
                                     file_path]
                writer.writerow(row)
