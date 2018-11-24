# Logging support functions

import time

VERBOSE = True

def log(str):
    if VERBOSE:
        print (time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()) + ": " + str)
