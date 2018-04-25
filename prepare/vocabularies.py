import pandas as pd
import collections
import re
import string


def token_signature(t):
    trans_upper = str.maketrans(string.ascii_letters+string.digits,
                                'a'*len(string.ascii_uppercase)+'A'*len(string.ascii_uppercase)+'0'*len(string.digits))
    res = t.translate(trans_upper)
    res = re.sub(r'(.)\1{1,}', r'\1', res)
    a = "a" in res
    A = "A" in res
    zero = "0" in res
    underscore = "_" in res

    if a and A:
        if zero:
            res = re.sub(r'(Aa0)\1{1,}', r'\1', res)
        if underscore:
            res = re.sub(r'(Aa_)\1{1,}', r'\1', res)
        res = re.sub(r'(Aa)\1{1,}', r'\1', res)

    if a:
        if zero:
            res = re.sub(r'(a0)\1{1,}', r'\1', res)
            res = re.sub(r'(0a)\1{1,}', r'\1', res)
        if underscore:
            res = re.sub(r'(a_)\1{1,}', r'\1', res)
            res = re.sub(r'(_a)\1{1,}', r'\1', res)
            if zero:
                res = re.sub(r'(0a_)\1{1,}', r'\1', res)
                res = re.sub(r'(_a0)\1{1,}', r'\1', res)
                res = re.sub(r'(_0a)\1{1,}', r'\1', res)
                res = re.sub(r'(_a0a)\1{1,}', r'\1', res)

    if A:
        if zero:
            res = re.sub(r'(0A)\1{1,}', r'\1', res)
            res = re.sub(r'(A0)\1{1,}', r'\1', res)
        if underscore:
            res = re.sub(r'(A_)\1{1,}', r'\1', res)
            res = re.sub(r'(_A)\1{1,}', r'\1', res)
            if zero:
                res = re.sub(r'(_A0)\1{1,}', r'\1', res)
                res = re.sub(r'(_0A)\1{1,}', r'\1', res)

    if zero:
        res = re.sub(r'(0_)\1{1,}', r'\1', res)


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
            list(map(lambda x: file_counter.update(x), tokenized_file_contents))
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
