
# Data format definitions for Coda and associated tools

## Code Schemes

Code schemes are used to represent possible values, they are defined in JSON, and loaded into Firebase using a support tool

Code Scheme definition (JSON, named $Name-$Version)

```
{
  "SchemeID"            : String,       // Required, Globally unique format "Scheme-sUUID"
  "Name"                : String,       // Required, Friendly name
  "Version"             : String,       // Required, Semantic version code
  "Codes"               : [             // Required
    {
      "CodeID"          : String,       // Required, Unique in code scheme format "Scheme-???-sUUID"
      "DisplayText"     : String,       // Required, Coda will display this
      "Shortcut"        : String,       // Optional, Single character for shortcut
      "NumericValue"    : Int,          // Required, Unique in code scheme analysis output in numeric form
      "StringValue"     : String,       // Required, Unique in code scheme analysis output in string form
      "VisibleInCoda"   : Bool,         // Required, Coda will display if true
      "Color"           : String,       // Optional
      "MatchValues"     : List<String>  // Optional, List of strings that tools can use to automatically match this code
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
  "MessageID"           : String,           // Required, Globally unique
  "SequenceNumber"      : Int               // Required, Unique, but not necessarily consecutive
  "Text"                : String,           // Required
  "CreationDateTimeUTC" : ISO 8601 String,  // Required
  "Labels"              : [                 // Required
    {
      "SchemeID"        : String,           // Required
      "CodeID"          : String,           // Required
      "DateTimeUTC"     : ISO 8601 String,  // Required
      "Checked"         : Bool,             // Optional
      "Confidence"      : Double,           // Optional ( 0 <= Confidence <= 1 )
      "LabelSet"        : Int,              // Optional, used to group multiple labels together in future UI
      "Origin"          : {                 // Required
        "OriginID"      : String,           // Required
        "Name"          : String,           // Required
        "OriginType"    : String,           // Required
        "Metadata"      : {                 // Optional
          String : String
        }
      }
    }
  ]
}
```
