def validate_string(s, variable_name=""):
    assert isinstance(s, str), "{} not a string".format(variable_name)
    assert s != "", "{} is empty".format(variable_name)
    return s

def validate_int(i, variable_name=""):
    assert isinstance(i, int), "{} not an int".format(variable_name)
    return i

def validate_double(d, variable_name=""):
    assert isinstance(d, float), "{} not a double".format(variable_name)
    return d

def validate_bool(b, variable_name=""):
    assert isinstance(b, bool), "{} not a bool".format(variable_name)
    return b
