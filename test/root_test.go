package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestRootModule(t *testing.T) {
	t.Parallel()

	expectedRegion := "us-east-1"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": expectedRegion,
		},
		Vars: map[string]interface{}{
			"name":         "jobtest",
			"cluster_name": "ecs-devxp",
			"cron":         "* * * * ? *",
			"subnets":      []string{},
		},
	})

	// defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	output := terraform.Output(t, terraformOptions, "repository_url")
	// targetGroup := terraform.Output(t, terraformOptions, "default_target_group")
	// targetGroups := terraform.OutputMap(t, terraformOptions, "target_groups")

	assert.Regexp(t, "\\d{12}.dkr.ecr."+expectedRegion+".amazonaws.com/jobtest", output)
	// assert.Regexp(t, "arn:aws:elasticloadbalancing:us-east-1:\\d{12}:targetgroup/module-test-lb-tg/[0-9a-z]{12}", targetGroup)
	// assert.Regexp(t, "arn:aws:elasticloadbalancing:us-east-1:\\d{12}:targetgroup/module-test-api-lb-tg/[0-9a-z]{12}", targetGroups["api"])

}
