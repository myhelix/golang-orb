if [[ -z ${GO_ENV} ]]; then
  echo "export GO_ENV=${ENVIRONMENT}" >> "$BASH_ENV"
else
  echo "export GO_ENV=${GO_ENV}" >> "$BASH_ENV"
fi