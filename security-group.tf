resource "aws_security_group" "sg" {
  name        = "SG-${var.projectName}"
  description = "EKS Security Group"
  vpc_id      = data.aws_vpc.vpc.id

  # Inbound
  ingress {
    description = "HTTP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    description = "All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
