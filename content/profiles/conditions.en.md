---
title: Conditions
weight: 60
description: Definition of the conditions applied to profile elements
---

## Overview

A condition is an expression evaluated against a DICOM instance that returns a boolean value (`true` or `false`). Conditions are used in profiles to determine whether specific actions or transformations should be applied to DICOM elements based on the content of the instance.

## Quick Reference

| Function | Purpose | Example |
|----------|---------|---------|
| `tagValueIsPresent` | Exact match | `tagValueIsPresent(#Tag.Modality, "CT")` |
| `tagValueContains` | Substring match | `tagValueContains(#Tag.StudyDescription, "cardiac")` |
| `tagValueBeginsWith` | Prefix match | `tagValueBeginsWith(#Tag.SeriesNumber, "1")` |
| `tagValueEndsWith` | Suffix match | `tagValueEndsWith(#Tag.StationName, "GE")` |
| `tagIsPresent` | Tag existence | `tagIsPresent(#Tag.PatientName)` |

## Constants

To improve readability and reduce errors, the following constants are available:

- **`#Tag`** - Retrieves DICOM tag identifiers by their standard names
  - Example: `#Tag.PatientBirthDate` → `0010,0030`
  - Example: `#Tag.StudyDescription` → `0008,1030`
  - Example: `#Tag.Modality` → `0008,0060`

- **`#VR`** - Retrieves DICOM Value Representation types
  - Example: `#VR.LO` → Long String
  - Example: `#VR.DA` → Date
  - Example: `#VR.PN` → Person Name

Using these constants is recommended over hardcoded tag values to make profiles more maintainable and self-documenting.

## Available Functions

All utility functions are detailed below with their parameters, return types, and usage examples.

Utility functions are available to define the conditions and are detailed below.

### tagValueIsPresent 

`tagValueIsPresent(int tag, String value)` or `tagValueIsPresent(String tag, String value)`

This function will retrieve the `tag` value of the DICOM and check if the `value` parameter is the same as the tag value.

```java
//Check if the study description is equals to "755523-st222-GE"
tagValueIsPresent(#Tag.StudyDescription, "755523-st222-GE")
tagValueIsPresent("0008,1030", "755523-st222-GE")

//Check if the study description is not equals to "755523-st222-GE"
!tagValueIsPresent(#Tag.StudyDescription, "755523-st222-GE")
!tagValueIsPresent("0008,1030", "755523-st222-GE")
```

### tagValueContains

`tagValueContains(int tag, String value)` or `tagValueContains(String tag, String value)`

This function will retrieve the `tag` value of the DICOM and check if the `value` parameter appears in the tag value.

```java
//Check if the study description contains "st222"
tagValueContains(#Tag.StudyDescription, "st222")
tagValueContains("0008,1030", "st222")

//Check if the study description does not contain "st222"
!tagValueContains(#Tag.StudyDescription, "st222")
!tagValueContains("0008,1030", "st222")
```

### tagValueBeginsWith

`tagValueBeginsWith(int tag, String value)` or `tagValueBeginsWith(String tag, String value)`

This function will retrieve the `tag` value of the DICOM and check if the tag value begins with the parameter `value`

```java
//Check if the study description begins with "755523"
tagValueBeginsWith(#Tag.StudyDescription, "755523")
tagValueBeginsWith("0008,1030", "755523")

//Check if the study description does not begin with "755523"
!tagValueBeginsWith(#Tag.StudyDescription, "755523")
!tagValueBeginsWith("0008,1030", "755523")
```

### tagValueEndsWith

`tagValueEndsWith(int tag, String value)` or `tagValueEndsWith(String tag, String value)`

This function will retrieve the `tag` value of the DICOM and check if the tag value ends with the parameter `value`

```java
//Check if the study description ends with "GE"
tagValueEndsWith(#Tag.StudyDescription, "GE")
tagValueEndsWith("0008,1030", "GE")

//Check if the study description does not end with "GE"
!tagValueEndsWith(#Tag.StudyDescription, "GE")
!tagValueEndsWith("0008,1030", "GE")
```

### tagIsPresent

`tagIsPresent(int tag)` or `tagIsPresent(String tag)`

This function will check if the `tag` is present in the DICOM instance.

```java
//Check if the tag study description is present in the DICOM file
tagIsPresent(#Tag.StudyDescription)
tagIsPresent("0008,1030")

//Check if the tag study description is not present in the DICOM file
!tagIsPresent(#Tag.StudyDescription)
!tagIsPresent("0008,1030")
```

### Tags Inside Sequences

A condition is evaluated for each visited attribute, including the attributes nested in the items of a sequence. The tag given to a function is looked up from the dataset being visited outwards: inside a sequence item, the item's own value is used when the item holds the tag, otherwise the value of the enclosing dataset (up to the top level). A condition on a study-level tag such as `Modality` therefore holds at every level, while a condition on a tag that only exists inside the items of a sequence is true only while those items are visited.

### Combining Conditions

Multiple conditions can be combined using logical operators.

`&&` corresponds to the AND logical operator

`||` corresponds to the OR logical operator

```java
//Check if the tag study description ends with "GE" and if the station name is "CT1234"
tagValueEndsWith(#Tag.StudyDescription, "GE") && tagValueContains(#Tag.StationName, "CT1234")

//Check if the tag study description ends with "GE" or if the station name is "CT1234"
tagValueEndsWith(#Tag.StudyDescription, "GE") || tagValueContains(#Tag.StationName, "CT1234")
```

