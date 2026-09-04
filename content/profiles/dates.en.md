---
title: Actions on dates
weight: 30
description: Definition of the actions applied to dates
---

This profile element applies a specific action to tags containing dates. 
These actions can only be applied to the following [Value Representations](https://dicom.nema.org/medical/dicom/current/output/chtml/part05/sect_6.2.html): Age String (AS), Date (DA), Date Time (DT), and Time (TM).

## Parameters

### Required parameters

* `name`: Description of the action applied
* `codename`: Must be set to `action.on.dates`
* `option`: The action to be applied (see options below)
* `arguments`: Additional parameters depending on the chosen option

### Optional parameters

* `condition`: Defines a condition to evaluate whether this profile element should be applied to the DICOM instance
* `tags`: List of tags the action should be applied to. If not specified, the action applies to all tags with AS, DA, DT, or TM Value Representation
* `excludedTags`: List of tags that will be ignored by this action

## Available Options

The `option` parameter can have one of the following values:

* `shift` - Apply a fixed time shift
* `shift_range` - Apply a random time shift within specified ranges
* `shift_by_tag` - Apply a shift based on values from another DICOM tag
* `shift_from_api` - Apply a shift based on values from an external API
* `date_format` - Remove date precision (day and/or month)

## Shift Option

The **shift** option applies a fixed shift to dates using the following required arguments:

* `seconds`: Integer representing the number of seconds for the shift operation
* `days`: Integer representing the number of days for the shift operation

**Behavior by Value Representation:**

* **Age String (AS)**: Seconds and days are **added** to the existing value
* **Date (DA), Date Time (DT), Time (TM)**: Seconds and days are **subtracted** from the existing value

### Example

This example shifts all tags starting with `0010` that have AS, DA, DT, or TM Value Representation by 30 seconds and 10 days:

```yaml
- name: "Shift Date"
  codename: "action.on.dates"
  arguments:
    seconds: 30
    days: 10
  option: "shift"
  tags:
    - "0010,XXXX"
```

## Shift Range Option

The **shift_range** option applies a random shift to dates within user-defined ranges.

### Arguments

* `max_seconds` (required): Upper bound for the number of seconds to shift
* `max_days` (required): Upper bound for the number of days to shift
* `min_seconds` (optional): Lower bound for the number of seconds to shift (defaults to 0)
* `min_days` (optional): Lower bound for the number of days to shift (defaults to 0)

The random operation is deterministic and reproducible based on the patient and project.

### Example

This example shifts all tags starting with `0008,002` that have AS, DA, DT, or TM Value Representation randomly within a range of 0 to 60 seconds and 50 to 100 days:


```yaml
  - name: "Shift Range Date"
    codename: "action.on.dates"
    arguments:
      max_seconds: 60
      min_days: 50
      max_days: 100
    option: "shift_range"
    tags:
      - "0008,002X"
```
## Date Format Option

The **date_format** option removes date precision by deleting specific date components.

This action can only be applied to Date (DA) and Date Time (DT) Value Representations.

### Arguments

* `remove`: Specifies which date components to remove
  * `day`: Removes the day information, replacing it with `01`
  * `month_day`: Removes both month and day information, replacing them with `01` for each

### Example: Remove Day

This example removes the day from all tags starting with `0008,003` that have DA or DT Value Representation:


```yaml
  - name: "Date format"
    codename: "action.on.dates"
    arguments:
      remove: "day"
    option: "date_format"
    tags:
      - "0008,003X"
```

For example, if the value contained in the tag is `20230512`, the output value will be `20230501`.


## Shift By Tag Option

The **shift_by_tag** option applies a shift based on values contained in other DICOM tags.

### Arguments

At least one of the following arguments must be specified:

* `seconds_tag`: Tag containing the number of seconds for the shift operation
* `days_tag`: Tag containing the number of days for the shift operation

### Example

This example shifts all tags starting with `0010` that have AS, DA, DT, or TM Value Representation by the number of days stored in the private tag `(0015,0011)`:


```yaml
- name: "Shift Date By Tag"
  codename: "action.on.dates"
  arguments:
    days_tag: "(0015,0011)"
  option: "shift_by_tag"
  tags:
    - "0010,XXXX"
```

## Shift From API Option

The **shift_from_api** option applies a shift based on values from an external API call.

### Arguments

* `url` (required): URL of the API to query. Can contain runtime parameters (see [URL and Body Arguments](#url-and-body-arguments)).
* `daysPath` (required): JSON path to the number of days for the shift operation, using [JSON Pointer](https://datatracker.ietf.org/doc/html/rfc6901) syntax. Empty string means the entire response value will be used.
* `secondsPath` (optional): JSON path to the number of seconds for the shift operation, using [JSON Pointer](https://datatracker.ietf.org/doc/html/rfc6901) syntax. Empty string means the entire response value will be used.
* `method` (optional): HTTP method: `GET` or `POST`. Defaults to `GET`.
* `body` (optional): Request body for POST requests in JSON format. Can contain runtime parameters (see [URL and Body Arguments](#url-and-body-arguments)).
* `authConfig` (optional): Identifier of an existing [Authentication Configuration](../../userguide/authconfig) for authenticating the call. No authentication used if not specified.

### Example

This example shifts all tags starting with `0010` that have AS, DA, DT, or TM Value Representation by the number of days contained in the response of the API call:

```yaml
- name: "Shift Date By Tag"
  codename: "action.on.dates"
  option: "shift_from_api"
  arguments:
    daysPath: "/shift/days"
    secondsPath: "/shift/seconds"
    url: "http://example.com/{{getString(#Tag.PatientID)}}/shift"
  tags:
    - "0010,XXXX"
```

## Complete Profile Example

This example demonstrates a complete de-identification profile that applies multiple date actions in sequence:

1. **Shift Range**: Randomly shift tags matching `(0008,003X)` and `(0008,0012)` (except `(0008,0030)` and `(0008,0032)`) by 0 to 60 seconds and 10 to 50 days
2. **Date Format**: Remove month and day from tags `(0008,0023)` and `(0008,0021)`
3. **Fixed Shift**: Shift tags matching `(0010,XXXX)` (except `(0010,0010)`) by 30 seconds and 10 days
4. **Basic Profile**: Apply the Basic DICOM Profile to all remaining tags

```yaml
name: "De-identification profile"
version: "1.0"
minimumKarnakVersion: "0.9.2"
defaultIssuerOfPatientID:
profileElements:
  - name: "Shift Range Date with arguments"
    codename: "action.on.dates"
    arguments:
      max_seconds: 60
      min_days: 10
      max_days: 50
    option: "shift_range"
    tags:
      - "0008,0012"
      - "0008,003X"
    excludedTags:
      - "0008,0030"
      - "0008,0032"
      
  - name: "Date Format"
    codename: "action.on.dates"
    arguments:
      remove: "month_day"
    option: "format_date"
    tags:
      - "0008,0023"
      - "0008,0021"

  - name: "Shift Date with arguments"
    codename: "action.on.dates"
    arguments:
      seconds: 30
      days: 10
    option: "shift"
    tags:
      - "0010,XXXX"
    excludedTags:
      - "0010,1010"

  - name: "DICOM basic profile"
    codename: "basic.dicom.profile"
```


