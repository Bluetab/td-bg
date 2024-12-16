# Changelog

## [6.16.0] 2024-12-16

### Added

- [TD-6938] Refactor query builder to use TdCore
- [TD-6888] Support for expandable Concept links
- [TD-6982] Added SSL and ApiKey configuration for Elasticsearch

### Fixed

- [TD-6996] Set lang from assigns locale in business_concept_version_search_view

## [6.15.0] 2024-11-27

### Added

- [TD-6783] Concept searchable in any active language

## [6.14.0] 2024-11-07

### Added

- [TD-6938] Add Concept Search by updated_at as range

### Changed

- [TD-6880] Add Concepts download and upload table type fields for XLSX
- [TD-6938] Refactor Concept Version Controller to move search to new Controller

## [6.13.2] 2024-11-05

### Changed

- [TD-6743] Remove incompatibilities with Elasticsearch v8

## [6.13.1] 2024-10-17

### Fixed

- [TD-6894] Changeset validations overwrite existing content

## [6.13.0] 2024-10-15

### Added

- [TD-6773] Require validation for `table` template fields columns.

### Changed

- [TD-6469] Concept links in browser language
- [TD-6773] Parse numbers from Excel uploads as strings to enable casting in `td-df-lib`.

### Fixed

- [TD-6617] Allow to save concepts in progress:
  - Only takes into account valildation for required information in the concept content.
  - Enable it for bulk upload.
  - Exclude required field errors when concept is in progress in bulk upload.

### Added

- [TD-6817] `td-df-lib` update to validate `user` and `user_group` template fields in business concept version's content.

## [6.10.0] 2024-08-12

- [TD-6735] Automate redis recache for task TD-6689
- [TD-6718] Avoid to save empty values for dynamic content

## [6.9.2] 2024-07-29

### Fixed

- [TD-6734] Update td-df-lib and td-core, add tests for download concepts with visible options

## [6.9.1] 2024-07-26

### Added

- [TD-6733] Update td-df-lib and td-core

## [6.9.0] 2024-07-26

### Added

- [TD-6649] Add Business Concept file manager domain name
- [TD-6689] Add Implementations conditional linked concepts display

### Changed

- [TD-6602] Update td-cache, td-core and td-df-lib
- [TD-6602], [TD-6723] Update td-cache, td-core and td-df-lib
- [TD-6649] Add Business Concept file manager domain name

## [6.8.1] 2024-07-18

### Added

- [TD-6713] Update td-df-lib and td-core

## [6.8.0] 2024-07-03

### Added

- [TD-6499] Add Business Concept content data origin

## [6.7.0] 2024-06-13

### Changed

- [TD-6561] Standardise aggregations limits

### Fixed

- [TD-6561]
  - Standardise aggregations limits
  - Use keyword list for elastic search configuration
- [TD-6402] IndexWorker improvement
- [TD-6440] Fixed Hierarchy bugs

## [6.6.0] 2024-05-21

### Changed

- [TD-6455] Router API for business_concept_user_filters

## [6.5.0] 2024-04-30

### Added

- [TD-6535] Update Td-core for Elasticsearch reindex improvements and fix index deletion by name
- [TD-6492] Update td-df-lib

### Fixed

- [TD-6401] Fixed Content aggregations have a maximum of 10 values
- [TD-6424] Fixed switch on fields aren't translated when uploading and downloading

## [6.4.0] 2024-04-09

### Fixed

- [TD-6507] Add Elastic bulk page size for enviroment vars and update core lib

# [6.3.1] 2024-04-04

### Fixed

- [TD-6507] Add Elastic bulk page size for enviroment vars and update core lib

## [6.3.0] 2024-03-20

### Fixed

- [TD-6350] Fix concepts file upgrade workflow keeping pending approval status
- [TD-6401] Fixed Content aggregations have a maximum of 10 values

### Added

- [TD-6210] Get BC Actions via API
- [TD-4110] Allow structure scoped permissions management

# [6.2.1] 2024-04-04

### Fixed

- [TD-6507] Add Elastic bulk page size for enviroment vars and update core lib

## [6.2.0] 2024-02-26

### Added

- [TD-6243] Support for deleting Elasticsearch indexes
- [TD-6258] Support for I18n in templates

### Fixed

- [TD-6425] Ensure SSL if configured for release migration

## [6.1.1] 2023-02-08

### Fixed

- [TD-6342] Add correct id for delete elasticsearch index

## [6.1.0] 2023-02-08

### Fixed

- [TD-6342] Add missing Elasticsearch.Document Integer implementation (in td-core)

## [6.0.0] 2023-01-17

### Added

- [TD-6336] Get test-truedat-eks config on deploy stage
- [TD-6205] Upload and auto publish of concepts for updating and creating
  from xlsx

### Changed

- [TD-6197] Migrate descriptions to new field in the template

## [5.20.0] 2023-12-19

### Changed

- [TD-6215] Use td-core-lib for elastic search and reindex

## [5.19.0] 2023-11-28

### Changed

- [TD-6124] Download concepts in xlsx format

## [5.18.1] 2023-11-17

## Fixed

- [TD-6191] New Concept Draft notification not being sent

## [5.18.0] 2023-11-13

### Changed

- [TD-6177] Update td-df-lib to fix format field

## [5.17.1] 2023-11-17

## Fixed

- [TD-6191] New Concept Draft notification not being sent

## [5.17.0] 2023-10-31

### Added

- [TD-6103] Allow empty option for domain type filter

## [5.16.0] 2023-10-18

### Fixed

- [TD-6082] Upload csv translation use template fields name instead of labels

## [5.15.0] 2023-10-02

### Added

- [TD-5495] Foreing keys columns should match original ID columns in all tables
- [TD-6071] Updated to Elixir 1.14 and added support for TdCluster

## [5.14.1] 2023-09-20

### Added

- [TD-6025] When a business concept is deprecated, keep data in redis

## [5.14.0] 2023-09-19

### Added

- [TD-5929] Upload csv concepts with fixed template values in browser language

## [5.13.1] 2023-09-14

### Fixed

- [TD-6051] Searchable option for filters

## [5.13.0] 2023-09-05

### Added

- [TD-5928] Allow to publish deprecated concepts

## [5.12.0] 2023-08-16

### Added

- [TD-5891] Download csv i18n support

## Changed

- [TD-5913] Update td-df-lib to fix depends validation

## [5.11.0] 2023-07-24

### Added

- [TD-5872] Add link to concepts in downloaded files

### Changed

- [TD-5844] Concepts CSV dynamic content domain fields: as name instead of external id.

## [5.10.1] 2023-07-10

### Fixed

- [TD-5840] Update td-cache version

## [5.10.0] 2023-07-06

### Added

- [TD-5787] Add multi_match param in elastic query for Boost option
- [TD-5840] Update td-cache reference

### Changed

- [TD-5912] `.gitlab-ci.yml` adaptations for develop and main branches

## [5.9.0] 2023-06-20

### Added

- [TD-5770] Add database TSL configuration
- [TD-5577] Add retrive global filters for default user

## [5.8.0] 2023-06-05

### Added

- [TD-3916] Update td-df-lib version

### Changed

- [TD-5697] Use `HierarchyCache.get_node/1`

## [5.6.0] 2023-05-09

### Added

- [TD-3807] search filters returns types

## [5.5.0] 2023-04-18

### Added

- [TD-5650] Tests for hierarchy bulk uploads
- [TD-5297] Added `DB_SSL` environment variable for Database SSL connection

## [5.4.0] 2023-03-28

### Changed

- [TD-4870] Concept csv download and upload uses unified df_content parsing

## [5.3.0] 2023-03-13

### Changed

- [TD-3879] All `raw keyword` indexing mappings uses empty string as null_value

### Added

- [TD-3806] Hierarchy template cache implementation

## [5.2.0] 2023-02-28

### Added

- [TD-4554] Links and actions to concepts search

## [4.59.0] 2023-01-16

### Added

- [TD-5242] Global filters for Business Concepts
- [TD-3930] includes `completeness` on `BusinessConceptVersion` csv download

## [4.58.1] 2022-12-27

### Added

- [TD-3919] Index business concept version template subscope

## [4.57.0] 2022-12-12

### Added

- [TD-5161] Add actions to create implementations

## [4.56.0] 2022-11-28

### Added

- [TD-5289] Elasticsearch 7 compatibility

## [4.54.0] 2022-10-31

### Changed

- [TD-5284] Phoenix 1.6.x

## [4.53.0] 2022-10-17

### Changed

- [TD-5254] Completeness calculation now considers conditional visibility of
  "switch" fields
- [TD-4857] Completeness calculation now considers ratio of completed visible
  fields rather than completed optional fields
- [TD-5140] Changed implementations ids by implementations refs

## [4.52.0] 2022-10-03

### Added

- [TD-4903] Include `sobelow` static code analysis in CI pipeline

## [4.50.0] 2022-09-05

### Changed

- [TD-5091] Dynamic `domain` fields are now integer ids instead of embedded
  documents

## [4.49.0] 2022-08-16

### Added

- [TD-5043] Add `last_change_at` to business concept versions CSV download

## [4.48.0] 2022-07-26

### Fixed

- [TD-5011] `TemplateCache.list/0` was returning duplicate entries

### Changed

- [TD-3614] Support for access token revocation
- [TD-3584] Allow longer domain descriptions

## [4.46.0] 2022-06-20

### Changed

- [TD-4739] Validate dynamic content for safety to prevent XSS attacks

### Fixed

- [TD-4938] Issue fetching links when implementation has no rule

## [4.45.0] 2022-06-06

### Added

- [TD-4482] Support filtering by `link_tags` instead of `has_links`

## [4.44.0] 2022-05-25

### Added

- [TD-4089] Add abilities for ruleless_implementation when fetching domains

## [4.41.0] 2022-04-04

### Added

- [TD-4666] Enrich business concept search results with `domain_parents`

## [4.40.1] 2022-03-21

### Added

- [TD-4271] Support for linking implementations with business concepts

### Fixed

- [TD-4630] Domain filter was not working correctly

## [4.40.0] 2022-03-14

### Changed

- [TD-2501] Database timeout and pool size can now be configured using
  `DB_TIMEOUT_MILLIS` and `DB_POOL_SIZE` environment variables
- [TD-4461] Avoid reindexing when a domain is modified
- [TD-4491] Refactored search and permissions

## [4.38.0] 2022-02-22

- [TD-4481] Allow to change domain in business concept

## [4.36.0] 2022-01-24

### Added

- [TD-4312]
  - Autogenerated template identifier field
  - Prevent identifier change if a new concept version is created
  - Mapping to search by identifier

## [4.31.0] 2021-11-02

### Added

- [TD-4124] Dependent domain field in td_df_lib

## [4.29.0] 2021-10-04

### Changed

- [TD-4076] `DomainLoader` now force refreshes domain cache when the service
  starts

## [4.28.0] 2021-09-20

### Added

- [TD-3971] Template mandatory dependent field
- [TD-3780] Cache domain `descendent_ids`

### Fixed

- [TD-3780] Missing `domain_ids` in Audit events
- [TD-4037] change the limit on the taxonomy in aggregations

## [4.27.0] 2021-09-07

### Changed

- [TD-3973] Update td-df-lib for default values in swith fields

## [4.25.0] 2021-07-26

### Added

- [TD-3873] Include a specific permission to be able to share a concept with a
  domain

### Fixed

- [TD-3965] Allow domain filtering by view_dashboard permission

## [4.24.0] 2021-07-13

### Modified

- [TD-3878] Concepts only show links to structures for which user has
  view_data_structure permission

### Added

- [TD-3230] Taxonomy aggregations with enriched information

## [4.23.0] 2021-06-28

### Added

- [TD-3720] Add manage_structures_domain permission to domain actions

## [4.22.2] 2021-06-16

### Fixed

- [TD-3868] Unlock td-cache version `4.22.1`

## [4.22.1] 2021-06-15

### Fixed

- [TD-3447] Update td-cache with version `4.22.1`

## [4.22.0] 2021-06-15

### Added

- [TD-3447] Share concept to a group of domains

## [4.21.0] 2021-05-31

### Changed

- [TD-3753] Build using Elixir 1.12 and Erlang/OTP 24
- [TD-3502] Update td-cache and td-df-lib

### Added

- [TD-3446] Aggregation to filter by domain ids

## [4.20.0] 2021-05-17

### Changed

- Security patches from `alpine:3.13`
- Update dependencies

## [4.19.0] 2021-05-04

### Added

- [TD-3628] Force release to update base image

## [4.17.0] 2021-04-05

### Changed

- [TD-3445] Postgres port configurable through `DB_PORT` environment variable

## [4.16.0] 2021-03-22

### Added

- [TD-3173] A non administrator user can to bulk load concepts

## [4.15.0] 2021-03-08

### Change

- [TD-3063] Cache and send on events subscribable fields
- [TD-3341] Build with `elixir:1.11.3-alpine`, runtime `alpine:3.13`

## [4.14.0] 2021-02-22

### Added

- [TD-3265] Version as sub resource of a concept

### Changed

- [TD-3265]:
  - **BREAKING CHANGE** endpoint `/business_concepts_versions/:id` to
    `/business_concepts/:business_concept_id/versions/:id`
  - **BREAKING CHANGE** endpoint `/business_concepts_versions/:id/versions` to
    `/business_concepts/:business_concept_id/versions`
- [TD-3245] Tested compatibility with PostgreSQL 9.6, 10.15, 11.10, 12.5 and
  13.1. CI pipeline changed to use `postgres:12.5-alpine`.

## [4.13.0] 2021-02-08

### Added

- [TD-3263] Use HTTP Basic authentication for Elasticsearch if environment
  variables `ES_USERNAME` and `ES_PASSWORD` are present

### Changed

- [TD-3146] Cache deleted domain ids

## [4.12.0] 2021-01-25

### Added

- [TD-2591] Include the number of related concepts on concept view
- [TD-3164] Service accounts can search business concepts and view domains

### Changed

- [TD-3163] Auth tokens now include `role` claim instead of `is_admin` flag
- [TD-3182] Allow to use redis with password

## [4.11.0] 2021-01-11

### Changed

- [TD-3170] Build docker image which runs with non-root user

### Fixed

- [TD-3155] Verification of duplicated concept names on parent domain change

## [4.10.0] 2020-12-14

### Added

- [TD-2486] Template type `domain`
- [TD-2486] Check new permissions on taxonomy abilties
- [TD-3085] Attribute `domain_parents` on business concept version

## [4.9.0] 2020-11-30

### Added

- [TD-3089] Widget and type `copy` on df

## [4.6.0] 2020-10-19

### Added

- [TD-2485]:
  - Enrich template fields from cache
  - Mappings for system type of templates

## [4.2.0] 2020-08-17

### Added

- [TD-2280] Domain group as independent entity
- [TD-2790] User search filters entity and management

### Changed

- [TD-2280] Reference concepts by external id on domain upload
- [TD-2816] Bulk Update: Validate only specified fields in concept content
- [TD-2849] Current version:
  - Version in `published` status
  - When a concept has not been `published` the last available version

### Fixed

- [TD-2737] Create domain permission ability was checking permissions on parent
  domain making that hypermedia actions did not contain create domain action

## [4.0.0] 2020-07-01

### Fixed

- [TD-2684] check permission `send_business_concept_for_approval` instead of
  `update_concept`
- [TD-2679] Upload of multiple user type fields

### Changed

- [TD-2637] Audit events are now published to a Redis stream
- [TD-2585] Include `domain_ids` in payload of audit events
- [TD-2672] Confidential attribute at Concept level instead of being set at
  business concept version template content
- Update to Phoenix 1.5

### Removed

- Deprecated metrics published for prometheus & grafana

## [3.24.0] 2020-06-15

### Changed

- [TD-2705] In progress is not applied on concepts upload

## [3.23.0] 2020-06-01

### Changed

- [TD-2629] Update td-df-lib to omit template fields of type `image` on indexing
- [TD-2492] Update td-df-lib to include new numeric template types
- [TD-2261] Update cache to retrieve new attribute `deleted_at` from structures

### Fixed

- [TD-2677] Concept id format on `add_link` event

## [3.22.0] 2020-05-18

### Added

- [TD-2490] Permission checks for changing a domain's parent, include
  `parentable_ids` in `/api/domains/:id` response if user can change parent.
- Database pool size is now configurable by using the environment variable
  `DB_POOL_SIZE`. The default value has changed from 10 to 5.

### Removed

- Removed deprecated `related_to` property on business concept versions
- [TD-2608] Empty content fields on concepts bulk update

## [3.20.0] 2020-04-20

### Fixed

- [TD-2500] Issue caching user/role content fields (fixed in `td-cache` 3.20.0)

## [3.19.0] 2020-04-06

### Changed

- [TD-2364] Generate event and reindex concepts when a domain is updated
- [TD-1691] Reindex all concepts on event `add_rule`

## [3.16.0] 2020-02-25

### Added

- [TD-2328] Include `external_id` in domain model and API

## [3.14.0] 2020-01-27

### Changed

- [TD-2269] Update elasticsearch mappings for dynamic content

## [3.10.0] 2019-11-11

### Fixed

- [TD-2164] Put port in swagger url

## [3.8.0] 2019-10-14

### Changed

- [TD-1721] Reindex automatically when a template changes
  - Breaking change: New environment variable `ES_URL` replaces existing
    `ES_HOST`/`ES_PORT`

## [3.7.0] 2019-09-30

### Fixed

- [TD-2084] Update `rule_count` when a rule is removed

### Added

- [TD-1625] Support for df `table` type
- [TD-2084] Reindex concept on rule removal

## [3.6.0] 2019-09-16

### Fixed

- [TD-2078] Default order of Business Concept table by name
- [TD-1625] Omit table field type in bulk upload

### Changed

- [TD-2067] Added sortable normalizer to mappings of business concept domain
  name

## [3.5.1] 2019-09-03

### Fixed

- [TD-2074] Link count was not calculated correctly
- [TD-2075] Rule count was not reindexed correctly
- [TD-2081] Event stream consumer did not respect redis_host and port config
  options

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

- [TD-1532] Improved linking with data structures, removing integration with
  td-dd

### Fixed

- [TD-1951] Swagger with phoenix version 1.4.9
- [TD-1687] Delete concept from cache on deprecation and first draft deletion
- [TD-1664] Recover link_count and rule_count in concept

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

- [TD-1917] Remove unused functionality for business concept parent/children and
  aliases

## [3.0.0] 2019-06-25

### Fixed

- [TD-1893] Use CI_JOB_ID in gitlab ci

## [2.19.0] 2019-05-14

### Fixed

- [TD-1701] Return business concepts non-dynamic content when related template
  does not exist on csv download
- [TD-1774] Newline is missing in logger format

### Added

- [TD-1519] Initial Redis Loader will write business_concepts parents for
  migration

## [2.17.1] 2019-04-22

### Changed

- [TD-1705] Search results are ordered by relevance and name by default

## [2.17.0] 2019-04-17

### Changed

- [TD-1529] Search business concept versions now do not return deprecated or
  different versions of same bc
- [TD-71] Additional functionality for searching concepts filtering by user
  apability of managing links

## [2.16.0] 2019-04-01

### Added

- [TD-1571] Elixir's Logger config will check for `EX_LOGGER_FORMAT` variable to
  override format

## [2.14.0] 2019-03-04

### Added

- [TD-1085] Support filtering on empty values in fields with cardinality `+` or
  `*`
- [TD-1422] Support for removing stale business concept relations (td_perms
  2.14.0)

### Changed

- [TD-1392] Refactor publication of audit events and comments

## [2.13.1] 2019-02-04

### Removed

- [TD-1331] Deleted deprecated tables relating to templates

### Changed

- Revised CSV Upload process:
- It now uses entity helpers to create new concepts instead of hardcoded SQL
  statements
- Added structural validations before trying to parse and insert values
- Refactor messages for specific internationalization instead of general errors

## [2.12.4] 2019-02-01

### Removed

- Deleted deprecated API endpoints and controller methods (refactored tests that
  used them)

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

- [TD-1358] The search of the concept chidren of a role in a given domain should
  be performed over the full string of the field "Full Name"

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

- New endpoint to query the count of business concepts in a domain filtering by
  a user name
- Update domain's name in Redis and Elastic when it recieves and update

## [2.10.0] 2018-12-12

### Changed

- [TD-1171] Calculates completeness when perfoming status update actions

## [2.8.6] 2018-12-03

### Added

- [TD-1210] Added endpoint for searching concept filters with conditions

## [2.8.5] 2018-11-23

### Changed

- Added new aggregation to filter the nested list field `domain_parents` in
  elasticsearch

## [2.8.4] 2018-11-22

### Changed

- Configure Ecto to use UTC datetime for timestamps

## [2.8.3] 2018-11-21

### Changed

- [TD-1076] Write published Business Concept Version parent and children to
  Redis
- Fault tolerant reindex_all when template no longer exists

## [2.8.2] 2018-11-15

### Changed

- Fix error on reindex while trying to index a deprecated business concept with
  a deleted parent domain

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

- Use `TdPerms.MockDynamicFormCache` instead of `TdBg.MockDfCache` for DfCache
  testing

## [2.7.3] 2018-11-06

### Added

- Delete `/api/templates` endpoint
- `/api/domains/:id/templates` endpoint now reads from Redis Cache written by
  td-df

## [2.7.1] 2018-10-29

### Added

- Deleting unused endpoints on search controller
- Modify endpoint from `/api/search/reindex_all` to
  `/api/business_concepts/search/reindex_all`
- Verify if the user is admin while calling reindex_all
