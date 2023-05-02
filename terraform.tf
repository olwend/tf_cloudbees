terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "mpesa-terraform-remote-state-centralised"
    dynamodb_table = "mpesa-terraform-locks-centralised"
    region         = "eu-west-1"
    key            = "mpesa-nap/{{ENV}}/terraform.tfstate"
    kms_key_id     = "arn:aws:kms:eu-west-1:556361159589:key/e3b3311d-2374-4a5b-a734-5180a53439f8"
  }
}