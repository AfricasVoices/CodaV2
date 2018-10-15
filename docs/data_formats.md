
# Data format definitions for Coda and associated tools

## Code Schemes

Code schemes are used to represent possible values, they are defined in JSON, and loaded into Firebase using a support tool

Code Scheme definition (JSON, named $Name-$Version)

```
{
  "SchemeID"            : String,     // Required, Globally unique format "Scheme-sUUID"
  "Name"                : String,     // Required, Friendly name
  "Version"             : String,     // Required, Semantic version code
  "Codes"               : [           // Required
    {
      "CodeID"          : String,     // Required, Unique in code scheme format "Scheme-???-sUUID"
      "DisplayText"     : String,     // Required, Coda will display this
      "Shortcut"        : String,     // Optional, Single character for shortcut
      "NumericValue"    : Int,        // Required, Unique in code scheme
      "VisibleInCoda"   : Bool,       // Required, Coda will display if true
      "Color"           : String      // Optional
    }
  ],
  "Documentation" : {                 // Optional
     "URI" :  String
  }
}
```

## Messages

Messages are used to represent a message to be coded. They are defined in JSON and loaded into Firebase using a support tool

Message definition (JSON, named $ID)
```
{
  "MessageID"           : String,     // Required, Globally unique
  "Text"                : String,     // Required
  "CreationDateTimeUTC" : DateTime,   // Required
  "Labels"              : [           // Required
    {
      "SchemeID"        : String,     // Required
      "CodeID"          : String,     // Required
      "DateTimeUTC"     : DateTime,   // Required
      "Checked"         : Bool,       // Optional
      "Confidence"      : Double,     // Optional
      "Origin"          : {           // Required
        "OriginID"      : String,     // Required
        "Name"          : String,     // Required
        "OriginType"    : String,     // Required
        "Metadata"      : {           // Optional
          "key": "value"
        }
      }
    }
  ]
}
```
