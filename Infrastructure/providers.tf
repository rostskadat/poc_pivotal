provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      iac-type = "terraform"
      project  = "pivotal-assessment-poc"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias = "us-east-1"

  default_tags {
    tags = {
      iac-type = "terraform"
      project  = "pivotal-assessment-poc"
    }
  }
}
