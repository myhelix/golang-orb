# Jobs

## golang/test

Run unit or acceptance tests with ginkgo.

_Note_ this will install the latest version of ginkgo.
For services that depends on hss, see golang/glide-ginkgo.


```yaml
workflows:
  build:
    jobs:
      - golang/test:
          name: "Test"
          context: ci
          test_type: unit

      - golang/test:
          context: development
          name: "Dev Acceptance Test"
          test_type: acceptance
          requires:
            - "Deploy cdk: Development"
          filters:
            branches:
              only: /^feature/.*/
```

## golang/test-parallel

Run unit or acceptance tests with ginkgo.  Allow to set parallelism and split ginkgo test

_Note_ this will install the latest version of ginkgo,
for services that depends on hss, see golang/glide-ginkgo


```yaml
workflows:
  build:
    jobs:
      - golang/test:
          name: "Test"
          context: ci
          test_type: unit
          parallelism: 10

      - golang/test:
          context: development
          name: "Dev Acceptance Test"
          test_type: acceptance
          requires:
            - "Deploy cdk: Development"
          filters:
            branches:
              only: /^feature/.*/
```

## golang/glide-ginkgo

Run unit or acceptance tests on a runner with ginkgo.

This job has ginkgo pinned to: ginkgo@8382b23d18dbaaff8e5f7e83784c53ebb8ec2f47


```yaml
golang_runner_defaults: &golang_runner_defaults
  golang_version: 1.13
  project_name: my-service

workflows:
  build:
    jobs:
      - golang/glide-ginkgo:
          <<: *golang_runner_defaults
          name: "Unit Test"
          test_type: unit
          environment: ci
          go_env: test
          requires:
            - "GooseUp: CI"

      - golang/glide-ginkgo:
          <<: *golang_runner_defaults
          name: "Acceptance Test"
          test_type: acceptance
          environment: ci
          requires:
            - "GooseUp: CI"
```

## golang/gox-build

Use gox to build all go binaries in a directory

These are built with lambda in mind, zipped and stored in an artifacts directory

```yaml
golang_executor_defaults: &golang_executor_defaults
  golang_version_short: 1.15
  project_name: my-service

workflows:
  build:
    jobs:
      - golang/gox-build:
          <<: *golang_executor_defaults
          name: "Build"
          attach_at: /tmp/workspace/
          persist_at: /tmp/workspace/
          context:
            - ci
            - basic

```
