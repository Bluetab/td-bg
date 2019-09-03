# Changelog

## [3.5.1] 2019-09-03

### Fixed

- [TD-2074] Link count was not calculated correctly
- [TD-2075] Rule count was not reindexed correctly

## [3.5.0] 2019-09-02

### Fixed

- [TD-2059] Return link related actions on hypermedia
- [TD-1428] Format links, multiple fields, enriched text in bg content

## [3.3.0] 2019-08-05

### Added

- [TD-1776] Publish and inform confidential related events
- [TD-1560] Enriched description field in template content

### Changed

- [TD-1985] Type of template field user with an aggregation size of 50
- [TD-2037] Bump cache version due to lack of performance

## [3.2.0] 2019-07-24

### Added

- [TD-1532] Improved linking with data structures, removing integration with td-dd

### Fixed

- [TD-1951] Swagger with phoenix version 1.4.9
- [TD-1687] Delete concept from cache on deprecation and first draft deletion
- [TD-1664] Recover link_count and rule_count in concpet

### Changed

- [TD-1480] Reindex business concept using a background process
- [TD-2002] Update td-cache and remove permissions list from config

## [3.1.0] 2019-07-08

### Added

- [TD-1316] Bulk update endpoint for business concept versions

### Fixed

- [TD-1946] Fixed error indexing concepts pertaining to soft-deleted domains

### Changed

- [TD-1618] Cache improvements (using td-cache instead of td-perms)
- [TD-1942] Use Jason instead of Posion for JSON encoding/decoding

### Removed

- [TD-1917] Remove unused functionality for business concept parent/children and aliases

## [3.0.0] 2019-06-25

### Fixed

- [TD-1893] Use CI_JOB_ID in gitlab ci

## [2.19.0] 2019-05-14

### Fixed

- [TD-1701] Return business concepts non-dynamic content when related template does not exist on csv download
- [TD-1774] Newline is missing in logger format

### Added

- [TD-1519] Initial Redis Loader will write business_concepts parents for migration

## [2.17.1] 2019-04-22

### Changed

- [TD-1705] Search results are ordered by relevance and name by default

## [2.17.0] 2019-04-17

### Changed

- [TD-1529] Search business concept versions now do not return deprecated or different versions of same bc
- [TD-71] Additional functionality for searching concepts filtering by user apability of managing links

## [2.16.0] 2019-04-01

### Added

- [TD-1571] Elixir's Logger config will check for EX_LOGGER_FORMAT variable to override format

## [2.14.0] 2019-03-04

### Added

- [TD-1085] Support filtering on empty values in fields with cardinality `+` or `*`
- [TD-1422] Support for removing stale business concept relations (td_perms 2.14.0)

### Changed

- [TD-1392] Refactor publication of audit events and comments

## [2.13.1] 2019-02-04

### Removed

- [TD-1331] Deleted deprecated tables relating to templates

### Changed

- Revised CSV Upload process:
- It now uses entity helpers to create new concepts instead of hardcoded SQL statments
- Added structural validations before trying to parse and insert values
- Refactor messages for specific internationalization instead of general errors

## [2.12.4] 2019-02-01

### Removed

- Deleted deprecated API endpoints and controller methods (refactored tests that used them)

## [2.12.3] 2019-01-31

### Changed

- Bulk index in batches of 100 items

## [2.12.2] 2019-01-31

### Fixed

- Fixed elastic search mapping to get field on new template model
- REQUIRES REINDEX

## [2.12.1] 2019-01-30

### Fixed

- Fixed query for uploading massive concepts on deleted domain

## [2.12.0] 2019-01-28

### Added

- [TD-1390] Add in cache deprecated business concepts on load

## [2.11.7] 2019-01-10

### Fixed

- [TD-1361] Check permission create_ingest on domain list

## [2.11.6] 2019-01-10

### Fixed

- [TD-1358] The search of the concept chidren of a role in a given domain should be performed over the full string of the field "Full Name"

## [2.11.5] 2019-01-09

### Removed

- [TD-1114] Remove obsolete tables and modules
- Don't include child domains when retrieving linkable structures

## [2.11.4] 2019-01-09

### Fixed

- [TD-1344] Concept count metrics groups by template name

## [2.11.3] 2019-01-08

### Added

- [TD-831] Allow client to specify i18n translations for CSV headers

## [2.11.2] 2019-01-08

### Changed

- [TD-1180] Update audit information when publishing a concept

## [2.11.1] 2019-01-04

### Changed

- [TD-1345] Serves type_label on concepts search rendering

## [2.11.0] 2019-01-03

### Changed

- [TD-1108] Concept name is now case insensitive for duplicity

## [2.10.2] 2018-12-14

### Fixed

- count_bc_in_domain_for_user is controlled by domain's permissions

## [2.10.1] 2018-12-14

### Changed

- New endpoint to query the count of business concepts in a domain filtering by a user name
- Update domain's name in Redis and Elastic when it recieves and update

## [2.10.0] 2018-12-12

### Changed

- [TD-1171] Calculates completeness when perfoming status update actions

## [2.8.6] 2018-12-03

### Added

- [TD-1210] Added endpoint for searching concept filters with conditions

## [2.8.5] 2018-11-23

### Changed

- Added new aggregation to filter the nested list field "domain_parents" in elasticsearch

## [2.8.4] 2018-11-22

### Changed

- Configure Ecto to use UTC datetime for timestamps

## [2.8.3] 2018-11-21

### Changed

- [TD-1076] Write published Business Concept Version parent and children to Redis
- Fault tolerant reindex_all when template no longer exists

## [2.8.2] 2018-11-15

### Changed

- Fix error on reindex while trying to index a deprecated business concept with a deleted parent domain

## [2.8.1] 2018-11-15

### Changed

- Add domains' soft deletion

## [2.8.0] 2018-11-15

### Changed

- Update dependencies (td-perms 2.8.1, td-df-lib 2.8.0)

## [2.7.7] 2018-11-12

### Changed

- Update TD-DF-LIB to validate dependant fields

## [2.7.6] 2018-11-08

### Removed

- Remove migration that drops the deprecated Templates table

## [2.7.5] 2018-11-07

### Changed

- Template fields with no type are now interpreted as type "string"

## [2.7.4] 2018-11-07

### Changed

- Use TdPerms.MockDynamicFormCache instead of TdBg.MockDfCache for DfCache testing

## [2.7.3] 2018-11-06

### Added

- Delete /api/templates endpoint
- /api/domains/#id/templates endpoint now reads from Redis Cache written by Td-Df

## [2.7.1] 2018-10-29

### Added

- Deleting unused endpoints on search controller
- Modify endpoint from /api/search/reindex_all to /api/business_concepts/search/reindex_all
- Verify if the user is admin while calling reindex_all
