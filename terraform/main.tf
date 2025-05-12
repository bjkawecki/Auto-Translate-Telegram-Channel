resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ttc-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true # Öffenliche IP zuweisen

  tags = {
    Name = "ttc-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ttc-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ttc-public-rt"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ttc-sg-ssm-only"
  }
}

resource "aws_instance" "public" {
  ami                    = var.amazon-linux-2-eu-central-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = file("user_data.sh")
  key_name               = aws_key_pair.dein_key.key_name


  tags = {
    Name = "ttc-public-instance"
  }

  # für SSM
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}

# IAM Rolle für EC2 erstellen
resource "aws_iam_role" "ttc_ec2_role" {
  name = "ttc-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# S3-Lesezugriffs-Policy für EC2-Rolle erstellen
resource "aws_iam_policy" "s3_read_policy" {
  name = "s3-read-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:GetObject"
      ],
      Resource = "arn:aws:s3:::telethon-ttc-deploy-bucket/*"
    }]
  })
}

# AmazonSSMManagedInstanceCore-Policy für EC2-Rolle erstellen
resource "aws_iam_policy" "ssm_policy" {
  name = "ssm-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "ssm:*",
      Resource = "*"
    }]
  })
}

# Policies an die Rolle anhängen
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ttc_ec2_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ttc_ec2_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-s3-ssm-profile"
  role = aws_iam_role.ttc_ec2_role.name
}

# resource "aws_iam_role" "ttc_ec2_role" {
#   name = "ttc-ec2-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ssm_attach" {
#   role       = aws_iam_role.ttc_ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "ttc_ec2_role" {
#   name = "ttc-ec2-role"
#   role = aws_iam_role.ttc_ec2_role.name
# }


resource "aws_key_pair" "dein_key" {
  key_name   = "my-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}


resource "aws_s3_bucket" "deploy_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "Telethon Deployment Bucket"
    Environment = "prod"
  }

  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "deploy_bucket_block" {
  bucket = aws_s3_bucket.deploy_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_iam_role" "ec2_s3_read_role" {
#   name = "ec2-s3-read-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_policy" "s3_read_policy" {
#   name = "s3-read-access"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Action = [
#         "s3:GetObject"
#       ],
#       Resource = "arn:aws:s3:::telethon-ttc-deploy-bucket/*"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_s3_read" {
#   role       = aws_iam_role.ec2_s3_read_role.name
#   policy_arn = aws_iam_policy.s3_read_policy.arn
# }


resource "aws_iam_role" "lambda_terminate_ec2_role" {
  name        = "ttc-lambda-terminate-ec2-role"
  description = "Allows Lambda functions to call terminate ec2 services."

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_ec2_terminate_policy" {
  name = "lambda-ec2-terminate-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ec2:DescribeInstances",
        "ec2:TerminateInstances",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "arn:aws:s3:::telethon-ttc-deploy-bucket/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_terminate_ec2_role.name
  policy_arn = aws_iam_policy.lambda_ec2_terminate_policy.arn
}


resource "aws_lambda_function" "ttc_lambda_terminate_ec2" {
  function_name    = "ttc-lambda-terminate-ec2"
  runtime          = "python3.13"
  role             = aws_iam_role.lambda_terminate_ec2_role.arn
  handler          = "terminateEC2Instance.lambda_handler"
  filename         = "../lambda/terminateEC2Instance.py.zip"
  source_code_hash = filebase64sha256("../lambda/terminateEC2Instance.py.zip")
}


resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/ttc_lambda_terminate_ec2"
  retention_in_days = 7
}
