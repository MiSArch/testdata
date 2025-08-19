# MiSArch Testdata

This directory contains scripts to create test data for the MiSArch Experiment Tool.

In the Docker stack this data is created automatically when docker-compose is called.
Note that each time the stack is executed, the test data is created, so it might end up duplicated.

For Kubernetes all scripts must be manually executed from using e.g. `kubectl port-forward`.

## Test Data

- `create-gatling-user.sh` Script to create a user for Gatling tests.
- `get-token.sh` fetches a token for the user created by `create-gatling-user.sh`.
- `create-test-data.sh` Script to creates necessary test data for a MiSArch Buy process, containing a user address, tax rate and a product, which is restocked.