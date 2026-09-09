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
| **TagMorphingSOPInstanceUID** | SOP Instance UID **after** tag morphing |
| **TagMorphingSeriesInstanceUID** | Series Instance UID **after** tag morphing |
| **ProjectName** | Project name used for de-identification or tag morphing |
| **ProfileName** | Profile name used for de-identification or tag morphing |
| **ProfileCodenames** | Concatenated list of profile items applied during de-identification or tag morphing |

These variables are set (as [MDC](https://logback.qos.ch/manual/mdc.html) values, used with `%X{name}` in a pattern) while a profile is applied to an instance; the `Deidentify*` / `TagMorphing*` values, `ProjectName`, `ProfileName` and `ProfileCodenames` are available on the `DEBUG` event emitted with the `CLINICAL` marker once the profile has been applied. See the [clinical logs](#clinical-logs) example below.

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
      - ./my-logback.xml:/logs/my-logback.xml
    environment:
      LOGBACK_CONFIGURATION_FILE: /logs/my-logback.xml
```

### Using Java

If you run Karnak directly from the JAR file, add the following parameter at startup: `-Dlogging.config=my-logback.xml`

## Default Logback Configuration

The default [logback configuration file](https://github.com/nroduit/karnak/blob/master/src/main/resources/logback.xml) selects its appenders from the active Spring profile:

### Standard installation (Docker or JAR)

* Logs everything at the `INFO` level to the **console** (standard output) only; no log file is written, so no writable volume is needed and the Docker logs can be read with `docker logs` or collected by your log driver
* Log levels can be adjusted with the standard Spring `logging.level.*` properties (e.g. the `LOGGING_LEVEL_ORG_KARNAK=DEBUG` environment variable)

### Portable distribution

* Logs the `org.karnak` packages at the `INFO` level to the console **and** to the rolling file `logs/karnak.log` in the extracted directory
* The rotation is controlled by the `KARNAK_LOGS_MAX_FILE_SIZE` (default `50MB`), `KARNAK_LOGS_MIN_INDEX` (default `1`) and `KARNAK_LOGS_MAX_INDEX` (default `10`) variables set in `run.cfg`

### Clinical logs

Each de-identification or tag-morphing operation emits a `DEBUG` event carrying the `CLINICAL` marker and the [variables](#available-variables) above. The default configuration does not write these events to a dedicated file. To keep an audit trail, add an appender filtered on the marker to your custom configuration and enable the `DEBUG` level for the `org.karnak` package:

```xml
<configuration>
  <appender name="CLINICAL_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>logs/clinical.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.FixedWindowRollingPolicy">
      <fileNamePattern>logs/clinical_%i.log</fileNamePattern>
      <minIndex>1</minIndex>
      <maxIndex>10</maxIndex>
    </rollingPolicy>
    <triggeringPolicy class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy">
      <maxFileSize>50MB</maxFileSize>
    </triggeringPolicy>
    <!-- Keep only the events carrying the CLINICAL marker -->
    <filter class="ch.qos.logback.core.filter.EvaluatorFilter">
      <evaluator class="ch.qos.logback.classic.boolex.OnMarkerEvaluator">
        <marker>CLINICAL</marker>
      </evaluator>
      <onMismatch>DENY</onMismatch>
      <onMatch>NEUTRAL</onMatch>
    </filter>
    <encoder>
      <pattern>%d SOPInstanceUID_OLD=%X{SOPInstanceUID} SOPInstanceUID_NEW=%X{DeidentifySOPInstanceUID} SeriesInstanceUID_OLD=%X{SeriesInstanceUID} SeriesInstanceUID_NEW=%X{DeidentifySeriesInstanceUID} ProjectName=%X{ProjectName} ProfileName=%X{ProfileName} ProfileCodenames=%X{ProfileCodenames}%n</pattern>
    </encoder>
  </appender>

  <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
    <!-- Exclude the clinical events from the console -->
    <filter class="ch.qos.logback.core.filter.EvaluatorFilter">
      <evaluator class="ch.qos.logback.classic.boolex.OnMarkerEvaluator">
        <marker>CLINICAL</marker>
      </evaluator>
      <onMismatch>NEUTRAL</onMismatch>
      <onMatch>DENY</onMatch>
    </filter>
    <encoder>
      <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <logger name="org.karnak" level="DEBUG" />

  <root level="INFO">
    <appender-ref ref="STDOUT" />
    <appender-ref ref="CLINICAL_FILE" />
  </root>
</configuration>
```

With Docker, mount a writable volume for the `logs` folder (the image runs as a non-root user, so mount it at a path such as `/tmp/logs` or make the target directory writable).

> [!INFO]
> Clinical logs provide detailed tracking of the de-identification process, including which profiles were applied and how patient data was transformed. This is useful for auditing and compliance purposes.



