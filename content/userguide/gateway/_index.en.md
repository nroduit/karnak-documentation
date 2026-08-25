---
title: Gateway
weight: 10
description: Gateway management in Karnak
---

The Gateway page allows you to configure Forward Nodes in Karnak. A Forward Node represents a DICOM Application Entity (AE) that receives DICOM instances and routes them to one or more destinations.

## Forward Node

This page lists all the forward nodes configured in Karnak and allows you to create, edit, and delete them.

{{% annotate src="/userguide-new/gateway_forwardnode.png" viewbox="0 0 2940 1190" alt="Gateway and Forward Node" %}}
1               |    | 950,65 | 40
2               |    | 840,145 | 40
3               |    | 1180,350 | 40
4               |    | 2850,40 | 40
@box | 1345,180,1570,500 | #00a6b6
5               |    | 2750,620 | 40
{{% /annotate %}}

##### 1. Create a Forward Node

Click the **New forward node** button. A popup will appear:
  1. Enter a unique value in the **Forward AETitle** field. AE Titles must not exceed 16 characters.
  2. Click the **Add** button

![New Forward Node](/userguide-new/gateway_new_forwardnode.png)

The new forward node appears in the list and is automatically selected. Optionally, add a description and save your changes.

> [!INFO]
> The Forward AETitle must be unique across all forward nodes in the Karnak instance.

##### 2. Create a group

When the list grows, you can organize forward nodes into **groups** (a single level of
folders) to keep related nodes together:

- Click **Add group** to create a new group and give it a name.
- **Drag a forward node onto a group** to assign it to that group.
- **Right-click a group** to **Rename group** or **Delete group**; deleting a group only
  removes the folder — the nodes it contained move back out, they are not deleted.
- **Right-click a node** and choose **Remove from group** to take it out of its group.

Groups are purely organizational; they do not change how forward nodes behave. The same
grouping is available for [Projects](../projects) and [Profiles](../profiles).


![Group](/userguide-new/gateway_group.png)

##### 3. Forward Node List

All configured forward nodes and groups are displayed in the left panel. 

Select a forward node from the list to view and manage its configuration in the right panel.

> [!INFO]
> The copy icon {{< svg-inline "static/userguide/copy.svg" >}} next to each forward node allows you to quickly copy its DICOM configuration in the clipboard for use in DICOM clients.

##### 4. Forward Node Parameters

In the details view, you can modify:

- **Forward AETitle**: The Application Entity Title of the forward node
- **Description**: An optional description to help identify the node's purpose

Click the **Save** button to apply your changes.

##### 5. Sources and Destinations

Each forward node can be configured with:

- [**Sources**](sources): Control which DICOM nodes are authorized to send data to this forward node
- [**Destinations**](destinations): Define where received DICOM instances should be forwarded

{{% annotate src="/userguide-new/gateway_destinationspage.png" viewbox="0 0 843 253" alt="Forward Node details" %}}
1               |    | 240,27 | 15
2               |    | 25,87 | 15
3               |    | 697,67 | 15
4               |    | 750,200 | 15
{{% /annotate %}}

###### 5.1 Navigation

Use the tabs to switch between the [**Destinations**](destinations) and [**Sources**](sources) views for the selected forward node.

###### 5.2 Filtering

**Destinations tab**: a free-text filter matching a destination's description, AE Title, hostname, port, URL, headers and notification settings.

**Sources tab**: a free-text filter matching a source's description, AE Title and hostname.

###### 5.3 List

All destinations or sources associated with the forward node are displayed here.

Click any item in the list (or a **New** button) to open its configuration form. The form
**replaces** the list panel in place; click **Cancel** to return to the list.

###### 5.4 Actions

The available action buttons depend on the active tab.

**Destinations tab**: 

Create a new destination using either the DICOM or DICOM WEB (STOW) protocol. See the [Destinations](destinations) page for detailed configuration instructions.

**Sources tab**: 

Create a new source to control which DICOM nodes can send data to this forward node. See the [Sources](sources) page for detailed configuration instructions.

##### 5. Forward Node Actions

Three action buttons are available:

| Action | Description |
|--------|-------------|
| **Save** | Saves changes made to the forward node parameters |
| **Delete** | Deletes the selected forward node and all associated configurations |
| **Cancel** | Reverts unsaved changes to the forward node parameters |

> [!WARNING]
> Deleting a forward node will also remove all associated sources and destinations. This action cannot be undone.