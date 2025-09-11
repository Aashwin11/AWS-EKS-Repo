#PRIVATE SUBNET
resource "aws_subnet" "private_zone_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = local.zone1
  tags = {
    Name                                      = "${local.env}-private-subnet-{local.zone1}"
    "kubernetes.io/role/internal-elb"         = "1"     #special tag used by EKS for Private Load Balancers  in case we want to expose our service internall within VPC
    "kubernetes.io/cluster/${local.eks-name}" = "owned" # to provision multiple EKS cluster in same AWS account
  }
}

resource "aws_subnet" "private_zone_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = local.zone2
  tags = {
    Name                                      = "${local.env}-private-subnet-{local.zone2}"
    "kubernetes.io/role/internal-elb"         = "1"     #special tag used by EKS for Private Load Balancers  in case we want to expose our service internall within VPC
    "kubernetes.io/cluster/${local.eks-name}" = "owned" # to provision multiple EKS cluster in same AWS account
  }
}


#PUBLIC SUBNET
resource "aws_subnet" "public_zone_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.32.0/24"
  availability_zone       = local.zone1
  map_public_ip_on_launch = true


  tags = {
    Name                                                   = "${local.env}-public-subnet-{local.zone1}"
    "kubernetes.io/role/elb"                               = "1"     #special tag used by EKS for Public Load Balancers
    "kubernetes.io/cluster/${local.env}-${local.eks-name}" = "owned" # to provision multiple EKS cluster in same AWS account
  }
}

resource "aws_subnet" "public_zone_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/24"
  availability_zone       = local.zone2
  map_public_ip_on_launch = true


  tags = {
    Name                                                   = "${local.env}-public-subnet-{local.zone2}"
    "kubernetes.io/role/elb"                               = "1"     #special tag used by EKS for Public Load Balancers
    "kubernetes.io/cluster/${local.env}-${local.eks-name}" = "owned" # to provision multiple EKS cluster in same AWS account
  }
}

