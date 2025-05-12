variable "region" {
  default = "eu-central-1"
}

variable "amazon-linux-2-eu-central-1" {
  default = "ami-06d4d7b82ed5acff1"
}


variable "s3_bucket_name" {
  default = "telethon-ttc-deploy-bucket"
  type    = string
}
