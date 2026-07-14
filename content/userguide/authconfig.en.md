---
title: Authentication Config
weight: 80
description: Authentication Configuration for API calls
---

This page allows you to configure authentication credentials for API calls. Since this information is sensitive, it is stored in an encrypted database table.

![authconfig page](/userguide/authconfig_main.png)

##### 1. Create an Authentication Configuration

Click the **New authentication config** button to begin. You'll be prompted to enter a unique identifier for the new configuration.

![authconfig create](/userguide/authconfig_create.png)

**Requirements:**

- The identifier must be unique (an error will appear if a duplicate exists)
- We recommend avoiding spaces in the identifier for easier reference in profiles

Click **Add** to proceed. The popup closes and an empty, editable configuration form
appears in the right panel. The configuration is **not** saved yet — fill in the OAuth 2.0
fields described below and click **Save** to create it. Only then is it persisted and added
to the list on the left. Click **Cancel** to discard it.

###### OAuth 2.0

Currently, OAuth 2.0 is the only supported authentication type.

**Required fields:**

| Field                | Description                                                 |
|----------------------|-------------------------------------------------------------|
| **Access Token URL** | The OAuth 2.0 token endpoint                                |
| **Scope**            | Required scopes (separate multiple scopes with whitespace)  |
| **Client Secret**    | OAuth 2.0 client secret                                     |
| **Client ID**        | OAuth 2.0 client identifier                                 |

![authconfig create form](/userguide/authconfig_createform.png)

Once all required fields are filled, click **Save** to create the configuration and add it
to the list; click **Cancel** to discard it.

**How it works:**

When an API call references this configuration (via the `authConfig` parameter):

1. Karnak checks if a valid access token is available
2. If yes, the token is added to the request for authentication
3. If no, a new token is requested using the configuration details
4. The API call proceeds with the authenticated token

> [!WARNING]
> Authentication configurations cannot be modified after creation. To make changes, you must delete and recreate the configuration.

##### 2. Authentication Configuration List

All available authentication configurations are displayed in the left panel. Select a configuration to view its details on the right.

##### 3. Configuration Details

The details view displays all configuration information in read-only mode. 

To modify a configuration, you must delete it and create a new one.

##### 4. Delete Configuration

To delete a configuration:

1. Select it from the list
2. Click the red trash bin icon next to its identifier
3. Confirm the deletion in the popup

![authconfig delete](/userguide/authconfig_delete.png)

> [!INFO]
> Deleting a configuration in use may cause errors in your workflows. Karnak does not verify whether a configuration is referenced by profiles or de-identification processes before deletion. Ensure the configuration is not in use before deleting it, or transfers will fail.