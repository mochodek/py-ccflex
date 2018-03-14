import argparse
import json
import logging
from pprint import pprint

logger = logging.getLogger('pyccflex')
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
logger.addHandler(ch)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument("--config_file", help="Path to configuration file", type=str, required=False)
    args = vars(parser.parse_args())

    config_file_path = "./configuration.json" if args['config_file'] is None else args['config_file']

    with open(config_file_path) as config_file:
        config = json.load(config_file)
        logger.info("Configuration file loaded from {}".format(config_file_path))





