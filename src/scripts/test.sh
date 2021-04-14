#!/usr/bin/env bash
set -e

if [[ -n "${1}" ]]
then
        TEST_TYPE=${1}
fi

if [[ ${TEST_TYPE} != "acceptance" ]] && [[ ${TEST_TYPE} != "unit" ]]
then
  printf "Runs acceptance or unit tests\n\n"
  printf "Usage:\n"
  printf "./test.sh [acceptance|unit] <-o>\n"
  exit 1
fi

# Set test run type.
[[ ${TEST_TYPE} == "acceptance" ]] && IS_ACCEPTANCE=1 || IS_ACCEPTANCE=0

# Get if this is a local run.
[[ $(uname) == "Darwin" ]] && IS_LOCAL=1 || IS_LOCAL=0

# Set GO111MODULE if go.mod file exists.
[[ -f go.mod ]] && export GO111MODULE=on

COVER_FILE=cover.out
COVERAGE_OUTPUT_DIRECTORY=coverage
RESULTS_OUTPUT_DIRECTORY=test-results
OUTPUT_FILE=${COVERAGE_OUTPUT_DIRECTORY}/${COVER_FILE}
OUTPUT_HTML_FILE=${COVERAGE_OUTPUT_DIRECTORY}/cover.html
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-30}
TEST_PARALLELISM=${TEST_PARALLELISM:-4}
TEST_TIMEOUT=${TEST_TIMEOUT:-5}
GINKGO_EXTRA_FLAGS=()
GINKGO_TEST_PACKAGE="./..."
REGEX_FLAG=""
SED_FLAGS=()

if [[ ${IS_LOCAL} == 1 ]]
then
  REGEX_FLAG=-E
  SED_FLAGS=(-i .bak "${REGEX_FLAG}")
else
  REGEX_FLAG=-r
  SED_FLAGS=(-i.bak "${REGEX_FLAG}")
  GINKGO_EXTRA_FLAGS=(-failFast \
    -keepGoing \
    -nodes "${TEST_PARALLELISM}" \
    -randomizeAllSpecs \
    -randomizeSuites \
    -timeout "${TEST_TIMEOUT}m")
fi

if [[ ${IS_ACCEPTANCE} == 1 ]]
then
  GINKGO_TEST_PACKAGE="acceptance"
else
  # Unit tests should cover and skip all tests in ./acceptance.
  GINKGO_EXTRA_FLAGS+=(-cover \
    -coverprofile "${COVER_FILE}" \
    -skipPackage acceptance)

  # Cleanup previous run.
  rm -rf ${COVERAGE_OUTPUT_DIRECTORY} ${RESULTS_OUTPUT_DIRECTORY}
  mkdir -p ${COVERAGE_OUTPUT_DIRECTORY} ${RESULTS_OUTPUT_DIRECTORY}
fi

ginkgo \
  -progress \
  -r \
  -race \
  -requireSuite \
  -trace \
  -v \
  "${GINKGO_EXTRA_FLAGS[@]}" \
  "${GINKGO_TEST_PACKAGE}"

if [[ ${IS_ACCEPTANCE} == 0 ]]
then
  # Get all packages.
  while IFS='' read -r line; do PACKAGES+=("$line"); done < <(go list -f '{{.Dir}}' ./... | sed ${REGEX_FLAG} "s%$(pwd)/?%%g")

  # Combine the code coverage for each package.
  echo "mode: atomic" > ${OUTPUT_FILE}
  for package in "${PACKAGES[@]}"
  do
    if [[ -f ${package}/${COVER_FILE} ]]
    then
      tail -n +2 "${package}/${COVER_FILE}" >> ${OUTPUT_FILE}
      echo "" >> ${OUTPUT_FILE}
      rm "${package}/${COVER_FILE}"
    fi
  done

  # Move all the test results to test-results/${package}/
  for package in "${PACKAGES[@]}"
  do
    for file in "${package}"/junit*.xml
    do
      if [[ -f ${file} ]]
      then
        mkdir -p "${RESULTS_OUTPUT_DIRECTORY}/${package}"
        mv "${package}"/junit*.xml ${RESULTS_OUTPUT_DIRECTORY}/"${package}"
      fi
    done
  done

  # Remove code coverage lines with main.go or mock.go since we don't want to
  # include those in code coverage. Also remove blank lines.
  sed "${SED_FLAGS[@]}" '/.+\/(main|mocks?)\.go:.+/d' ${OUTPUT_FILE}
  sed "${SED_FLAGS[@]}" '/^\s*$/d' ${OUTPUT_FILE}
  # Temporarily remove copypasted jwt.go code
  sed "${SED_FLAGS[@]}" '/.+\/jwt\.go:.+/d' ${OUTPUT_FILE}
  rm ${OUTPUT_FILE}.bak

  # Generate the overall code coverage in both HTML and function report form.
  go tool cover -html=${OUTPUT_FILE} -o ${OUTPUT_HTML_FILE}
  cover_output=$(go tool cover -func=${OUTPUT_FILE})
  echo "${cover_output}"

  # Open coverage file if flag supplied and is local run.
  if [[ "$2" == "-o" && ${IS_LOCAL} ]]
  then
    open ${OUTPUT_HTML_FILE}
  fi

  # Get the overall code coverage and check it against the threshold.
  # Note coverage excludes files that are entirely untested from the calculation.
  total_regex=".+\(statements\)[[:space:]]+([[:digit:]]+\.[[:digit:]]+)%$"
  if [[ ${cover_output} =~ ${total_regex} ]]
  then
    total_cover_percent=${BASH_REMATCH[1]}
  fi

  if (( $(echo "${total_cover_percent} >= ${COVERAGE_THRESHOLD}" | bc -l) ))
  then
    echo "current coverage (${total_cover_percent}) meets threshold (${COVERAGE_THRESHOLD})"
  else
    echo "current coverage (${total_cover_percent}) does not meet threshold (${COVERAGE_THRESHOLD})"
  fi
fi
