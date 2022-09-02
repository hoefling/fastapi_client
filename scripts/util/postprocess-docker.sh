#! /usr/bin/env bash

set -e
cd /generator-output

CMDNAME=${0##*/}

usage() {
  exitcode="$1"
  cat <<USAGE >&2

Postprocess the output of openapi-generator

Usage:
  $CMDNAME -p PACKAGE_NAME

Options:
  -p, --package-name       The name to use for the generated package
  -h, --help               Show this message
USAGE
  exit "$exitcode"
}

main() {
  validate_inputs
  delete_unused
  fix_any_of
  apply_formatters
}

validate_inputs() {
  if [ -z "$PACKAGE_NAME" ]; then
    echo "Error: you need to provide --package-name argument"
    usage 2
  fi
}

delete_unused() {
  # Delete empty folder
  rm -r "${PACKAGE_NAME}"/test >/dev/null 2>&1 || true

  rm "${PACKAGE_NAME}"/rest.py >/dev/null 2>&1 || true
  rm "${PACKAGE_NAME}"/configuration.py >/dev/null 2>&1 || true
}

fix_any_of() {
  find . -name "*.py" -exec sed -i.bak "s/AnyOf[a-zA-Z0-9]*/Any/" {} \;
  find . -name "*.md" -exec sed -i.bak "s/AnyOf[a-zA-Z0-9]*/Any/" {} \;
  find . -name "*.bak" -exec rm {} \;
}

apply_formatters() {
  autoflake --remove-all-unused-imports --recursive --remove-unused-variables --in-place "${PACKAGE_NAME}" --exclude=__init__.py
  isort --profile=black --float-to-top -p "${PACKAGE_NAME}" -p example "${PACKAGE_NAME}"
  black --fast -l 120 --target-version py36 "${PACKAGE_NAME}"
}

while [ $# -gt 0 ]; do
  case "$1" in
  -p | --package-name)
    PACKAGE_NAME=$2
    shift 2
    ;;
  -h | --help)
    usage 0
    ;;
  *)
    echo "Unknown argument: $1"
    usage 1
    ;;
  esac
done

main
