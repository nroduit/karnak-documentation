---
title: Profile Structure
weight: 10
description: Understanding the Profile Structure and YAML format
---

The [Profiles](../../userguide/profiles/) page allows you to manage de-identification profiles for your projects in the Karnak interface. This page explains the structure of these profiles and how to create or modify them using YAML files.

## Overview

A **profile** defines how DICOM attributes should be modified during de-identification or tag morphing. It consists of one or more **profile elements**, each specifying:

- Which DICOM attributes to target
- What action to apply (e.g., remove, replace, keep)
- Optional conditions for applying the action

**Important behavior:**

- Profile elements are **applied sequentially** in the order they appear in the YAML file
- Only the **first applicable** profile element modifies each DICOM attribute
- Once modified, subsequent profile elements won't affect that attribute

> [!INFO]
> Profiles must be YAML files that conform to the YAML specification and follow Karnak's profile structure defined here.

## Profile Metadata

Metadata fields help identify and manage your profiles. While optional, we recommend defining at least `name` and `version` for clarity.

| Field | Description | Required |
|-------|-------------|----------|
| **name** | Profile name displayed in the UI | Optional (recommended) |
| **version** | Profile version number | Optional (recommended) |
| **minimumKarnakVersion** | Minimum Karnak version required | Optional |
| **defaultIssuerOfPatientID** | Legacy field, accepted for compatibility but ignored. The default Issuer of Patient ID is configured on the [destination](../../userguide/gateway/destinations/#issuer-of-patient-id-by-default) | Optional |
| **profileElements** | List of profile elements to apply | Required |

## Profile Element Structure

Each profile element defines a specific de-identification rule.

### Required Fields

| Field | Description |
|-------|-------------|
| **name** | Descriptive name for this profile element |
| **codename** | Type identifier (see available types in this documentation) |

### Optional Fields

| Field | Description | When Required |
|-------|-------------|---------------|
| **condition** | Boolean expression to conditionally apply this element | Optional |
| **action** | Action type to perform (`K`, `X`, `Z`, `U`, `D`; see [Actions on tags](tags.en.md)) | For certain codenames |
| **option** | Single configuration value | For certain codenames |
| **arguments** | Key-value pairs for advanced configuration | For certain codenames |
| **tags** | DICOM attributes this element should target | For certain codenames |
| **excludedTags** | DICOM attributes to skip (can be modified by later elements) | Optional |

### DICOM Tag Formats

Tags can be specified in multiple formats:

| Format | Example | Description |
|--------|---------|-------------|
| Parentheses | `(0010,0010)` | Standard DICOM notation |
| Comma-separated | `0010,0010` | Without parentheses |
| Concatenated | `00100010` | No separators |
| Pattern | `(0010,XXXX)` | All tags in group 0010 |
| Wildcard | `(XXXX,XXXX)` | All DICOM attributes |

A tag written in one of these formats matches the attribute **wherever it appears** in the instance: at the top level and inside the items of any sequence.

### Tag Paths (Sequences)

To restrict a tag to a given location, write a dot-separated **path**: the last segment is the tag itself and the preceding segments are the sequences enclosing it. A leading dot anchors the path to the top-level dataset; without it, the named sequences may themselves be nested anywhere.

| Path | Matches |
|------|---------|
| `.(0040,0009)` | The tag at the top level only |
| `(0040,0275).(0040,0009)` | The tag directly inside an item of (0040,0275), the sequence being at any depth |
| `.(0040,0275).(0040,0009)` | Same, but the sequence must be at the top level |
| `*.(0040,0009)` | The tag exactly one sequence below its enclosing dataset |
| `**.(0040,0009)` | The tag at any depth except the top level |
| `(0040,0275).*` | Any tag directly inside an item of (0040,0275) |

Each segment accepts the `X` wildcard digits (e.g., `(0040,0275).0040XXXX`). When several entries of the same element match a tag, a path takes precedence over a plain tag, and the most specific path wins. Paths are accepted by `tags` and `excludedTags` of the elements working on user-defined tags, and by [Add new tags](tags.en.md#add-new-tags) (literal paths only).

### Conditions

Add optional conditions to control when a profile element applies. The expression is evaluated for each matching tag.

For complete syntax and examples, see the [Conditions](../conditions) page.

## Basic DICOM Profile

The [Basic DICOM Profile](http://dicom.nema.org/medical/dicom/current/output/chtml/part15/chapter_E.html) is the DICOM standard's reference profile for removing Personally Identifying Information (PII) from DICOM files. 
The conditions to apply rules for a specific tag depend on its attribute type (Type 1, Type 2, etc.) based on the Information Object Definition (IOD). Karnak automatically determines the attribute type for each tag during de-identification.

> [!IMPORTANT]
> We strongly recommend including this profile as the foundation for de-identification.

### Why Use It?

- Removes all attributes containing identifiable patient information
- Maintains DICOM conformance
- Industry-standard approach to de-identification

### How to Include

Reference it by codename in your profile:

```yaml
- name: "DICOM basic profile"
  codename: "basic.dicom.profile"
```

### Complete Example

Below is a minimal but complete profile that applies only the Basic DICOM Profile:

```yaml
name: "Dicom Basic Profile"
version: "1.0"
minimumKarnakVersion: "0.9.2"
defaultIssuerOfPatientID:
profileElements:
  - name: "DICOM basic profile"
    codename: "basic.dicom.profile"
```

> [!INFO]
> This profile should be placed at the end of your profile elements to ensure all other rules are applied first. The profile editor automatically moves it to the last position, and it can appear only once in a profile (as can the Clean Pixel Data and Defacing elements).