echo "Installing ginkgo"


MOD_GINKGO_RAW=$(go mod edit -json 2> /dev/null | jq '.Require[] | select(.Path | test("^github.com/onsi/ginkgo.*$")) | {(.Path|tostring) : .Version}' -c | sort -t ':' -k2 -Vr | head -n 1)

if [ -n "$MOD_GINKGO_RAW" ]; then
    MOD_GINKGO_GO_STRING=$(echo "$MOD_GINKGO_RAW" | jq -r 'to_entries[] | "\(.key)/ginkgo"')
        echo "installing $MOD_GINKGO_GO_STRING"
        GO111MODULE=on go install "$MOD_GINKGO_GO_STRING"
fi

goenv version
