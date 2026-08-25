---
title: API Actions
weight: 45
description: Definition of the actions related to API calls
---

## Actions with API calls

This profile element uses a call to an API to replace the value of a tag or a group of tags defined by the user.

Another variant of this action regarding shifting dates using values retrieved from an external API is described in [Shift Dates from API](../dates/#shift-from-api-option).

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| **name** | Required | Description of the action applied |
| **codename** | Required | Must be set to `action.replace.api` |
| **arguments** | Required | Definition of the API call configuration (see [Arguments](#arguments) below) |
| **tags** | Required | List of tags the action should be applied to |
| **condition** | Optional | Condition to evaluate if this profile element should be applied to this DICOM instance |
| **excludedTags** | Optional | List of tags that will be ignored by this action |

### Arguments

| Argument | Type | Description                                                                                                                                                                                                                                                                       |
|----------|------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **url** | Required | URL of the API to query. Can contain runtime parameters (see [URL and Body Arguments](#url-and-body-arguments)).                                                                                                                                                                  |
| **responsePath** | Required | JSON path of the value used as replacement, using [JSON Pointer](https://datatracker.ietf.org/doc/html/rfc6901) syntax. Empty string means the entire response value will be used.                                                                                                |
| **method** | Optional | HTTP method: `GET` or `POST`. Defaults to `GET`.                                                                                                                                                                                                                                  |
| **body** | Optional | Request body for POST requests in JSON format. Can contain runtime parameters (see [URL and Body Arguments](#url-and-body-arguments)).                                                                                                                                            |
| **authConfig** | Optional | Identifier of an existing [Authentication Configuration](../../userguide/authconfig) for authenticating the call. No authentication used if not specified.                                                                                                                        |
| **defaultValue** | Optional | Fallback value used when an error occurs during the API call (e.g., Unauthorized, value not found, authConfig not found). If not specified, the transfer will be aborted with an error displayed in monitoring. When specified, the default value is used and transfer continues. |
### URL and Body Arguments

The URL and body may require values directly linked to the instance being transferred, such as the Patient ID.

A specific syntax allows this runtime injection. Parts evaluated at runtime must be enclosed in **double brackets**. The syntax uses [Spring Expression Language (SpEL)](https://docs.spring.io/spring-framework/reference/core/expressions.html), with functions and constants defined similarly to [Expressions](../expressions).

**URL examples:**

```yaml
http://example.com/{{getString(#Tag.PatientID)}}/endpoint
http://example.com/{{getString(#Tag.ClinicalTrialSponsorName)}}/patient/{{getString(#Tag.PatientID)}}/endpoint

{ 
  "patientId": "{{getString(#Tag.PatientID)}}", 
  "project": "{{getString(#Tag.ClinicalTrialSponsorName)}}" 
}
```

In the body, hence the JSON format, the expression must be enclosed in double quotes if the expected value is a String.

## Examples

###  Example 1: Replace Patient ID with API response

The profile element below replaces the value of the Patient ID tag with the value retrieved from the url, it extracts the String value from the response at the specified path. Since it is not specified, the HTTP method is GET.

The authConfig argument contains the identifier of the Authentication Configuration used to authenticate the API call.

If an error occurs during the call, this transfer will be aborted. If the defaultValue was specified, it would have been used as the replacement value and the transfer would not have been blocked.

```yaml
  - name: "Replace Patient ID from API call"
    codename: "action.replace.api"
    arguments:
      url: "http://example.com/{{getString(#Tag.PatientID)}}/endpoint"
      responsePath: "/_embedded/0/value"
      authConfig: "endpoint-auth-config"
    tags:
      - "(0010,0020)"
```
### Example 2: POST request with body and default value

```yaml
  - name: "Replace Patient Name with fallback"
    codename: "action.replace.api"
    arguments:
      url: "http://example.com/patients"
      method: "POST"
      body: '{"patientId": "{{getString(#Tag.PatientID)}}"}'
      responsePath: "/name"
      authConfig: "endpoint-auth-config"
      defaultValue: "ANONYMOUS"
    tags:
      - "(0010,0010)"
```