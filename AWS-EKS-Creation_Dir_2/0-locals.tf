locals {
  env         = "staging"
  region      = "us-east-2"
  zone1       = "us-east-2a"
  zone2       = "us-east-2b"
  eks-name    = "eks-demo"
  eks-version = "1.33" # EKS version -LATEST SUPPORTED K8 version in AWS
}
