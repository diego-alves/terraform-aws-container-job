# Tests

This folder contains automated tests for this Module. All of the tests are written in [Go](https://golang.org) using a helper library called [Terratest](https://github.com/gruntwork-io/terratest).

## Running the tests

### Prerequisites

- Install the latest version of [Go](https://golang.org/doc/install).
- Install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).
- Configure your AWS credentials using one of the [options supported by the AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).
  > Usually, the easiest option is to set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.

### One-time setup

Download Go dependencies using dep:

```bash
cd test
go mod download
```

### Run all the tests

```bash
go test -v -timeout 60m
```

### Run a specific test

```bash
go test -v -timeout 60m -test.run TestTerraformBasicExample
```