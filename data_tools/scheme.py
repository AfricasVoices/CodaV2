import validators

class Scheme(object):
    scheme_id = None
    name = None
    version = None
    codes = []
    documentation = dict()

    def __eq__(self, other):
        if not isinstance(other, self.__class__):
            return False
        return other.scheme_id == self.scheme_id & \
            other.name == self.name & \
            other.version == self.version & \
            other.documentation == self.documentation & \
            other.codes == self.codes
    
    def __neq__(self, other):
        return not self.__eq__(other)


    @staticmethod
    def from_firebase_map(data):
        scheme = Scheme()
        scheme.scheme_id = validators.validate_string(data["SchemeID"])
        scheme.name = validators.validate_string(data["Name"])
        scheme.version = validators.validate_string(data["Version"])

        for code_map in data["Codes"]:
            code = Code.from_firebase_map(code_map)
            assert code.code_id not in code_map.keys(), \
                "Non-unique Code Id found in scheme: {}".format(code.code_id)
            scheme.codes.append(code)

        if "Documentation" in data.keys():
            doc_map = data["Documentation"]
            scheme.documentation["URI"] = validators.validate_string(doc_map["URI"])
        
        return scheme
    
    def to_firebase_map(self):
        ret = {}
        ret["SchemeID"] = self.scheme_id
        ret["Name"] = self.name
        ret["Version"] = self.version
        ret["Codes"] = []
        for code in self.codes:
            ret["Codes"].append(code.to_firebase_map())

        if len(documentation.items) > 0:
            ret["Documentation"] = documentation
        
        return ret
        

class Code:
    code_id = None
    display_text = None
    shortcut = None
    numeric_value = -42
    visible_in_coda = True
    color = None

    @staticmethod
    def from_firebase_map(data):
        code = Code()
        code.code_id = validators.validate_string(data["CodeID"], "CodeID")
        code.display_text = validators.validate_string(data["DisplayText"], "DisplayText")
        if "Shortcut" in data.keys():
            code.shortcut = validators.validate_string(data["Shortcut"], "Shortcut")
        code.numeric_value = validators.validate_int(data["NumericValue"], "NumericValue")
        code.visible_in_coda = validators.validate_bool(data["VisibleInCoda"], "VisibleInCoda")
        if "Color" in data.keys():
            code.color = validators.validate_string(data["Color"], "Color")
        return code
    
    def to_firebase_map(self):
        ret = dict()
        ret["CodeID"] = validators.validate_string(self.code_id, "CodeID")
        ret["DisplayText"] = validators.validate_string(self.display_text, "DisplayText")
        ret["Shortcut"] = validators.validate_string(self.shortcut, "Shortcut")
        ret["NumericValue"] = validators.validate_int(self.numeric_value, "NumericValue")
        ret["VisibleInCoda"] = validators.validate_bool(self.visible_in_coda, "VisibleInCoda")
        if self.color != None:
            ret["Color"] = validators.validate_string(self.color, "Color")
        return ret

    def __eq__(self, other):
        if not isinstance(other, self.__class__):
            return False
        return other.code_id == self.code_id & \
            other.display_text == self.display_text & \
            other.shortcut == self.shortcut & \
            other.numeric_value == self.numeric_value & \
            other.visible_in_coda == self.visible_in_coda & \
            other.color == self.color
    
    def __neq__(self, other):
        return not self.__eq__(other)
