---
archetype: "home"
title: "Karnak"
description: "Karnak is a DICOM gateway for data de-identification and DICOM attribute normalization."
keywords: [ "dicom gateway", "de-identification", "tag morphing", "dicom proxy" ]
---

Karnak is a DICOM gateway for data de-identification and DICOM attribute normalization. It is distributed as a containerized and portable application, making it easy to deploy and use across various environments.

![Karnak gateway](/images/karnak-gateway.png)

Karnak manages a continuous DICOM flow with a DICOM listener as input and a DICOM and/or DICOMWeb as output.

## Key Features

*   [**DICOM Gateway**](userguide/gateway): Acts as a proxy between DICOM modalities/workstations and PACS/Archives.
*   [**Flexible Connectivity**](userguide/gateway/destinations): Supports standard DICOM protocols (C-STORE) and DICOMWeb (STOW-RS).
*   [**De-identification**](profiles): Robust de-identification based on DICOM standards with configurable actions in YAML files.
*   [**Clean pixels**](profiles/masks/): Remove burned-in annotations from images to ensure patient privacy.
*   [**Pseudonymization**](userguide/gateway/destinations/#pseudonym-type): Apply pseudonyms from DICOM fields, by importing CSV, or with external web services.
*   [**Tag Morphing**](userguide/gateway/destinations/#7-tag-morphing): Normalizes DICOM attributes to ensure consistency across your workflow.
*   [**Conditional Processing**](profiles/conditions/): Apply de-identification and tag morphing rules based on customizable conditions.
*   [**Conformance Reports**](userguide/conformancereport): Validate each study against the DICOM standard and email a conformance report, with optional report-only (virtual) destinations.
*   [**Notification System**](userguide/gateway/destinations/#4-notifications): Email notifications for successful transfers and errors.
*   [**Diagnostic Tools**](userguide/dicomtools): Test and probe DICOM nodes and DICOMweb endpoints — echo, capabilities, network, TLS and service checks.
*   [**Project Management**](userguide/projects): Organize de-identification rules and secrets by project.
*   [**Web Interface**](userguide): User-friendly web portal for configuration, profile building and monitoring.
*   [**Portable Distribution**](userguide/portable): Run Karnak as a portable application without installation.

[Source Code on GitHub](https://github.com/nroduit/karnak)

