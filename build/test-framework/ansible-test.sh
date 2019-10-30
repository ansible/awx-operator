#!/bin/sh
export WATCH_NAMESPACE=${TEST_NAMESPACE}
(/usr/local/bin/entrypoint)&
trap "kill $!" SIGINT SIGTERM EXIT

cd ${HOME}/project
exec molecule test -s test-cluster
