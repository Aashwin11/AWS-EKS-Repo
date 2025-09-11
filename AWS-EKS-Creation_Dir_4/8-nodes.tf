  # Create IAM role for EKS worker nodes

resource "aws_iam_role" "nodes_iam_role" {
  name = "${local.env}-${local.eks-name}-nodes-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

#Attaching required policies to the Above IAM role - AmazonEKSWorkerNodePolicy
resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.nodes_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

}

#attaching required policies to the Above IAM role - AmazonEKS_CNI_Policy
resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_2_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.nodes_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

#attaching required policies to the Above IAM role - AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_3_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.nodes_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

#Node group
resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${local.env}-${local.eks-name}-nodes"
  version         = local.eks-version
  node_role_arn   = aws_iam_role.nodes_iam_role.arn
  subnet_ids = [
    aws_subnet.private_zone_1.id,
    aws_subnet.private_zone_2.id
  ]

  capacity_type  = "ON_DEMAND"   #can be SPOT or ON_DEMAND
  instance_types = ["t2.medium"] #can be multiple instance types in a list
  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }
  update_config {
    max_unavailable = 1
  }
  labels = {
    Environment = local.env
    Team        = "DevOps"
    role        = "general"
  }
  depends_on = [aws_iam_role_policy_attachment.aws_iam_role_policy_attachment_AmazonEKSWorkerNodePolicy, aws_iam_role_policy_attachment.iam_role_policy_attachment_2_AmazonEKS_CNI_Policy, aws_iam_role_policy_attachment.iam_role_policy_attachment_3_AmazonEC2ContainerRegistryReadOnly, ]

  #Allow external chanes without Terraform plan
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
