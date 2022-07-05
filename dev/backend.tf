terraform {
  backend "s3" {
    bucket  = "mohit-angi-test-infra"
    key     = "dev/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
