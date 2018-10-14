
# Data format definitions for Coda and associated tools

## Code Schemes

Code schemes are used to represent possible values, they are defined in JSON, and loaded into Firebase using a support tool

Code Scheme definition (JSON, named $Name-$Version)

```
{
  "SchemeID"      :  String,		// Required, Globally Unique Format "Scheme-sUUID"
  "Name"          :  String,		// Required, Friendly name
  "Version"       :  String,		// Required, Semantic version code
  "Codes"        :  [          // Required
    {
      "CodeID"        : String,  // Required, Unique in code scheme format "Scheme-???-sUUID"
      "DisplayText"    : String,	// Required, Coda will display this
      "Shortcut"       : String,  // Optional, single character for shortcut
      "NumericValue"   : Int,		  // Required, Unique in code scheme
      "VisibleInCoda"  : Bool,		// Required, Coda will display iff true
      "Color"         : String   // Optional
    }
  ],
  "Documentation" : {             // Optional
     "URI" :  String 
  }
}
```


