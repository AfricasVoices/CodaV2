
# Data format definitions for Coda and associated tools

## Code Schemes

Code schemes are used to represent possible values, they are defined in JSON, and loaded into Firebase using a support tool

Code Scheme definition (JSON):

```
{
  "schemeID"      :  String,		// Format "Scheme-UUID"
  "Name"          :  String,		// Friendly name
  "Version"       :  String,		// Semantic version code
  "Values"        :  [
    {
      "DisplayText"    : String,	// Coda will display this
      "NumericValue"   : Int,		// Unique in code scheme
      "VisibleInCoda"  : Bool,		// Coda will display iff true
      "Colour"         : String
    }
  ],
  "Documentation" : {
     "URI" :  String 
  }
}
```


