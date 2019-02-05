import nltk.data

import json
import random
from datetime import datetime
import pytz
import hashlib

class SHAUtils(object):
    @staticmethod
    def sha_string(string):
        """
        Hashes the provided string using the SHA-256 algorithm.
        :param string: String to hash.
        :type string: string
        :return: SHA-256 hashed string.
        :rtype: string
        """
        return hashlib.sha256(string.encode("utf-8")).hexdigest()

    @classmethod
    def stringify_dict(cls, d):
        """
        Converts a dict to a JSON string.
        Dictionaries with the same (key, value) pairs are guaranteed to serialize to the same string,
        irrespective of the order in which the keys were added.
        :param d: Dictionary to convert to JSON.
        :type d: dict
        :return: JSON serialization of the given dict.
        :rtype: string
        """
        return json.dumps(d, sort_keys=True)

    @classmethod
    def sha_dict(cls, d):
        """
        Hashes the provided dict using the SHA-256 algorithm.
        :param d: Dictionary to hash.
        :type d: dict
        :return: SHA-256 hashed dict.
        :rtype: string
        """
        return cls.sha_string(cls.stringify_dict(d))


tokenizer = nltk.data.load('tokenizers/punkt/english.pickle')
fp = open("original_texts/AliceInWonderland.txt")
alice_in_wonderland_tokens = tokenizer.tokenize(fp.read())
alice_in_wonderland_tokens = alice_in_wonderland_tokens[:1000]

fp = open("original_texts/PrideAndPrejudice.txt")
pride_and_prejudice_tokens = tokenizer.tokenize(fp.read())
pride_and_prejudice_tokens = pride_and_prejudice_tokens[:1000]

all_tokens = []
all_tokens.extend(alice_in_wonderland_tokens)
all_tokens.extend(pride_and_prejudice_tokens)



filtered_tokens = []
for token in all_tokens:
    if token.lower().find("chapter") > 0:
        continue
    if token.lower().find("gutenberg") > 0:
        continue

    if token.find('\n\n') > 0:
        for tt in token.split('\n\n'):
            filtered_tokens.append(tt)
        continue
    
    filtered_tokens.append(token)

random.shuffle(filtered_tokens)

msgs = []
i = 0
for t in filtered_tokens:
    i = i + 1
    t = t.replace("\n", " ")
    msgs.append(
        {
            "MessageID" : "{}".format(SHAUtils.sha_string(str(t))),
            "Text" : str(t),
            "CreationDateTimeUTC" : pytz.utc.localize(datetime.utcnow()).isoformat(timespec="microseconds"),
            "Labels" : [],
            "SequenceNumber" : i
        }
    )

print (json.dumps(msgs, ensure_ascii=True, indent=2))




