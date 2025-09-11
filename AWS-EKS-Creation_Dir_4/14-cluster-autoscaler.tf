#Create an IAM Role for CLuster AutoScaler
resource "aws_iam_role" "cluster-autoscalar-role"{
    name="${aws_eks_cluster.eks_cluster.name}-cluster-autoscalar-role"

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole",
        "sts:TagSession"]
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      },
    ]
  })
}

#Create policy to the role for all the permissions required 
resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "${aws_eks_cluster.eks_cluster.name}-cluster-autoscaler-policy"
  description = "IAM policy for Kubernetes Cluster Autoscaler"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:PutLifecycleHook",
          "autoscaling:DeleteLifecycleHook",
          "autoscaling:DescribeLifecycleHooks"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach now the policy to the Role
resource "aws_iam_role_policy_attachment" "cluster-autoscaler-role-policy-attachemnt" {
  role       = aws_iam_role.cluster-autoscalar-role.name
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
}

#Attach the role to the CAS Pod Service Account
resource "aws_eks_pod_identity_association" "cluster-autoscaler-pod-identity_-association" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster-autoscalar-role.arn
}


# Helm chart used to release the CLuster Autoscaler

resource "helm_release" "cluster_autoscaler_helm_release" {
  name       = "cluster-autoscaler-helm-release"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  # Combine all values into a single 'set' block
  set = [
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "autoDiscovery.clusterName"
      value = aws_eks_cluster.eks_cluster.name
    },
    {
      name  = "awsRegion"
      value = "us-east-2" # Consider making this dynamic, see note below
    }
  ]

  depends_on = [helm_release.metrics_server]
}