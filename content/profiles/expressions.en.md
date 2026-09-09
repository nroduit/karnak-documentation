---
title: Expressions
weight: 40
description: Definition of the expressions applied to specific tags
---

## Actions on specific tags

This profile element applies an expression to a tag or a group of tags defined by the user. An expression is based on [Spring Expression Language (SpEL)](https://docs.spring.io/spring-framework/reference/core/expressions.html) and returns a value or an action according to a certain condition.


### Parameters

This profile element requires the following parameters:

| Parameter | Required | Description |
|-----------|----------|-------------|
| **name** | Yes | Description of the action applied |
| **codename** | Yes | Must be `expression.on.tags` |
| **arguments** | Yes | Definition of the expression with the `expr` argument |
| **tags** | Yes | List of tags the action should be applied to |
| **condition** | No | Optional condition to evaluate if this profile element should be applied to this DICOM instance |
| **excludedTags** | No | List of tags that will be ignored by this action |

### Expression Context

The expression is contained in the `expr` argument. When executed, it can either:

- Return an action to be executed
- Return a null value (does nothing and moves to the next profile element)

#### Available Variables

The following variables are available in the expression context, containing information about the current attribute:

| Variable | Description | Example |
|----------|-------------|---------|
| `tag` | Current attribute tag | `(0010,0010)` |
| `vr` | Current attribute VR | `PN` |
| `stringValue` | Current element value | `'John^Doe'` |

#### Constants

Constants improve readability and reduce errors:

| Constant | Description | Example |
|----------|-------------|---------|
| `#Tag` | Retrieve any tag integer value from the DICOM standard | `#Tag.PatientBirthDate` returns (0010,0030) |
| `#VR` | Retrieve any VR value from the DICOM standard | `#VR.LO` returns the Long String type |

#### Utility Functions

The following utility functions help work with tags:

| Function | Description | Return Value |
|----------|-------------|--------------|
| `getString(int tag)` | Returns the value of the given tag, looked up from the dataset being visited outwards (from an attribute nested in a sequence, the tags of the enclosing datasets are visible) | String value or null if tag is not present |
| `tagIsPresent(int tag)` | Checks if the tag exists anywhere in the DICOM instance, at any nesting level | `true` if present, `false` otherwise |

The values read by the expression (`stringValue`, `getString`) are the **original** values of the instance, before any profile element modified it.

### Available Actions

Actions are defined as functions and set the operation to perform on the current tag:

| Action | Description |
|--------|-------------|
| `ReplaceNull()` | Sets the current tag value to empty |
| `Replace(String dummyValue)` | Replaces the current tag value with the specified value |
| `Remove()` | Removes the tag from the DICOM instance |
| `Keep()` | Keeps the tag unchanged |
| `UID()` | Replaces the current tag value with a newly generated UID and sets the tag's VR to UI |
| `ComputePatientAge()` | Replaces the current tag value with a computed patient's age at the time of the exam |
| `ExcludeInstance()` | Interrupts the transfer of this instance (appears as *Rejected* in monitoring) |

## Examples

### Conditional replacement based on tag value and type

Replace the Patient Name with the Institution Name if the current value is 'John', otherwise keep it unchanged:

```yaml
  - name: "Expression"
    codename: "expression.on.tags"
    arguments:
      expr: "stringValue == 'John' and tag == #Tag.PatientName? Replace(getString(#Tag.InstitutionName)) : Keep()"
    tags: 
      - "(xxxx,xxxx)"
```

> [!INFO]
> This example applies to all attributes in the DICOM instance. For each tag, it either applies Keep or Replace, which prevents further profile elements from modifying those tags.

### Remove tags with undefined values

Remove tags with 'UNDEFINED' value, otherwise keep them:

```yaml
  - name: "Expression"
    codename: "expression.on.tags"
    arguments:
      expr: "stringValue == 'UNDEFINED'? Keep() : Remove()"
    tags: 
      - "(0010,0010)" #PatientName
      - "(0010,0212)" #StrainDescription
```

### Concatenate multiple tag values

Replace Study Description with a concatenation of Institution Name and Station Name:

```yaml
- name: "Expression"
  codename: "expression.on.tags"
  arguments:
    expr: "Replace(getString(#Tag.InstitutionName) + '-' + getString(#Tag.StationName))"
  tags: 
    - "(0008,1030)" #StudyDescription
```

### Compute patient age

Calculate and set the patient's age at the time of the exam:

```yaml
- name: "Expression"
  codename: "expression.on.tags"
  arguments:
    expr: "ComputePatientAge()"
  tags: 
    - "(0010,1010)" #PatientAge
```

### Exclude instances conditionally

Exclude all instances that contain a name in the image (where Specimen Label In Image is set to YES):

```yaml
  - name: "Expression"
    codename: "expression.on.tags"
    arguments:
      expr: "getString(#Tag.SpecimenLabelInImage) == 'YES' ? ExcludeInstance() : null"
    tags: 
      - "(xxxx,xxxx)"
```