import logging
import os, shutil

module_logger = logging.getLogger('pyccflex.common.storage')


class FileStorageHandler(object):
    """
    Handles storage and reading from temporary folder
    """

    def __init__(self, tmp_dir_path, output_dir_name="results"):
        self.logger = logging.getLogger('pyccflex.common.configuration.TempStorageHandler')
        self.path = tmp_dir_path
        self.output_dir_name = output_dir_name
        self.results_path = self.get_file_path(self.output_dir_name)

    def create_storage_dir(self):
        os.makedirs(self.path)
        self.logger.info("Creating storage folder {}".format(self.path))
        os.makedirs(self.results_path)
        self.logger.info("Creating results folder {}".format(self.results_path))

    def remove_storage_dir(self):
        shutil.rmtree(self.path)
        self.logger.info("Removing storage folder {}".format(self.path))

    def get_file_path(self, filename):
        return os.path.join(os.path.normpath(self.path), filename)

    def get_results_file_path(self, filename):
        return os.path.join(os.path.normpath(self.results_path), filename)



