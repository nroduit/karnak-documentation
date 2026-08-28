---
title: Conformance Report
weight: 75
description: Validate studies against the DICOM standard and email a conformance report
---

Karnak can validate every study sent to a destination against the **DICOM standard** and
email an HTML **conformance report**. This helps detect silent conformance problems —
unsupported SOP classes, malformed values, inconsistent attributes across a study —
before or while data is forwarded.

The feature is configured **per destination**. It can be combined with normal forwarding
(validate *and* send), or used on its own with a
[virtual destination](gateway/destinations/#5-virtual-destination) that validates and
reports only, without sending anything.

## Enabling the report

Conformance reporting is enabled in the destination editor. See the
[Destinations](gateway/destinations/#6-dicom-conformance-report) page for the exact
location of the settings.

![Notifications](/userguide/destination_conformance_st.png)

| Setting | Description |
|---------|-------------|
| **Build DICOM conformance report** | Turns the feature on for the destination. |
| **Conformance report: list of emails** | Comma-separated recipients. Leave empty to reuse the destination's [notification](gateway/destinations/#4-notifications) email list. |
| **Check value content conformity (VR rules)** | Also report values that violate their VR length or format rules (PS3.5) — e.g. an over-long string or a malformed date. |
| **Deep sequence validation (SR, functional groups)** | Recurse the checks through every sequence level (e.g. the SR content tree or enhanced multiframe functional groups) instead of only the first one. The recursion is bounded by a defined depth limit (`conformance-report.max-sequence-depth`, **8** by default). Off by default, as deeper recursion increases memory use. |

> [!INFO]
> A [virtual destination](gateway/destinations/#5-virtual-destination) is report-only:
> it always builds a conformance report — that is its only output — so the report cannot
> be turned off while the destination is virtual.

## When the report is sent

Reports are generated **per study**. Karnak accumulates the validation results of every
instance of a study as they are processed, and emails one report once the study's
transfer **goes idle** — i.e. no new instance has arrived for that study within the idle
timeout (5 minutes by default). A study is also flushed if it exceeds a maximum lifetime
(4 hours by default), to guard against studies that never complete.

> [!INFO]
> If a study has no recipient email — neither a conformance report list nor a fallback
> notification list — its report is dropped (and the event is logged). Make sure at least
> one email address is configured.

These timings are tunable by the administrator with the following settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `conformance-report.idle-timeout-seconds` | `300` | Idle delay after the last instance of a study before the report is sent. |
| `conformance-report.max-study-lifetime-seconds` | `14400` | Maximum lifetime of a study batch before it is flushed regardless of idleness. |
| `conformance-report.max-sequence-depth` | `8` | Maximum sequence recursion depth used when *Deep sequence validation* is enabled. |

## How the report is built

Each instance is validated against the **IOD** of its SOP Class. An *Information Object
Definition (IOD)* is the part of the DICOM standard that specifies, for a given object
type (e.g. an MR Image, a CT Image, a Structured Report), which **modules** and
**attributes** the object must contain and how strict each one is.

The checks use a bundled, machine-readable copy of the DICOM standard extracted by the
[Innolitics `dicom-standard`](https://github.com/innolitics/dicom-standard) project
(the list of SOP Classes, their modules, and every attribute with its VR, value
multiplicity and Type), complemented by a curated rule set maintained in Karnak for the
parts the standard only expresses as prose (enumerated values and a subset of
machine-evaluable conditions).

### IOD structure (modules, tags, VR, Type)

For the instance's SOP Class, Karnak resolves the applicable modules and checks:

- **Module presence** — a mandatory (usage *M*) module whose required attributes are all
  absent is reported as missing.
- **Attribute Type** — each attribute's requirement is enforced:
  - **Type 1** — must be present **and** carry a value (present-but-empty is an error).
  - **Type 2** — must be present, but may be empty.
  - **Type 3** — optional.
- **VR (Value Representation)** — the encoded VR must match the one the standard defines
  for the attribute.
- **VM (Value Multiplicity)** — the number of values must fall within the range the
  standard allows.

### Conditional requirements (Type 1C / 2C)

Some attributes are **conditionally** required (Type *1C* / *2C*, or attributes inside a
usage-*C* module) — mandatory only when a condition holds (for example, "required if the
image is a localizer"). Karnak evaluates these **when possible**: when a curated,
machine-evaluable condition resolves to *true* for the instance, the attribute is treated
as mandatory (1C is checked like Type 1, 2C like Type 2).

> [!INFO]
> **Limitation.** In the standard, these conditions are free text and many are clinical
> in nature, so they cannot all be evaluated automatically. When a condition has no curated
> machine-evaluable rule — or it evaluates to *false*/*unknown* — the attribute is **only**
> validated if it is actually present; its conditional requirement is not enforced. Karnak
> therefore never raises a *false* conformance error on a condition it cannot reliably
> evaluate.

### Private tags

Private data elements are checked for **block structure** only (PS3.5 §7.8): every private
data element must belong to a block reserved by a **non-empty Private Creator** element. A
private element with no reserving creator, or an empty Private Creator, is reported.

> [!INFO]
> **Limitation.** Private *values* are not interpreted or validated — Karnak does not carry
> vendor-specific private dictionaries, so only the standard-defined block structure is
> verified.

### Other checks

Beyond the IOD structure, Karnak runs a set of **value-level and cross-attribute checks**
modelled on those of David Clunie's [`dciodvfy`](https://www.dclunie.com/dicom3tools/dciodvfy.html)
verifier. The table lists what each one verifies and the severity it raises; a few are
*optional* (value-conformity option) or *deep* (deep-sequence option), as noted.

| Check | What it verifies | Severity |
|-------|------------------|:--------:|
| **Enumerated values / Defined Terms** | Value lies within a closed Enumerated Values set; an unexpected Defined Term is a softer signal. | Error / Warning |
| **Plausible values** | No value of **zero** where it is physically impossible — structural counts & geometry vs. acquisition/physics parameters¹ — and no negative *Spacing Between Slices* (Nuclear Medicine excepted). | Error / Warning |
| **Pixel geometry** | *Pixel Aspect Ratio* of **1:1** is omitted; *Pixel Spacing* matches *Imager / Nominal Scanned Pixel Spacing* unless a *Pixel Spacing Calibration Type* explains the difference. | Error / Warning |
| **Image & patient orientation** | *Image Orientation (Patient)* is two **unit**, **orthogonal** direction-cosine vectors; *Patient Orientation* uses valid biped codes, with no opposing directions in one value and distinct row/column directions. | Error |
| **Laterality** | A **paired** (non-midline) *Body Part Examined* carries a Laterality, unless one is already conveyed or the object type makes it inapplicable. | Warning |
| **Coded entries** | A *Code Value* uses only the characters its *Coding Scheme Designator* allows (SNOMED / DICOM) and does not denote the *"Unknown"* concept. | Warning |
| **Identifier reuse** | The SOP Instance, Series, Study and Frame of Reference UIDs all differ from one another. | Error |
| **Residual identifiers** | No **direct identifier** remains after de-identification (telephone, address, other names, institution / physician names, occupation, comments…).² | Warning |
| **Standard Extended SOP Class** | A standard attribute present but not part of the object's IOD. | Info |
| **Retired constructs** | Attributes, SOP Classes or transfer syntaxes retired in the current standard. | Info |
| **Value content conformity** *(optional)* | String values obey their VR length and format rules (PS3.5 §6.2). | Error / Warning |
| **Enhanced multi-frame & segmentation** | *Per-frame Functional Groups* item count equals *Number of Frames*; *Segment Numbers* increase monotonically from one (LABELMAP excepted). *(deep)* *Dimension Index Values* match the *Dimension Index Sequence*, and no functional group appears in both the Shared and a Per-frame group. | Error |
| **Study-level consistency** | Across the closed study: one Study Instance UID, one Patient ID & Name, consistent Frame of Reference, and Modality ↔ SOP Class coherence. | Error / Warning |

> [!INFO]
> ¹ **Zero is an *error*** for structural counts and geometry (Rows, Columns, Bits
> Allocated/Stored, Samples per Pixel, Number of Frames, Pixel/Imager Spacing, Slice
> Thickness, Rescale Slope) and a *warning* for acquisition/physics parameters where it is
> merely implausible (KVP, X-Ray Tube Current, Exposure, source distances, Echo/Repetition
> Time, Magnetic Field Strength, Flip Angle, Patient Weight/Size…).
> 
> ² The **residual-identifier** check is specific to the de-identification use case (it goes
> beyond `dciodvfy`); its attribute list mirrors the identifiers removed by `dciodvfy`'s
> companion de-identifier, `dcanon`, and it is most useful on a de-identifying destination.

### Scope notes

- **VR** is not checked for *Implicit VR Little Endian* datasets, where the VR comes from
  the dictionary (the check would be circular).
- By default only the top level and the first sequence level are validated; enabling
  [Deep sequence validation](#enabling-the-report) walks deeper, bounded by the
  `conformance-report.max-sequence-depth` limit. Two enhanced multi-frame checks
  (Dimension Index Values count, and a functional group present in both the Shared and a
  Per-frame group) require this option, because they read per-frame functional groups.
- Deep validation checks the **encoding** and the **structural rules** of nested attributes;
  it does **not** verify SR-specific semantics (template/TID conformance, content-item
  value-type rules, parent/child relationships) or whole-slide tile relationships.
- SOP Classes the bundled standard does not define (unknown or retired) are flagged, and
  their IOD module checks are skipped.

## What the report contains

The HTML email summarizes, for the study:

- **Study and patient context** — patient ID and name, study date, description and
  accession number, source AE Title, and whether the data was de-identified.
- **Counts** — number of series, instances, and failed instances, plus the totals of
  **errors**, **warnings** and **informational** findings, and an overall **pass/fail**.
- **Composition** — the modalities, SOP Class UIDs and transfer syntaxes encountered.
- **Per-series summary** — each series with its modality, SOP classes and instance count.
- **Findings** — conformance findings grouped by SOP class (with an example instance and
  a count), and study-level **consistency findings** for attributes that should be
  identical across the study but are not.

## Examples

The reports below are real, de-identified examples — three studies that fail conformance
and one that passes — that illustrate the kinds of findings the validator produces. Each
opens in a new tab as the actual HTML email.

> [!INFO]
> In every example the patient *name* shows as *(hidden — destination not de-identified)*.
> The report only redacts the name when the destination's data is **not** de-identified, to
> avoid emailing identifying information in clear text; the patient ID and other attributes
> are still shown.

### Example 1 — missing module, pixel geometry and private-block issues

> Ultrasound study · 6 series · 6 instances · **FAILED** — 3 errors, 6 warnings, 4 info
>
> <a href="/conformance/karnak-report1.html" target="_blank">View report 1</a>

A multi-frame ultrasound study that trips several unrelated rules at once. The errors are a
**missing mandatory module** (the required *Cine* attributes are all absent) and two
**pixel-geometry** violations (a *Pixel Aspect Ratio* of 1:1 is encoded when the standard says
to omit it). The warnings cover three **private blocks used without a Private Creator**, a
missing Type 2 *Image Type*, a **retired SOP Class**, and a **mis-formatted date**; the
informational findings flag retired and non-standard (standard-extended) attributes. A spread
like this usually reflects the acquisition device's encoding conventions.

### Example 2 — a passing study

> Computed Radiography (CR) study · 1 series · 1 instance · **PASSED** — 0 errors, 8 warnings, 17 info
>
> <a href="/conformance/karnak-report2.html" target="_blank">View report 2</a>

This is what a study that meets the standard looks like: with **no errors the overall result is
PASSED**, even though the report still lists warnings and informational findings. The warnings
are **implausible zero values** — physics parameters such as *KVP*, *Exposure* and *Patient's
Weight* recorded as `0` — and a **missing Laterality** on a paired body part; none of these
breaks the standard, so none fails the study. The informational findings are mostly
**standard-extended attributes** (present but not part of this object's IOD) plus one retired
attribute. A "passed with warnings and info" result like this is normal and usually needs no
action, though the warnings can be worth a look.

### Example 3 — empty Type 1/1C, a VM violation and UID-format problems

> Digital X-Ray (DX) study · 1 series · 1 instance · **FAILED** — 7 errors, 4 warnings, 1 info
>
> <a href="/conformance/karnak-report3.html" target="_blank">View report 3</a>

A good illustration that a **single instance can surface several unrelated rule categories at
once**. The errors span presence (a **missing mandatory module** and four **Type 1 / 1C
attributes present but empty**), value multiplicity (*Patient Orientation* carrying the **wrong
number of values**) and an **image-orientation** rule. The warnings add a missing recommended
attribute and three **UID-format** problems (identifiers that don't follow the DICOM UID
syntax). When one object trips this many distinct rules, the cause is usually upstream encoding
rather than the individual values.

### Example 4 — missing Type 1 attributes inside SR sequences

> SR + CR study · 2 series · 2 instances · **FAILED** — 16 errors, 4 warnings, 3 info
>
> <a href="/conformance/karnak-report4.html" target="_blank">View report 4</a>

A mixed-modality study — a **Basic Text Structured Report** sent alongside a Computed Radiography
image — whose SR is missing many mandatory elements. Fifteen of the sixteen errors are **Type 1
attributes missing inside the SR content sequences** (*Graphic Data*, *Concept Code Sequence*,
*Temporal Range Type*…); the remaining error is an empty Type 1 *LUT Data* in the CR image. The
warnings note two missing Type 2 attributes, a value-format issue and a missing Laterality, and
the informational findings list retired and non-standard attributes. A deeply incomplete SR like
this points to the application that generated it.

## Relation to other DICOM validators

Karnak's conformance report is not meant to replace the established standalone validators —
it serves a different purpose. It validates **automatically, inside the forwarding pipeline,
and per study**, so conformance is checked continuously without a separate tool or manual
step. Because it sees the whole study batch, it can also run **cross-instance consistency**
checks (single Study Instance UID, consistent Patient ID / Name, Modality ↔ SOP Class
coherence, Frame of Reference) that single-file tools cannot.

For the per-object checks, Karnak builds on the same approach as the
[`pydicom/dicom-validator`](https://github.com/pydicom/dicom-validator): both derive the IOD
requirements from a **machine-readable copy of the DICOM standard** (Karnak uses the
[Innolitics `dicom-standard`](https://github.com/innolitics/dicom-standard) extraction) and
both **evaluate conditional (Type 1C/2C) requirements only when the condition can be
evaluated**, treating them as optional otherwise — so neither raises false errors on
clinical, free-text conditions.

For the **value-level and cross-attribute checks**, Karnak additionally mirrors a
substantial subset of [`dciodvfy`](https://www.dclunie.com/dicom3tools/dciodvfy.html): zero/
implausible values, pixel and image geometry, patient orientation, laterality, coded-entry
validity, UID reuse and enhanced multi-frame / segmentation consistency (see
[Other checks](#other-checks)). `dciodvfy` nonetheless remains the more exhaustive
single-object reference — notably for byte-level encoding and full SR content-tree
semantics, which Karnak does not attempt.

For an exhaustive, authoritative check of an individual object, or for interactive/standalone
validation, the well-known dedicated tools remain the reference and complement Karnak well:

- [**dciodvfy**](https://www.dclunie.com/dicom3tools/dciodvfy.html) (David Clunie's
  *dicom3tools*) — the long-standing reference single-object validator, with the most
  thorough encoding and value-level checks.
- [**dcm4che `dcmvalidate`**](https://github.com/dcm4che/dcm4che/blob/master/dcm4che-tool/dcm4che-tool-dcmvalidate/README.md)
  — validates against a supplied XML IOD definition.
- [**DVTk**](https://www.dvtk.org/) — a toolkit that validates against editable DICOM
  definition files.
- [**IHE Gazelle**](https://www.ihe-europe.net/testing-IHE/gazelle) — the IHE testing
  platform, whose validation services can run several DICOM validators so their results can
  be compared.