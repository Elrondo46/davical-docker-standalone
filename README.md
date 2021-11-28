# DAViCal Standalone Docker
Docker image for a complete [DAViCal](https://www.davical.org/) server (DAViCal + Apache2 + PostgreSQL) on Alpine Linux requires a separate PGSQL container (watch docker-compose).
The repository on github.org contains example configuration files for DAViCal (as well as the Dockerfile to create the Docker image).
It contains docker-compose config example.

## About DAViCal
[DAViCal](https://www.davical.org/) is a server for shared calendars. It implements the [CalDAV protocol](https://wikipedia.org/wiki/CalDAV) and stores calendars in the [iCalendar format](https://wikipedia.org/wiki/ICalendar).

List of supported clients: Mozilla Thunderbird/Lightning, Evolution, Mulberry, Chandler, iCal, ...

**Features**
>-  DAViCal is Free Software licensed under the General Public License.
>-  uses an PGSQL database for storage of event data
>-  supports backward-compatible access via WebDAV in read-only or read-write mode (not recommended)
>-  is committed to inter-operation with the widest possible CalDAV client software.

  >  DAViCal supports basic delegation of read/write access among calendar users, multiple users or clients reading and writing the same calendar entries over time, and scheduling of meetings with free/busy time displayed.
(*https://www.davical.org/*)

## Settings Added
-  Exposed Ports: TCP 80 and TCP 443
-  Exposed Volumes: /config and /var/lib/postgresql/data/

## Multilanguage Support for Interface
>  -  DAVICAL_LANG is here for this
>  -  Diffrents values for languages: en, ar, de_DE, es_AR, es_ES, es_MX, es_VE, et_EE, fe_FI, fr_FR, hu_HU, it_IT, ja_JP, ko_KR, nb_NO, nl_NL, pl_PL, pt_BR, pt_PT, ru_RU, sk_SK, sv_SE

## Multi Architecture Support
You can use it in ARM, ARM64 and AMD64

