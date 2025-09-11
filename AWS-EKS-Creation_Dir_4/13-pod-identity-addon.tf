# The resource down is responsible that when 
# EKS Control Plane looks at the PodIdentityAssociation mappings that you create via the EKS API (or Terraform's aws_eks_pod_identity_association resource). 
# This is a dedicated, internal record within the EKS service itself. It is not a Kubernetes object like a ConfigMap.

resource "aws_eks_addon" "pod_identity"{
    cluster_name=aws_eks_cluster.eks_cluster.name
    addon_name="eks-pod-identity-agent"
    addon_version="v1.3.8-eksbuild.2"
}