if [[ "${GINKGO_PARAMETERS}" == *"-label-filters"* ]]; then
  echo "please set label-filters using flag_filter_override"
  exit 1
fi

if [ -d test-results ]; then
  rm -rf test-results
fi
mkdir test-results

HAS_LABEL_FILTERS=false
FILTER_FLAGS=""
if [[ -n ${FLAG_FILTER_OVERRIDE} ]]; then
  echo "using label filters found in flag_filter_override"
  HAS_LABEL_FILTERS=true
  FILTER_FLAGS="${FLAG_FILTER_OVERRIDE}"
fi

if [[ -n ${TEST_TYPE} ]]; then
  echo "using focus filters found in test_type"
  if [[ ${HAS_LABEL_FILTERS} == true ]]; then
    echo "ERROR: -label-filters are already set somewhere else"
    exit 1
  fi
  HAS_LABEL_FILTERS=true

  FILTER_FLAGS="${TEST_TYPE} && !skip-${ENVIRONMENT}"
fi

if [[ ${HAS_LABEL_FILTERS} == false ]]; then
  echo "no label filters found: please set label filters with test_type or flag_filter_override."
fi

echo "running ginkgo with label filters: ${FILTER_FLAGS}"
ginkgo version
ginkgo "${GINKGO_PARAMETERS}" -label-filter="${FILTER_FLAGS}"