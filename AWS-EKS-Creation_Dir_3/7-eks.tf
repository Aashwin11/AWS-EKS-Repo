#Creating a role for EKS to use

resource "aws_iam_role" "eks_aws_iam_role" {
  name = "${local.env}-${local.eks-name}-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

#Attaching required policies to the Above IAM role
resource "aws_iam_role_policy_attachment" "eks_aws_iam_role_policy_attachment" {
  role       = aws_iam_role.eks_aws_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}

#eks cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${local.env}-${local.eks-name}"
  role_arn = aws_iam_role.eks_aws_iam_role.arn
  version  = local.eks-version

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    #The subnet ids are the list that must include the subnets where you plan to launch worker nodes.
    # Genexrally ,worker nodes are launched in private subnets. So most of the time we will be using private subnet ids here.
    subnet_ids = [
      aws_subnet.private_zone_1.id,
      aws_subnet.private_zone_2.id
    ]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
  depends_on = [aws_iam_role_policy_attachment.eks_aws_iam_role_policy_attachment]
}
