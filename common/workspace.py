import logging
import os, shutil

module_logger = logging.getLogger('pyccflex.common.workspace')


class WorkspaceHandler(object):
    """
    Handles storage and reading from temporary folder
    """

    def __init__(self, tmp_dir_path, output_dir_name="results",
                 processing_dir_name="processing",
                 reporting_dir_name="reports"):
        self.logger = logging.getLogger('pyccflex.common.configuration.TempStorageHandler')
        self.path = tmp_dir_path
        self.output_dir_name = output_dir_name
        self.results_path = self.get_file_path(self.output_dir_name)
        self.processing_dir_name = processing_dir_name
        self.processing_path = self.get_file_path(self.processing_dir_name)
        self.reports_dir_name = reporting_dir_name
        self.reports_path = self.get_file_path(self.reports_dir_name)

    def create_workspace_dir(self):
        os.makedirs(self.path)
        self.logger.info("Creating storage folder {}".format(self.path))
        os.makedirs(self.results_path)
        self.logger.info("Creating results folder {}".format(self.results_path))
        os.makedirs(self.processing_path)
        self.logger.info("Creating results folder {}".format(self.processing_path))
        os.makedirs(self.reports_path)
        self.logger.info("Creating results folder {}".format(self.reports_path))

    def remove_workspace_dir(self):
        shutil.rmtree(self.path)
        self.logger.info("Removing storage folder {}".format(self.path))

    def get_file_path(self, filename):
        return os.path.join(os.path.normpath(self.path), filename)

    def get_results_file_path(self, filename):
        return os.path.join(os.path.normpath(self.results_path), filename)

    def get_processing_file_path(self, filename):
        return os.path.join(os.path.normpath(self.processing_path), filename)

    def get_reports_file_path(self, filename):
        return os.path.join(os.path.normpath(self.reports_path), filename)



