---
title: "Manage Karnak with the REST API"
weight: 20
description: "Configure forward nodes, destinations, projects, profiles and pseudonyms from scripts with the Karnak REST API: authentication, roles, endpoints and the OpenAPI description."
linkTitle: "REST API"
keywords: [ "karnak rest api", "openapi", "pseudonym import", "gateway automation", "api roles" ]
---

Karnak exposes a REST API under `/api` on the web port, so that other systems and scripts can configure the gateway and manage pseudonyms without the web portal.

The complete description of every endpoint, with its parameters and payloads, is the OpenAPI file [`karnak-api.openapi.yaml`](https://github.com/nroduit/karnak/blob/master/api-collection/karnak-api.openapi.yaml).
A ready-to-use [Postman collection](https://github.com/nroduit/karnak/blob/master/api-collection/karnak-api.postman_collection.json) is available next to it.

## Authentication

The API is stateless: every request carries its own credentials, and no session or cookie of the web portal is used.
The method depends on the [identity provider](../installation#identity-provider):

| Identity provider | Credentials sent with each request |
|-------------------|------------------------------------|
| Built-in account (default) | HTTP Basic authentication with the administrator login and password (`KARNAK_LOGIN_ADMIN` / `KARNAK_LOGIN_PASSWORD`) |
| OpenID Connect (`IDP=oidc`) | An access token of the provider, as `Authorization: Bearer <token>` |

`GET /api/echo/destinations` is the only endpoint that requires no authentication.

## Roles

Each endpoint requires one of the API roles below.
The built-in administrator has all of them.
With OpenID Connect, add the roles to the `karnak` client of the provider and assign them to the account used by the calling system; they are read from the access token like the [portal roles](../installation#identity-provider).

| Role | Grants |
|------|--------|
| `karnak_read` | Read forward nodes, sources, destinations, profiles, projects, secrets and pseudonyms |
| `karnak_search` | Read the monitoring data (transfers, errors, dashboard, CSV export) |
| `karnak_create` | Create forward nodes, destinations, profiles, projects, secrets and pseudonyms |
| `karnak_update` | Update them, and add sources and profile elements |
| `karnak_delete` | Delete them, and clear the monitoring records |

## Endpoints

Responses are JSON (`application/json;version=1`); profiles can also be downloaded and imported as YAML.

| Path | Purpose |
|------|---------|
| `/api/forward-nodes` | [Forward nodes](../userguide/gateway), with their `source-nodes` and `destinations` |
| `/api/profiles` | [Profiles](../userguide/profiles) and their `elements`, YAML `import` and `download` |
| `/api/projects` | [Projects](../userguide/projects) and their `secrets` |
| `/api/pseudonyms` | [External pseudonyms](../userguide/extpseudo) |
| `/api/monitoring` | [Monitoring](../userguide/monitoring) data |
| `/api/echo/destinations` | C-ECHO status of the destinations configured for a source AE Title |

### Bulk pseudonym import {#bulk-pseudonym-import}

`POST /api/pseudonyms/import` {{< since "2.0.1" >}} creates many pseudonyms in one request, from a JSON array of patients with the same fields as the single-create endpoint (`POST /api/pseudonyms`).

```json
[
  { "pseudonym": "PSY_001", "patientId": "PAT_001", "projectUUID": "6f1c…" },
  { "pseudonym": "PSY_002", "patientId": "PAT_002", "issuerOfPatientId": "HOSP", "projectUUID": "6f1c…" }
]
```

Each row is processed independently, so one invalid row does not reject the others.
The request always returns `200` with a summary to inspect for partial failures:

```json
{
  "created": 1,
  "conflict": 1,
  "error": 0,
  "issues": [
    { "index": 1, "reason": "…", "existing": { "pseudonym": "PSY_OLD", "patientId": "PAT_002" } }
  ]
}
```

- **created** — rows stored as new pseudonyms.
- **conflict** — rows whose patient (Patient ID, Issuer of Patient ID and project) already has a pseudonym; `existing` returns the stored one, which is left unchanged.
- **error** — rows that failed validation or reference an unknown project.
- **issues** — one entry per conflicting or failed row, with its 0-based `index` in the request array.

### Delete blockers {#delete-blockers}

A project used by a destination, or a profile used by a project, cannot be deleted {{< since "2.0.1" >}}.
`DELETE` then returns `409 Conflict` with the list of what still uses it, and nothing is modified:

| Request | Blockers listed |
|---------|-----------------|
| `DELETE /api/projects/{uuid}` | The destinations that reference the project, for de-identification or tag morphing |
| `DELETE /api/profiles/{uuid}` | The projects that use the profile |

The same list is available before deleting with `GET /api/projects/{uuid}/delete-blockers` and `GET /api/profiles/{uuid}/delete-blockers`; an empty `blockers` array means the deletion will succeed.
