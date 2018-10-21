import nltk.data

import json
import random
import datetime

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
            "MessageID" : "m-{}".format(i),
            "Text" : str(t),
            "CreationDateTimeUTC" : datetime.datetime.now().isoformat(),
            "Labels" : []
        }
    )

mp = {
    "messages" : msgs
}
print (json.dumps(mp, ensure_ascii=True, indent=2))