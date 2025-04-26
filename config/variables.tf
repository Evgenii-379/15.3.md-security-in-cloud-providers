variable "yc_token" {
  description = "y0_AgAAAABT.........................................XRhpk9lgY"
  type        = string
}

variable "yc_cloud_id" {
  description = "b1gt41qe1o37635d6cud"
  type        = string
}

variable "yc_folder_id" {
  description = "b1gt6sro0sp7kjv4dnh1"
  type        = string
}

variable "yc_access_key" {
  description = "S3 Access Key для Object Storage"
  type        = string
}

variable "yc_secret_key" {
  description = "S3 Secret Key для Object Storage"
  type        = string
}

variable "service_account_id" {
  description = "ID сервисного аккаунта для Instance Group"
  type        = string
}


variable "bucket_name" {
  description = "The name of the Object Storage bucket"
  default     = "my-bucket-evgen"
}

variable "region" {
  default = "ru-central1"
}

variable "zone" {
  default = "ru-central1-a"
}

variable "network_name" {
  default = "my-network"
}

variable "subnet_name" {
  default = "my-subnet"
}
