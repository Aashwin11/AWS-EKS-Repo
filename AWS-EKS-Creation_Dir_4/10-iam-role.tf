data "aws_caller_identity" "current" {} #<-- Here, We need AWS account number for IAM role. We can hardcode it, but  
                                        # Better Approach: use Terraform  data resource to dynamically retrieve it. 
                                        # Create IAM role that would give Admin priviledges inside K8 Cluster. 

#Create the EKS Admin IAM Role
resource "aws_iam_role" "eks_admin_role" {
  name = "EKSAdminRole"

  # This policy defines WHO can assume the role.
  # In this case, it's the AWS account root and a specific IAM user.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    # adding trust policy 
    # who all can assume this role
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          # Allows any user in the account to assume the role.
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = "sts:AssumeRole",
      },
    ]
  })

  tags = {
    "Name" = "EKSAdminRole"
  }
}



resource "aws_iam_policy" "eks_admin_policy"{
  name        = "AmazonEksAdminPolicy"


  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },

      #Adding this for security to avoid Permission to Delegate.
      {
        Effect="Allow",
        Action="iam:PassRole",
        Resource="*",
        Condition:{
          "StringEquals":{
            "iam:PassToService":"eks.amazon.com"
          }
        }
        
      }
    ]
  })
}

#attaching role and policy
resource "aws_iam_role_policy_attachment" "eks_admin_role_policy_attachment" {
  role = aws_iam_role.eks_admin_role.name
  policy_arn = aws_iam_policy.eks_admin_policy.arn
}

#Creating user and assuming role
resource "aws_iam_user" "admin_user_manager" {
  name="eks-admin-manager"
}

#create Policy to for the user to assume IAM Role
resource "aws_iam_policy" "iam_user_assume_role_policy" {
  name        = "AmazonEksRoleAssumingtoIamUserPolicy"
  description = "Allows a user to assume the EKSAdminRole"

  # An aws_iam_policy uses a "policy" block, not "assume_role_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole",
        Effect   = "Allow",
        # The Resource is the ARN of the role that can be assumed
        Resource = aws_iam_role.eks_admin_role.arn
      },
    ]
  })
}
#attach policy to that user
resource "aws_iam_user_policy_attachment" "aws_iam_user_ATTACH_iam_user_assume_role_policy" {
  user = aws_iam_user.admin_user_manager.name
  policy_arn = aws_iam_policy.iam_user_assume_role_policy.arn
}

#add the user to the entry access of RBAC
resource "aws_eks_access_entry" "eks_admin_access_entry" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_iam_role.eks_admin_role.arn 
  kubernetes_groups = ["my-admin"]
}