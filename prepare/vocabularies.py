import pandas as pd
import collections
import re
import string


def token_signature(t):
    trans_upper = str.maketrans(string.ascii_letters+string.digits,
                                'a'*len(string.ascii_uppercase)+'A'*len(string.ascii_uppercase)+'0'*len(string.digits))
    res = t.translate(trans_upper)
    res = re.sub(r'(.)\1{1,}', r'\1', res)
    res = re.sub(r'(Aa)\1{1,}', r'\1', res)
    res = re.sub(r'(Aa0)\1{1,}', r'\1', res)
    res = re.sub(r'(a_)\1{1,}', r'\1', res)
    res = re.sub(r'(A_)\1{1,}', r'\1', res)
    res = re.sub(r'(Aa_)\1{1,}', r'\1', res)
    return res

CODE_STOP_DELIM = "([\s\t\(\)\[\]{}!@#$%^&*\/\+\-=;:\\\\|`'\"~,.<>/?\n])"

def code_stop_words_tokenizer(s):
    split_s = re.split(CODE_STOP_DELIM, s)
    split_s = list(filter(lambda a: a != '', split_s))
    split_s = ["0" if x.isdigit() else x for x in split_s]
    return split_s


class VocabularyExtractor(object):
    def __init__(self, lines_file_path, separator, tokenizer=code_stop_words_tokenizer):
        self.lines_file_path = lines_file_path
        self.vocab = None
        self.separator = separator
        self.tokenizer = tokenizer

    def extract(self):
        lines_data = pd.read_csv(self.lines_file_path, sep=self.separator, encoding="utf-8")
        lines_data.contents = lines_data.contents.fillna("")

        global_counter = collections.Counter()
        file_counters = []
        files = lines_data.path.unique()
        no_files = len(files)

        for file_path in files:
            file_df = lines_data[lines_data['path'] == file_path]
            file_contents = list(file_df.contents)
            tokenized_file_contents = [self.tokenizer(x) for x in file_contents]

            file_counter = collections.Counter()
            _ = list(map(lambda x: file_counter.update(x), tokenized_file_contents))
            file_counters.append(file_counter)
            global_counter.update(file_counter)

        rows = []
        for entry in global_counter.items():
            token, global_count = entry
            row = [token, global_count]
            in_files = 0
            for counter in file_counters:
                in_files += 1 if counter[token] > 0 else 0
            row.append(in_files)
            row.append(in_files / no_files)
            rows.append(row)

        self.vocab = pd.DataFrame(
            rows, columns=["token", "count", "count_files", "perc_files"]).sort_values(by=['count'], ascending=False)
