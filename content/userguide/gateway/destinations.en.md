---
title: Destinations
weight: 10
description: Destinations management in Karnak
---

This page allows you to configure destinations for your forward nodes. Destinations define where DICOM instances are sent and how they are processed during transfer.

> [!INFO]
> To access this page, first select a forward node from the [Gateway](../) page, then open the **Destinations** tab (it is selected by default).

Depending on the protocol used, two types of destinations can be created:

- [**DICOM Destinations**](#dicom-destination) - Traditional DICOM protocol
- [**STOW Destinations**](#stow-destination) - DICOMWeb (STOW-RS) protocol

## DICOM Destination

A DICOM Destination uses the traditional DICOM protocol to forward instances to another DICOM node.

### Creating a DICOM Destination

**AETitle**, **Hostname** and **Port**  are mandatory when creating a DICOM Destination.

![Creation source](/userguide-new/destination_DICOM.png)

### Configuration Options

#### 1. Destination Parameters

These fields define where Karnak should send the DICOM instances.

- **AETitle**: The Application Entity Title that identifies the destination DICOM node.
- **Hostname**: The IP address or hostname of the destination server.
- **Port**: The network port used by the destination DICOM service (must be between 1 and 65535).
- **Concurrent connections**: The number of parallel DICOM associations Karnak opens to this destination (between 1 and 50; `1` means a single connection). Increasing this value improves throughput when forwarding large studies, but must stay within the destination PACS's concurrent-association limit.
- **Condition** (labeled *Condition (Leave blank if no condition)*): An optional field that can contain an expression. If the condition is met, the destination will be activated. See [Conditions](../../../profiles/conditions) for more details.

#### 2. Transfer Syntax

This field defines the [transfer syntax](http://dicom.nema.org/medical/dicom/current/output/chtml/part05/chapter_10.html) used when sending DICOM instances to this destination. The transfer syntax determines the encoding and compression format of the DICOM data.

It is recommended to choose "Keep original transfer syntax" unless you have specific requirements for compression or compatibility with the destination system.

When selecting a specific transfer syntax, ensure that the destination system supports it to avoid decompression or compatibility issues. It is also recommended to check "Transcode only uncompressed" when selecting lossy syntaxes to avoid re-compressing already compressed data.

> [!INFO]
> Transcoding may increase processing time and resource usage, especially for large datasets. Use it judiciously based on your workflow needs.

#### 3. Use AETitle Destination

When this option is **checked**, use the destination AETitle as the calling AETitle instead of the Forward Node AETitle during the DICOM association.

#### 4. Notifications

Check **Activate notification** to receive automatic email summaries of forwarded
instances, including success and error reports.

![Notifications](/userguide-new/destination_notifications.png)

**Configuration fields** (on screen each label is prefixed with `Notif.:` and shows its
default inline, e.g. *Notif.: error subject prefix (Default: \*\*ERROR\*\*)*):

| Field | Description | Default Value |
|-------|-------------|---------------|
| **List of emails** | Comma-separated list of recipient email addresses | None |
| **Error subject prefix** | Prefix added to email subjects when an error occurs | `**ERROR**` |
| **Rejection subject prefix** | Prefix added when an instance is rejected due to filters or criteria | `**REJECTED**` |
| **Subject pattern** | Email subject template using [Java String Format](https://dzone.com/articles/java-string-format-examples) | `[Karnak Notification] %s %.30s` |
| **Subject values** | DICOM attributes to inject into the subject pattern (PatientID, StudyDescription, StudyDate, StudyInstanceUID) | `PatientID,StudyDescription` |
| **Interval** | Time in seconds to wait before sending notification (aggregates multiple instances) | `45` |

> [!INFO]
> The interval setting helps reduce email volume by aggregating notifications. All instances received within the specified interval are summarized in a single email.

> [!INFO]
> Each email reports only what is **new since the previous notification** for a given
> series (the delta), so outcomes that were already reported are not counted again when
> the series is touched by a later transfer. A series touched only by retries or duplicate
> re-sends has nothing new to report and therefore does not trigger a notification.

#### 5. Virtual Destination

When **Virtual destination (report only, discard DICOM)** is checked, the destination
does **not** forward anything to a real node. Each study is still received and validated,
but the only output is the [DICOM conformance report](#6-dicom-conformance-report), which
is emailed. Delivery settings (transfer syntax, notifications, etc.) do not apply, and the
conformance report is mandatory and cannot be turned off while the destination is virtual.

This is useful to validate DICOM conformance — for testing, validation-only deployments,
or audit purposes — without sending any data.

> [!INFO]
> On screen, the **Virtual destination** and **Build DICOM conformance report** options
> share a single box, displayed right after **Notifications** and before **Tag Morphing**
> and **De-identification**.

#### 6. DICOM Conformance Report

Enable **Build DICOM conformance report** to validate every study sent to this
destination against the DICOM standard and email an HTML report. When enabled, options
appear to set the report's recipient emails, to also check value content conformity
(VR rules), and to perform deep sequence validation.

![Notifications](/userguide-new/destination_conformance_st.png)

See the dedicated [Conformance Report](../conformancereport) page for what each option
does, when the report is sent, and what it contains.

#### 7. Tag Morphing

Tag morphing allows you to modify specific DICOM tag values defined in a profile. With this mode, it is not mandatory to de-identify patient information like in **De-identification** mode.

**Prerequisites:**

- A [project must be created](../../projects#1-create-a-project) first
- The project must have an associated profile

**Configuration:**

1. Select the project from the dropdown
2. The applied profile and its version are displayed below the selection

If no project exists yet, the same [no-project popup](#8-de-identification) shown for
de-identification appears, letting you create one or cancel.

![Tag Morphing](/userguide-new/destination_tagmorphing.png)

> [!INFO]
> **Activate tag morphing** and **Activate de-identification** are mutually exclusive options. Only one can be active at a time.

#### 8. De-identification

De-identification removes or replaces patient-identifying information in DICOM instances according to configurable rules and profiles. It is not possible to preserve the patient identity in the profile when this option is activated.

> [!INFO]
> **Activate de-identification** and **Activate tag morphing** are mutually exclusive options. Only one can be active at a time.

**Prerequisites:**

To activate de-identification, you must [create a project](../../projects#1-create-a-project) first.

**If no project exists:**

A popup will appear with two options, either create a project or continue without activating de-identification.

![Popup deidentification](/userguide-new/popup_deidentification.png)

**If a project exists:**

Configure de-identification as shown below:

![Configure de-identification](/userguide-new/deidentification_activate.png)

##### Project Selection

Select the project that defines the de-identification profile to apply. The profile name and version are displayed below the selection.

Each project is associated with:
- A de-identification profile
- A secret key used for pseudonymization and UID generation

See the [Projects](../../projects) page for more information about project configuration.

##### Pseudonym Type

Pseudonyms replace patient identifiers while maintaining the ability to link de-identified data back to the original patient (when necessary and authorized).

Choose how Karnak should retrieve or generate pseudonyms:

| Type | Description | Use Case |
|------|-------------|----------|
| **Pseudonym is already stored in KARNAK** | Queries the internal pseudonym cache | When using [External Pseudonym](../../extpseudo) |
| **Pseudonym is in a DICOM tag** | Extracts pseudonym from a specified DICOM tag | When pseudonyms are pre-populated in DICOM data |
| **Pseudonym from external API** | Retrieves pseudonym via API call | When using external pseudonymization services |

###### Pseudonym is already stored in KARNAK

This option queries the pseudonym stored in the internal cache as explained in [External Pseudonym](../../extpseudo).

**Behavior:**
- Karnak queries its internal cache using the Patient ID and Issuer of Patient ID
- If a pseudonym is found, it is used for de-identification
- If no pseudonym is returned, the transfer of the DICOM instance is aborted. Ensure pseudonyms are correctly populated in [External Pseudonym](../../extpseudo).

###### Pseudonym is in a DICOM tag

This option retrieves the pseudonym from a specified DICOM tag within the instance itself.

![Pseudonym is in a DICOM tag](/userguide-new/pseudonym_dicomtag.png)

**Required configuration:**

- **Tag**: The DICOM tag containing the pseudonym (e.g., Clinical Trial Subject ID `(0012,0040)`)

**Optional configuration:**

- **Delimiter**: Character used to split the tag value
- **Position**: Which part to use after splitting (zero-based index)

**Example:**

If tag `(0012,0040)` contains `"SITE01-PSN12345"` and you set:
- Delimiter: `-`
- Position: `1`

The pseudonym will be `"PSN12345"`.

If no delimiter and position are specified, the entire tag value is used as the pseudonym.

###### Pseudonym from external API

This option makes an API call to retrieve the pseudonym from an external service.

![Pseudonym from API](/userguide-new/pseudonym_api.png)

The detailed usage of all the fields is explained in the [API Actions page](../../../profiles/api). The behavior is identical to profile API actions.

You can reference an [Authentication Configuration](../../authconfig) to securely manage API credentials for OAuth 2.0.

##### Issuer of Patient ID by default

This field (labeled *Issuer of Patient ID by default*) provides a default value for the Issuer of Patient ID when it's not present in the DICOM instance.

**Usage:**

This value is used when retrieving the pseudonym using the [External Pseudonym](../../extpseudo) cache. The pseudonym is queried based on:
- Patient ID (from DICOM tag `0010,0020`)
- Issuer of Patient ID (from DICOM tag `0010,0021` or this default value)

The combination of Patient ID and Issuer ensures unique patient identification across different healthcare systems.

##### Ignore the Issuer of Patient ID (cache lookup)

This option is only available when the pseudonym type is **Pseudonym is already stored
in KARNAK**. On screen it is the checkbox *"Does the Issuer of Patient ID of the image to
de-identify should be ignored when retrieving the pseudonym in the cache? (only for
'Pseudonym is already stored in KARNAK')"*. When checked, the Issuer of Patient ID of the
incoming image is **ignored** when building the key used to look up the pseudonym in the
cache.

It is **enabled by default**, so the same Patient ID is matched even when it is registered
under a different (or missing) issuer in the [External Pseudonym](../../extpseudo) cache
than in the images you receive. Uncheck it if you need the issuer to be part of the lookup
key. When this option is checked, the *Issuer of Patient ID by default* field is cleared
and disabled, since it no longer takes part in the lookup.

#### 9. Authorized SOPs

Filter which DICOM instance types (SOP Classes) are forwarded to this destination.

![SOP Filter](/userguide-new/destination_SOPfilter.png)

**Configuration:**

- **Enabled**: Only instances matching the specified [SOP Classes](http://dicom.nema.org/medical/Dicom/current/output/chtml/part04/sect_B.5.html) are transferred
- **Disabled**: All SOP Classes are transferred without restriction

#### 10. Enable the Destination

This toggle allows you to temporarily disable a destination without deleting it. The state is also visible in the destination list with a green (enabled) or red (disabled) indicator.

Use this feature to:
- Temporarily pause forwarding during maintenance
- Test configurations without affecting production destinations
- Keep backup destination configurations ready but inactive

#### 11. Action Buttons

Three actions are available to manage the destination:

| Button | Description |
|--------|-------------|
| **Save** | Saves all changes made to the destination configuration |
| **Delete** | Permanently deletes the selected destination |
| **Cancel** | Reverts all unsaved changes to the last saved state |

> [!WARNING]
> Deleting a destination cannot be undone. All configuration settings will be permanently removed.

---

### Creating a STOW Destination

The URL is required for STOW Destination creation. Most configuration options are identical to [DICOM Destinations](#dicom-destination). Only the differences are detailed below.

![Creation source](/userguide-new/destination_stow.png)

### Configuration Differences

#### 1. Destination Parameters

**URL**: The DICOMweb STOW-RS endpoint where DICOM instances will be sent (e.g., `https://pacs.example.com/dicomweb/studies`).

**Condition**: An optional expression that activates the destination when met. See [Conditions](../../../profiles/conditions) for more details.

##### Use HTTP/2

When **Use HTTP/2** is checked, STOW-RS uploads use HTTP/2 instead of HTTP/1.1.

> [!WARNING]
> Leave this **unchecked** (HTTP/1.1) when the archive sits behind a reverse proxy that
> caps the number of HTTP/2 requests per connection (e.g. KHEOPS / nginx
> `http2_max_requests=1000`), which can silently drop instances beyond the limit.

##### HTTP Headers

The **Headers** field contains HTTP headers added to each STOW-RS request.

**Format:** Headers are defined using XML-style key-value tags as shown below:
```
<key>Header-Name</key>
<value>Header-Value</value>

<key>Another-Header</key>
<value>Another-Value</value>
```

##### Generate Authorization Header

Click the **Generate Authorization Header** button to automatically generate properly formatted authentication headers.

> [!WARNING]
> If a header with `<key>Authorization</key>` already exists, an error will be displayed. The generator will append to existing headers if they don't conflict.

**Supported Authorization Types:** the dialog has an **Authorization Type** selector
(**Basic Auth** or **OAuth 2**) and a **Generate Headers** button that appends the
generated header.

###### Basic Auth

Use for simple username/password authentication:

![Creation source](/userguide-new/destination_basicauth.png)

**Generated headers:**
```
<key>Authorization</key>
<value>Basic dXNlcm5hbWU6cGFzc3dvcmQ=</value>
```

The username and password are Base64-encoded automatically.

###### OAuth 2

Use for token-based authentication:

![Creation source](/userguide-new/destination_oauth.png)

**Generated headers:**
```
<key>Authorization</key>
<value>Bearer 1234567890</value>
```

##### 2. Switching to different Kheops albums

If the destination is a Kheops endpoint, it is possible to configure multiple albums by selecting the option "Switching in different KHEOPS albums".

Explanations for configuring Kheops-related parameters can be found in the [Kheops](../../kheops) section.
