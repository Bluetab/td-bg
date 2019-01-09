# Changelog

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
