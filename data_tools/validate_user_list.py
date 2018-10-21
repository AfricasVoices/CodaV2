import json

def verify_JSON_path(users_path):
    f = open(users_path, 'r')
    users = json.loads(f.read())

    for user_id in users:
        assert (user_id.find("@") > 0)
