import abc
import logging
import os
import csv

import re
import hashlib

module_logger = logging.getLogger('pyccflex.prepare.case_extractors')


class BaseCaseExtractor(abc.ABC):
    """
    Base class for extracting cases / objects from code files. Intended for subclassing.
    """

    def __init__(self, code_location, output_file_path, decision_classes, sep=",",
                 quotechar="\"", remove_duplicates=False, verbosity=100):
        self.logger = logging.getLogger('pyccflex.common.configuration.BaseCaseExtractor')
        self.code_location = code_location
        self.locations = code_location.get("locations", [])
        self.output_file_path = output_file_path
        self.sep = sep
        self.decision_classes = decision_classes
        self.baseline_dir = code_location.get("baseline_dir", "/")
        self.quotechar = quotechar
        self.verbosity = verbosity
        self.remove_duplicates = remove_duplicates

    def extract(self):
        with open(self.output_file_path, "w", newline='', encoding="utf-8") as output_file:
            writer = csv.writer(output_file, delimiter=self.sep, quotechar=self.quotechar, quoting=csv.QUOTE_NONNUMERIC)

            self._save_header(writer)

            files = set()
            self._get_files_in_locations(self.locations, files)
            no_files = len(files)
            for i, file_path in enumerate(files, start=1):
                if self.verbosity == 0:
                    self.logger.info("Extracting file {}".format(file_path))
                else:
                    if i % self.verbosity == 0:
                        self.logger.info("Extracting {} out of {} files: {}".format(i, no_files, file_path))
                self.extract_cases_from_file(file_path, writer)

    def _matches_any(self, filename, include):
        for pattern in include:
            if pattern.match(filename):
                return True
        return False

    def re_compiled(self, reg_exps):
        return [re.compile(x) for x in reg_exps]

    def _get_files_in_locations(self, locations, result):
        for location in locations:
            path = location.get("path", None)
            include = self.re_compiled(location.get("include", []))
            exclude = self.re_compiled(location.get("exclude", []))

            if os.path.isfile(path):
                result.add(path)
            else:
                files = [f for f in os.listdir(path) if os.path.isfile(os.path.join(os.path.normpath(path), f))]
                dirs = [f for f in os.listdir(path) if os.path.isdir(os.path.join(os.path.normpath(path), f))]

                for f in files:
                    file_path = os.path.join(os.path.normpath(path), f)
                    if self._matches_any(f, include) and not self._matches_any(f, exclude):
                        result.add(file_path)

                children_loc = [{"path": os.path.join(os.path.normpath(path), d),
                                 "include": include, "exclude": exclude} for d in dirs]
                self._get_files_in_locations(children_loc, result)

    def _save_header(self, writer):
        header_row = self.header()
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

        file_relative_path = os.path.relpath(file_path, self.baseline_dir)

        completed_lines_hash = set()

        with open(file_path, "r", encoding="utf-8") as input_file:
            number = 0
            while True:
                number += 1
                try:
                    line = input_file.readline()
                    if not line:
                        break

                    if self.remove_duplicates and len(line.strip()) > 0:
                        hashValue = hashlib.md5(line.encode('utf-8')).hexdigest()
                        if hashValue not in completed_lines_hash:
                            completed_lines_hash.add(hashValue)
                        else:
                            self.logger.info("Skipping duplicated line {}: {}".format(number, line))
                            continue

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
                           number,
                           line.replace("\n", "").replace('\0', ''),
                           decision_class_name,
                           decision_class_value,
                           file_path.replace("\n", "")]
                    writer.writerow(row)

                except Exception as e:
                    self.logger.info("Skipping line {} because of wrong encoding".format(number))
