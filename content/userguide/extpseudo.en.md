---
title: External pseudonym
weight: 40
description: Import and manage pseudonyms from CSV files or manual entry
---

This page allows you to create or import pseudonyms that Karnak will use during de-identification. The de-identification process and how pseudonyms are used is detailed in the [Pseudonym chapter](../../profiles/rules/#pseudonym).

De-identification is activated in the [Destination configuration](../gateway/destinations/#8-de-identification).

> [!INFO]
> Pseudonyms created or imported on this page are stored in a cache with a maximum lifetime of **7 days**.
> 
> With the [portable version of Karnak](../portable), the cache is persistent only the time the application is running. Restarting the application will clear the cache.

{{% annotate src="/userguide/external_pseudonym_main.png" viewbox="0 0 1175 619" alt="External Pseudonym Page" %}}
1               |    | 620,130 | 20
2               |    | 430,210 | 20
3               |    | 330,260 | 20
4               |    | 1114,540 | 20
@box | 10,290,1155,300 | #00a6b6
{{% /annotate %}}

##### 1. Choose a project

External pseudonyms are linked to a specific project. This allows Karnak to properly handle cases where:
- A patient participates in multiple clinical studies with different pseudonyms
- Potential pseudonym collisions occur between projects

##### 2. Upload a CSV file

You can upload a CSV file containing external pseudonyms by:
- Clicking the **Upload File** button
- Dragging and dropping a file onto the upload area

###### 2.1 CSV separator configuration

After selecting a file, a dialog appears asking for the CSV separator character. The default value is a comma (`,`).

![External pseudonym separator dialog](/userguide/external_pseudonym_popup_separator.png)

Click **Open CSV** to proceed to the import configuration.

###### 2.2 Preview and configuration

The CSV data is displayed in a grid for review and configuration.

{{% annotate src="/userguide/external_pseudonym_csv_import_dialog.png" viewbox="0 0 1139 569" alt="External Pseudonym CSV Import" %}}
1               |    | 220,85 | 20
2               |    | 1100,135 | 20
3               |    | 1070,305 | 20
@box | 15,158,1110,200 | #00a6b6
{{% /annotate %}}

**1. From line:** This field defines the starting row for the import. Use this to skip header rows or other non-data lines at the beginning of the file.

**2. Column assignments:** Map each CSV column to the corresponding attribute to ensure that the data is properly imported.  
These fields are initially empty. This mechanism allows flexibility on the content of the CSV file being imported.  
Only the **Patient ID** and **External Pseudonym** fields are required. Other fields are optional.

**3. Data preview:** The data that will be imported as pseudonyms is displayed in the table.

###### 2.3 Import validation

Click **Upload CSV** to import the data. Karnak performs validation checks including:
- Duplicate Patient IDs
- Duplicate Pseudonyms
- Required field validation

If validation errors occur, they will be displayed and the import will be rejected.

##### 3. Pseudonym Actions

###### 3.1 Add a new pseudonym

You can also add external pseudonyms manually. Click the **Add patient** button above the
table to open a popup containing the following fields:
- **External Pseudonym** (required)
- **Patient ID** (required)
- **Patient first name** (optional)
- **Patient last name** (optional)
- **Issuer of patient ID** (optional)

![External pseudonym add](/userguide/external_pseudonym_add.png)

Fill in the fields and click **Add** in the popup to add the entry to the external
pseudonyms table.

###### 3.2 Delete all patients

The **Delete all patients** button removes all external pseudonyms for the selected project only. Pseudonyms linked to other projects are not affected.

##### 4. Pseudonym management

###### 4.1 Edit or delete individual entries

Each pseudonym row has action buttons:
- **Edit**: Modify the patient fields
- **Delete**: Remove the pseudonym from the cache

![External pseudonym edit](/userguide/external_pseudonym_edit.png)

###### 4.2 Bulk operations

Select multiple rows using the checkboxes on the left side of each row. Click **Delete selected patients** to remove all selected entries and confirm the action in the dialog.
