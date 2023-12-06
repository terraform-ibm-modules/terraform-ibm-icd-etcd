// Tests in this file are run in the PR pipeline
package test

import (
	"crypto/rand"
	"encoding/base64"
	"log"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Use existing resource group
const resourceGroup = "geretain-test-etcd"
const completeExampleTerraformDir = "examples/complete"
const basicExampleTerraformDir = "examples/basic"
const fsCloudExampleTerraformDir = "examples/fscloud"

// Restricting due to limited availability of BYOK in certain regions
const regionSelectionPath = "../common-dev-assets/common-go-assets/icd-region-prefs.yaml"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

func TestMain(m *testing.M) {

	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func TestRunFSCloudExample(t *testing.T) {
	t.Parallel()
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: fsCloudExampleTerraformDir,
		Prefix:       "etcd-fscloud",
		Region:       "us-south", // For FSCloud locking into us-south since that is where the HPCS permanent instance is
		/*
		 Comment out the 'ResourceGroup' input to force this test to create a unique resource group to ensure tests do
		 not clash. This is due to the fact that an auth policy may already exist in this resource group since we are
		 re-using a permanent HPCS instance. By using a new resource group, the auth policy will not already exist
		 since this module scopes auth policies by resource group.
		*/
		//ResourceGroup: resourceGroup,
		TerraformVars: map[string]interface{}{
			"access_tags":                permanentResources["accessTags"],
			"existing_kms_instance_guid": permanentResources["hpcs_south"],
			"kms_key_crn":                permanentResources["hpcs_south_root_key_crn"],
			"etcd_version":               "3.5", // Always lock this test into the latest supported etcd version
		},
	})
	options.SkipTestTearDown = true
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

	// check if outputs exist
	outputs := terraform.OutputAll(options.Testing, options.TerraformOptions)
	expectedOutputs := []string{"port", "hostname"}
	_, outputErr := testhelper.ValidateTerraformOutputs(outputs, expectedOutputs...)
	assert.NoErrorf(t, outputErr, "Some outputs not found or nil")
	options.TestTearDown()
}
func TestRunCompleteUpgradeExample(t *testing.T) {
	t.Parallel()

	// Generate a 15 char long random string for the admin_pass
	randomBytes := make([]byte, 13)
	rand.Read(randomBytes)
	randomPass := "A1" + base64.URLEncoding.EncodeToString(randomBytes)[:13]

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       completeExampleTerraformDir,
		Prefix:             "etcd-upg",
		ResourceGroup:      resourceGroup,
		BestRegionYAMLPath: regionSelectionPath,
		TerraformVars: map[string]interface{}{
			"etcd_version": "3.3", // should always test the lowest available version of etcd that the module supports
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

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
