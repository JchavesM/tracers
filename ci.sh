#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o posix

echo '[INFO] Updating dependencies'
poetry update

echo '[INFO] Installing'
poetry install

echo '[INFO] Running tests'
for example in examples/*
do
  echo "[INFO] Running test: ${example}"
  poetry run python "${example}"
done

echo '[INFO] Running code linters'
poetry run prospector --strictness veryhigh --with-tool mypy --without-tool pep257 src
echo '[INFO] Running examples linters'
poetry run prospector --strictness veryhigh --without-tool pep257 examples/*

if test "${1:-}" == 'publish'
then
  version=$(poetry run python -c 'if True:
    import time
    now=time.gmtime()
    minutes_month=(
      (now.tm_mday - 1) * 1440
      + now.tm_hour * 60
      + now.tm_min
    )
    print(time.strftime(f"%y.%m.{minutes_month}"))
  ')

  echo "[INFO] Tagging: ${version}"
  git tag --message "release-${version}" --sign "release-${version}"
  git push origin "release-${version}"

  echo "[INFO] Publishing: ${version}"
  sed -i "s/^version = .*$/version = \"${version}\"/g" pyproject.toml
  trap "sed -i 's/^version = .*$/version = \"1.0.0\"/g' pyproject.toml" EXIT
  poetry publish --build --username "${PYPI_USERNAME}" --password "${PYPI_PASSWORD}"
fi
