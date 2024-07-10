if [[ "${GINKGO_PARAMS}" == *"-label-filters"* ]]; then
  echo "please set label-filters using label_filter_override"
  exit 1
fi

if [ -d test-results ]; then
  rm -rf test-results
fi
mkdir test-results

HAS_LABEL_FILTERS=false
FILTER_LABELS=""
if [[ -n ${LABEL_FILTER_OVERRIDE} ]]; then
  echo "using label filters found in label_filter_override"
  HAS_LABEL_FILTERS=true
  FILTER_LABELS="${LABEL_FILTER_OVERRIDE}"
fi

if [[ -n ${TEST_TYPE} ]]; then
  echo "using focus filters found in test_type"
  if [[ ${HAS_LABEL_FILTERS} == true ]]; then
    echo "ERROR: -label-filters are already set somewhere else"
    exit 1
  fi
  HAS_LABEL_FILTERS=true

  FILTER_LABELS="${TEST_TYPE} && !skip-${ENVIRONMENT}"
fi

if [[ ${HAS_LABEL_FILTERS} == false ]]; then
  echo "no label filters found: please set label filters with test_type or label_filter_override."
fi

echo "running ginkgo with:
  label-filter=${FILTER_LABELS}
  parameters: $GINKGO_PARAMS"
ginkgo version
# shellcheck disable=SC2086
ginkgo $GINKGO_PARAMS -label-filter="${FILTER_LABELS}"
