import json
import argparse

# Valdiates a code scheme is of the form: 
# https://github.com/AfricasVoices/CodaV2/blob/master/docs/data_formats.md

    


def verify_JSON_path(scheme_path):
    f = open(scheme_path, 'r')
    scheme = json.loads(f.read())
    return verify_scheme(scheme)

def verify_scheme(scheme):
    assert "SchemeID" in scheme.keys()
    check_string(scheme["SchemeID"])

    assert "Name" in scheme.keys()
    check_string(scheme["Name"])

    # TODO: Improve checking of version syntax
    assert "Version" in scheme.keys()
    check_string(scheme["Version"])

    assert "Codes" in scheme.keys()
    Values = scheme["Codes"]
    assert isinstance(Values, list)

    seen_display_texts = set()
    seen_numeric_codes = set()
    seen_value_ids = set()


    for value in Values:
        assert isinstance(value, dict)

        ValueID = value["CodeID"]
        assert "CodeID" in value.keys()
        check_string(ValueID)
        assert ValueID not in seen_value_ids
        seen_value_ids.add(ValueID)

        DisplayText = value["DisplayText"]
        assert "DisplayText" in value.keys()
        check_string(DisplayText)
        assert DisplayText not in seen_display_texts
        seen_display_texts.add(DisplayText)

        NumericValue = value["NumericValue"]
        assert "NumericValue" in value.keys()
        check_int(NumericValue)
        assert NumericValue not in seen_numeric_codes
        seen_numeric_codes.add(NumericValue)

        assert "VisibleInCoda" in value.keys()
        check_bool(value["VisibleInCoda"])

        if "Color" in value.keys():
            check_string(value["Color"])
        
        if "Shortcut" in value.keys():
            check_string(value["Shortcut"])
            assert len(value["Shortcut"]) == 1
        
    return scheme


def check_string(s):
    assert isinstance(s, str)
    assert s != ""

def check_int(i):
    assert isinstance(i, int)

def check_bool(b):
    assert isinstance(b, bool)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="verify code scheme")
    parser.add_argument("code_scheme_path", help="Path to code scheme", nargs=1)

    args = parser.parse_args()
    CODE_SCHEME_PATH = args.code_scheme_path[0]

    verify_JSON_path(CODE_SCHEME_PATH)
