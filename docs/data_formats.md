
# Data format definitions for Coda and associated tools

## Code Schemes

Code schemes are used to represent possible values, they are defined in JSON, and loaded into Firebase using a support tool

Code Scheme definition (JSON):

```
{
  "schemeID"  :  String,
  "Name"      :  String,
  "Version"   :  String,
  "Values"    :  [
  {
    "DisplayText"    : String,
    "NumericValue"   : Int,
    "VisibleInCoda"  : Bool,
    "Colour"         : String
		}
	]
}
```
