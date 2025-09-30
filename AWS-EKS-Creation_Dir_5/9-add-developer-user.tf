resource "aws_iam_user" "developer_iam_user" {
  name = "developer"
}

resource "aws_iam_policy" "developer_eks" {
    name = "AmazonEKSDeveloperPolicy"
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Required to allow developers to use 'aws eks update-kubeconfig'
          "eks:DescribeCluster",
          "eks:ListClusters",
  
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "developer_eks_iam_policy_attachment" {
  user = aws_iam_user.developer_iam_user.name
  policy_arn = aws_iam_policy.developer_eks.arn

}

resource "aws_eks_access_entry" "developer_access_entry" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_iam_user.developer_iam_user.arn
  kubernetes_groups = ["my-viewer"]
}