import json
import logging
import os

module_logger = logging.getLogger('pyccflex.common.configuration')


class ConfigurationHandler(object):
    """
    Reads json configuration file and gives access to settings.
    Many processing components can share the same configuration file and use different nodes.
    """

    def __init__(self, config_file_path):
        self.logger = logging.getLogger('pyccflex.common.configuration.ConfigurationHandler')

        if not os.path.exists(config_file_path) or not os.path.isfile(config_file_path):
            self.logger.error("Configuration file doesn't exist")
            raise Exception("Configuration file doesn't exist")

        with open(config_file_path) as config_file:
            self.config = json.load(config_file)
            self.logger.info("Configuration file loaded from {}".format(config_file_path))

    def get(self, key, default):
        return self.config.get(key, default)