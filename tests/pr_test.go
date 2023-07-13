// Tests in this file are run in the PR pipeline
package test

import (
	"crypto/rand"
	"encoding/base64"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Use existing resource group
const resourceGroup = "geretain-test-etcd"
const completeExampleTerraformDir = "examples/complete"
const basicExampleTerraformDir = "examples/basic"

// Restricting due to limited availability of BYOK in certain regions
const regionSelectionPath = "../common-dev-assets/common-go-assets/icd-region-prefs.yaml"

func TestRunCompleteExample(t *testing.T) {
	t.Parallel()

	// Generate a 10 char long random string for the admin_pass
	randomBytes := make([]byte, 10)
	_, err := rand.Read(randomBytes)
	randomPass := base64.URLEncoding.EncodeToString(randomBytes)[:10]

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       completeExampleTerraformDir,
		Prefix:             "etcd-complete",
		ResourceGroup:      resourceGroup,
		BestRegionYAMLPath: regionSelectionPath,
		TerraformVars: map[string]interface{}{
			"etcd_version": "3.4", // should always test the latest available version of etcd that the module supports
			"users": []map[string]interface{}{
				{
					"name":     "testuser",
					"password": randomPass, // pragma: allowlist secret
					"type":     "database",
				},
			},
			"admin_pass": randomPass,
		},
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgradeCompleteExample(t *testing.T) {
	t.Parallel()

	// TODO: Remove this line after the first merge to primary branch is complete to enable upgrade test
	t.Skip("Skipping upgrade test until initial code is in primary branch")
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       completeExampleTerraformDir,
		Prefix:             "etcd-complete-upg",
		ResourceGroup:      resourceGroup,
		BestRegionYAMLPath: regionSelectionPath,
		TerraformVars: map[string]interface{}{
			"etcd_version": "3.3", // should always test the lowest available version of etcd that the module supports
		},
	})

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
