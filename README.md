# Truedat Business Glossary

TdBG is a back-end service developed as part of the Truedat project that supports the generation of a Business Glossary

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

Install dependencies with `mix deps.get`

To start your Phoenix server:

### Installing

- Create and migrate your database with `mix ecto.create && mix ecto.migrate`
- Start Phoenix endpoint with `mix phx.server`

- Now you can visit [`localhost:4002`](http://localhost:4002) from your browser.

## Running the tests

Run all aplication tests with `mix test`

## Environment variables

### SSL Connection

- `DB_SSL`: Boolean value to enable SSL configuration. Default is `false`.
- `DB_SSL_CACERTFILE`: Path to the Certification Authority (CA) certificate file, e.g. `/path/to/ca.crt`.
- `DB_SSL_VERSION`: Supported versions are `tlsv1.2` and `tlsv1.3`. Default is `tlsv1.2`.
- `DB_SSL_CLIENT_CERT`: Path to the client SSL certificate file.
- `DB_SSL_CLIENT_KEY`: Path to the client SSL private key file.
- `DB_SSL_VERIFY`: Specifies whether server certificates should be verified (`true`/`false`).

### Elastic bulk page size configuration

- BULK_PAGE_SIZE_CONCEPTS: default 500

### Elastic aggregations

- The aggregation variables are defined as follows: AGG\_<AGGREGATION_NAME>\_SIZE

### ElasticSearch authentication

#### (Optional) Basic HTTP authentication

These environment variables will add the Authentication header on each request
with value `Basic <ES_USERNAME>:<ES_PASSWORD>`

- ES_USERNAME: Username
- ES_PASSWORD: Password

#### (Optional) ApiKey authentication

This environment variables will add the Authentication header on each request
with value `ApiKey <ES_API_KEY>`

- ES_API_KEY: ApiKey

#### (Optional) HTTP SSL Configuration (Normally required for ApiKey authentication)

These environment variables will configure CA Certificates for HTTPS requests

- ES_SSL: [true | false] required to activate following options
- ES_SSL_CACERTFILE: (Optional) Indicate the cacert file path. If not set, a certfile will be automatically generated by `:certifi.cacertfile()`
- ES_SSL_VERIFY: (Optional) [verify_peer | verify_none] defaults to `verify_none`

## Deployment

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Built With

- [Phoenix](http://www.phoenixframework.org/) - Web framework
- [Ecto](http://www.phoenixframework.org/) - Phoenix and Ecto integration
- [Postgrex](http://hexdocs.pm/postgrex/) - PostgreSQL driver for Elixir
- [Cowboy](https://ninenines.eu) - HTTP server for Erlang/OTP
- [httpoison](https://hex.pm/packages/httpoison) - HTTP client for Elixir
- [credo](http://credo-ci.org/) - Static code analysis tool for the Elixir language
- [guardian](https://github.com/ueberauth/guardian) - Authentication library
- [canary](https://github.com/cpjk/canary) - Elixir authorization and resource-loading library
- [canada](https://github.com/jarednorman/canada) - Permission definitions in Elixir apps
- [ex_machina](https://hex.pm/packages/ex_machina) - Create test data for Elixir applications

## Authors

- **Bluetab Solutions Group, SL** - _Initial work_ - [Bluetab](http://www.bluetab.net)

See also the list of [contributors](https://github.com/bluetab/td-bg) who participated in this project.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

In order to use this software, it is necessary that, depending on the type of functionality that you want to obtain, it is assembled with other software whose license may be governed by other terms different than the GNU General Public License version 3 or later. In that case, it will be absolutely necessary that, in order to make a correct use of the software to be assembled, you give compliance with the rules of the concrete license (of Free Software or Open Source Software) of use in each case, as well as, where appropriate, obtaining of the permits that are necessary for these appropriate purposes.
