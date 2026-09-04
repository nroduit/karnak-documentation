---
title: Configuring Logs
weight: 10
description: Configure the logging system in Karnak
---

Karnak offers the possibility of injecting your own log configuration to customize how logs are generated and stored.

The logging system used by Karnak is [Logback](http://logback.qos.ch/). For detailed information about Logback configuration, see the [official manual](http://logback.qos.ch/manual/index.html).

## Available Variables

The following variables can be used in your custom Logback configuration file to capture specific de-identification context:

| Variable | Description |
|----------|-------------|
| **issuerOfPatientID** | Issuer of patient ID **before** de-identification |
| **PatientID** | Patient ID **before** de-identification |
| **SOPInstanceUID** | SOP Instance UID **before** de-identification |
| **DeidentifySOPInstanceUID** | SOP Instance UID **after** de-identification |
| **SeriesInstanceUID** | Series Instance UID **before** de-identification |
| **DeidentifySeriesInstanceUID** | Series Instance UID **after** de-identification |
| **ProjectName** | Project name used for de-identification |
| **ProfileName** | Profile name used for de-identification |
| **ProfileCodenames** | Concatenated list of profile items applied during de-identification |

For usage examples, see the [default Logback configuration](https://github.com/nroduit/karnak/blob/master/src/main/resources/logback.xml#L112-L114).

## Inject the Logback Configuration File

### Using Docker

Set the environment variable `LOGBACK_CONFIGURATION_FILE` with the path to your Logback configuration file. This will override the default log configuration.

**Example:**

If you create a custom configuration file named `my-logback.xml` in the same directory as your `docker-compose.yml`:

1. Create a volume to mount the file inside the Karnak container
2. Define the `LOGBACK_CONFIGURATION_FILE` environment variable with the container path

```yaml
services:
  karnak:
    container_name: karnak
    image: nroduit/karnak:latest
    volumes:
      - ./my-logback.yml:/logs/my-logback.xml
    environment:
      LOGBACK_CONFIGURATION_FILE: /logs/my-logback.xml
```

### Using Java

If you run Karnak directly from the JAR file, add the following parameter at startup: `-Dlogging.config=my-logback.xml`

## Default Logback Configuration

The default [logback configuration file](https://github.com/nroduit/karnak/blob/master/src/main/resources/logback.xml) supports two operating modes:

### Development Mode

* Set the `ENVIRONMENT` variable to `DEV` to activate this mode
* Logs everything at the `INFO` level by default
* Packages `org.karnak` and `org.weasis` are logged at the `DEBUG` level for detailed troubleshooting


### Production Mode

* Active by default (when `ENVIRONMENT` is not set to `DEV`)
* Logs everything at the `WARN` level or higher
* Creates two log files:

#### all.log

Contains:
* All `WARN` level logs and above
* `org.weasis` logs at `INFO` level
* `org.karnak` logs at `INFO` level (excluding clinical logs)

#### clinical.log

Contains:
* All logs marked with the `CLINICAL` marker
* Specifically tracks de-identification operations and clinical data processing

> [!INFO]
> Clinical logs provide detailed tracking of the de-identification process, including which profiles were applied and how patient data was transformed. This is useful for auditing and compliance purposes.



