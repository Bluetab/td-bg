#!/bin/sh

set -o errexit
set -o xtrace

bin/td_bg eval 'Elixir.TdBg.Release.migrate()'
bin/td_bg start
