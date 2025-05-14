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
  key_name               = aws_key_pair.my_key.key_name
  count                  = 1


  tags = {
    Name = "ttc-public-instance"
  }

  # für SSM
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}

resource "aws_launch_template" "ttc_ec2_launch_template" {
  name          = "ttc-ec2_launch_template"
  image_id      = var.amazon-linux-2-eu-central-1
  instance_type = "t3.micro"
  key_name      = aws_key_pair.my_key.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  user_data = filebase64("user_data.sh")

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ttc-public-instance"
    }
  }
}

resource "aws_autoscaling_group" "ttc_asg" {
  name                      = "ttc-asg"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = [aws_subnet.public.id]
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ttc_ec2_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ttc-public-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = false
  }
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

resource "aws_iam_policy" "secretsmanager_get_secret_policy" {
  name        = "SecretsManagerGetSecretPolicy"
  description = "Allow access to get secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "secretsmanager:GetSecretValue",
      Resource = ["arn:aws:secretsmanager:eu-central-1:803871200093:secret:openapikey-*",
        "arn:aws:secretsmanager:eu-central-1:803871200093:secret:telegram_api_id-*",
      "arn:aws:secretsmanager:eu-central-1:803871200093:secret:telegram_api_hash-*"]
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}

resource "aws_iam_role_policy_attachment" "attach_secretsmanager_get_secret_policy" {
  role       = aws_iam_role.ttc_ec2_role.name
  policy_arn = aws_iam_policy.secretsmanager_get_secret_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-s3-ssm-profile"
  role = aws_iam_role.ttc_ec2_role.name
}


resource "aws_key_pair" "my_key" {
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


resource "aws_s3_bucket_notification" "bucket_notify" {
  bucket = var.s3_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.ttc_lambda_terminate_ec2.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRestore:Post"]
    filter_suffix       = ".zip"
  }

  depends_on = [aws_lambda_permission.allow_event_notification]
}

resource "aws_lambda_permission" "allow_event_notification" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ttc_lambda_terminate_ec2.function_name
  principal     = "s3.amazonaws.com"
  statement_id  = "AllowExecutionFromS3"
  source_arn    = "arn:aws:s3:::${var.s3_bucket_name}"

}


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

resource "aws_iam_role_policy" "lambda_terminate_ec2_policy" {
  name = "lambda-ec2-terminate-policy"
  role = aws_iam_role.lambda_terminate_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:TerminateInstances"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_lambda_function" "ttc_lambda_terminate_ec2" {
  function_name    = "ttc-lambda-terminate-ec2"
  runtime          = "python3.13"
  role             = aws_iam_role.lambda_terminate_ec2_role.arn
  handler          = "terminateEC2Instance.lambda_handler"
  filename         = "../lambda/terminateEC2Instance.py.zip"
  source_code_hash = filebase64sha256("../lambda/terminateEC2Instance.py.zip")
  timeout          = 30
}


resource "aws_ssm_parameter" "openapi_key" {
  name        = "/ttc-ec2/openapi-key"
  description = "OpenAPI Key"
  type        = "SecureString"
  value       = var.openapi_key
  overwrite   = true
  tags = {
    environment = "prod"
  }
}


resource "aws_ssm_parameter" "telegram_api_id" {
  name        = "/ttc-ec2/telegram-api-id"
  description = "Telegram API Id"
  type        = "SecureString"
  value       = var.telegram_api_id
  overwrite   = true
  tags = {
    environment = "prod"
  }
}


resource "aws_ssm_parameter" "telegram_api_hash" {
  name        = "/ttc-ec2/telegram-api-hash"
  description = "Telegram API Hash"
  type        = "SecureString"
  value       = var.telegram_api_hash
  overwrite   = true
  tags = {
    environment = "prod"
  }
}


resource "aws_ssm_parameter" "phone" {
  name        = "/ttc-ec2/phone"
  description = "Phone Number"
  type        = "SecureString"
  value       = var.phone
  overwrite   = true
  tags = {
    environment = "prod"
  }
}

resource "aws_ssm_parameter" "telegram_password" {
  name        = "/ttc-ec2/telegram-password"
  description = "Telegram 2FA Password"
  type        = "SecureString"
  value       = var.telegram_password
  overwrite   = true
  tags = {
    environment = "prod"
  }
}

resource "aws_ssm_parameter" "input_channel" {
  name        = "/ttc-ec2/input-channel"
  description = "Telegram Input Channel"
  type        = "SecureString"
  value       = var.input_channel
  overwrite   = true
  tags = {
    environment = "prod"
  }
}


resource "aws_ssm_parameter" "output_channel" {
  name        = "/ttc-ec2/output-channel"
  description = "Telegram Output Channel"
  type        = "SecureString"
  value       = var.output_channel
  overwrite   = true
  tags = {
    environment = "prod"
  }
}


resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${var.local_ip_address}/32"]
  security_group_id = aws_security_group.ec2_sg.id
}
