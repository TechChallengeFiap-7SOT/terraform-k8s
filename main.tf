provider "aws" {
  region = "us-east-1"
}

variable "cluster_name" {
    default = "fiap"
}

variable "cluster_version" {
    default = "1.22"
}

resource "aws_vpc" "fiap-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "fiap-vpc"
    }
}

resource "aws_internet_gateway" "api-gw" {
    vpc_id = aws_vpc.fiap-vpc.id

    tags = {
        Name = "api-gw"
    }
}

resource "aws_subnet" "private-us-east-1a" {
    vpc_id = aws_vpc.fiap-vpc.id
    cidr_block        = "10.0.0.0/19"
    availability_zone = "us-east-1a"

    tags = {
        "Name" = "private-us-east-1a"
        "kubernetes.io/role/internal-elb" = "1"
        "kubernetes.io/cluster/${var.cluster_name}" = "owner"
    }
}

resource "aws_subnet" "public-us-east-1a" {
    vpc_id = aws_vpc.fiap-vpc.id
    cidr_block              = "10.0.64.0/19"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        "Name" = "public-us-east-1a"
        "kubernetes.io/role/elb" = "1"
        "kubernetes.io/cluster/${var.cluster_name}" = "owner"
    }
}

resource "aws_subnet" "private-us-east-1b" {
    vpc_id = aws_vpc.fiap-vpc.id
    cidr_block        = "10.0.32.0/19"
    availability_zone = "us-east-1b"

    tags = {
        "Name" = "private-us-east-1b"
        "kubernetes.io/role/internal/elb" = "1"
        "kubernetes.io/cluster/${var.cluster_name}" = "owner"
    }
}

resource "aws_subnet" "public-us-east-1b" {
    vpc_id = aws_vpc.fiap-vpc.id
    cidr_block              = "10.0.96.0/19"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true

    tags = {
        "Name" = "public-us-east-1b"
        "kubernetes.io/role/elb" = "1"
        "kubernetes.io/cluster/${var.cluster_name}" = "owner"
    }
}

resource "aws_eip" "nat" {
    vpc = true

    tags = {
        Name = "nat"
    }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public-us-east-1a.id

    tags = {
        Name = "nat"
    }

    depends_on = [aws_internet_gateway.api-gw]
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.fiap-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.fiap-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.api-gw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "private-us-east-1a" {
  subnet_id      = aws_subnet.private-us-east-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-us-east-1b" {
  subnet_id      = aws_subnet.private-us-east-1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-us-east-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-us-east-1b" {
  subnet_id      = aws_subnet.public-us-east-1b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_iam_role" "eks-cluster" {
  name = "eks-cluster-${var.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks-cluster.arn

  vpc_config {

    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    subnet_ids = [
      aws_subnet.private-us-east-1a.id,
      aws_subnet.private-us-east-1b.id,
      aws_subnet.public-us-east-1a.id,
      aws_subnet.public-us-east-1b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.amazon-eks-cluster-policy]
}

resource "aws_iam_role" "eks-fargate-profile" {
  name = "eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_role_policy_attachment" "eks-fargate-profile" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-profile.name
}

resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
    aws_subnet.private-us-east-1a.id,
    aws_subnet.private-us-east-1b.id
  ]

  selector {
    namespace = "kube-system"
  }
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.cluster.id
}

# resource "null_resource" "k8s_patcher" {
#   depends_on = [aws_eks_fargate_profile.kube-system]

#   triggers = {
#     endpoint = aws_eks_cluster.cluster.endpoint
#     ca_crt   = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
#     token    = data.aws_eks_cluster_auth.eks.token
#   }

#   provisioner "local-exec" {
#     command = <<EOH
# cat >/tmp/ca.crt <<EOF
# ${base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)}
# EOF
# kubectl \
#   --server="${aws_eks_cluster.cluster.endpoint}" \
#   --certificate_authority=/tmp/ca.crt \
#   --token="${data.aws_eks_cluster_auth.eks.token}" \
#   patch deployment coredns \
#   -n kube-system --type json \
#   -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
# EOH
#   }

#   lifecycle {
#     ignore_changes = [triggers]
#   }
# }

resource "aws_eks_fargate_profile" "staging" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "staging"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
    aws_subnet.private-us-east-1a.id,
    aws_subnet.private-us-east-1b.id
  ]

  selector {
    namespace = "staging"
  }
}
