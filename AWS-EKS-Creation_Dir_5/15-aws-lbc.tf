# Using Data Block , because the IAM Role already exists . Just using the properties
# Creating Policy for the Pods --- WHO CAN ASSUME THE ROLE WITH THE TRUST POLICY
data "aws_iam_policy_document" "pod_trust_policy" {
  statement {
    actions = ["sts:AssumeRole",
                "sts:TagSession"
                ]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    effect ="Allow"
  }
}

# Creating an IAM Role for the above Policy
resource "aws_iam_role" "aws_lbc"{
    name = "${aws_eks_cluster.eks_cluster.name}-aws-lbc-role"
    assume_role_policy = data.aws_iam_policy_document.pod_trust_policy.json
}

#Creating Policy for defining what all permissions can this Role be given 
resource "aws_iam_policy" "aws_lbc"{
  policy = file("./iam/AWSLoadBalancerController.json")
  name="AWSLoadBalancerController"
}

#Attach the above policy to the IAM Role created for the ALB Controller Pods
resource "aws_iam_role_policy_attachment" "aws_lbc_policy_attach" {
  role       = aws_iam_role.aws_lbc.name
  policy_arn = aws_iam_policy.aws_lbc.arn
}


#Link the IAM Role to the K8 Service Account
resource "aws_eks_pod_identity_association" "example" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-comtroller"
  role_arn        = aws_iam_role.aws_lbc.arn
}

# Helm to deploy controller 
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system" 

  
  version = "1.7.2" 

  # Set values for the Helm chart
  set=[{
    name  = "clusterName"
    value =  aws_eks_cluster.eks_cluster.name #
  }

  ,{
    name  = "serviceAccount.name"
    value = "aws-load-balancer-comtroller" 
  },
  {
    name  = "region"
    value =  local.region
  },
  {
    name  = "vpcId"
    value = aws_vpc.main.id
  }
  
  ]
  depends_on=[helm_release.aws_load_balancer_controller]

}