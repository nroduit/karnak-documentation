---
archetype: "home"
title: "Karnak"
description: "Karnak is a DICOM gateway for data de-identification and DICOM attribute normalization."
keywords: [ "dicom gateway", "de-identification", "pseudonymization", "tag morphing", "dicom conformance", "dicom proxy" ]
---

Karnak is a DICOM gateway for data de-identification and DICOM attribute normalization. It is distributed as a containerized and portable application, making it easy to deploy and use across various environments.

{{< svg "static/images/karnak-gateway.svg" >}}

<a href="/images/karnak-gateway.svg" target="_blank">Open the diagram at full size</a>

Karnak receives studies through a DICOM listener and forwards them to DICOM (C-STORE) or DICOMweb (STOW-RS) destinations.

## Get started

1. [Install Karnak with Docker Compose](installation) on a server, or [download the portable distribution](userguide/portable) to run it on a single machine without installation.
2. Create a [forward node with its sources and destinations](userguide/gateway).
3. Create a [project](userguide/projects) and assign it a [de-identification profile](profiles).

## Key Features

*   [**DICOM Gateway**](userguide/gateway): Acts as a proxy between DICOM modalities/workstations and PACS/Archives.
*   [**Flexible Connectivity**](userguide/gateway/destinations): Supports standard DICOM protocols (C-STORE) and DICOMweb (STOW-RS).
*   [**De-identification**](profiles/rules): Based on the DICOM standard, with configurable actions in YAML profiles.
*   [**Clean pixels**](profiles/masks/): Remove burned-in annotations with hand-defined masks or automatically through OCR service.
*   [**Pseudonymization**](userguide/gateway/destinations/#pseudonym-type): Apply pseudonyms from DICOM fields, by importing CSV, or with external web services.
*   [**Tag Morphing**](userguide/gateway/destinations/#7-tag-morphing): Normalizes DICOM attributes to ensure consistency across your workflow.
*   [**Conditional Processing**](profiles/conditions/): Apply de-identification and tag morphing rules based on customizable conditions.
*   [**Conformance Reports**](userguide/conformancereport): Validate each study against the DICOM standard and email a conformance report, with optional report-only (virtual) destinations.
*   [**Monitoring**](userguide/monitoring): Follow transfers in a destination, study and series tree, compare original and de-identified values, and export the activity as CSV.
*   [**Notification System**](userguide/gateway/destinations/#4-notifications): Email notifications for successful transfers and errors.
*   [**Diagnostic Tools**](userguide/dicomtools): Test and probe DICOM nodes and DICOMweb endpoints — echo, capabilities, network and service checks.
*   [**Project Management**](userguide/projects): Organize de-identification rules and secrets by project.
*   [**Single Sign-On**](installation/#identity-provider): Delegate the web portal login to an OpenID Connect provider such as Keycloak.
*   [**Web Interface**](userguide): User-friendly web portal for configuration, profile building and monitoring.
*   [**Portable Distribution**](userguide/portable): Run Karnak as a portable application without installation.

## Links

*   [Source code on GitHub](https://github.com/nroduit/karnak)
*   [Container image on Docker Hub](https://hub.docker.com/r/nroduit/karnak)
