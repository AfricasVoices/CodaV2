
# Data format definitions for Coda and associated tools

## Code Schemes

Code schemes are used to represent possible values, they are defined in JSON, and loaded into Firebase using a support tool

Code Scheme definition (JSON, named $Name_$Version)

```
{
  "schemeID"      :  String,		// Required, Format "Scheme-UUID"
  "Name"          :  String,		// Required, Friendly name
  "Version"       :  String,		// Required, Semantic version code
  "Values"        :  [          // Required
    {
      "DisplayText"    : String,	// Required, Coda will display this
      "NumericValue"   : Int,		  // Required, Unique in code scheme
      "VisibleInCoda"  : Bool,		// Required, Coda will display iff true
      "Colour"         : String   // Optional
    }
  ],
  "Documentation" : {             // Optional
     "URI" :  String 
  }
}
```


