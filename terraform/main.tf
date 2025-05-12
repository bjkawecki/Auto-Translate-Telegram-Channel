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

resource "aws_cloudwatch_event_rule" "s3_put_post_rule" {
  name        = "s3-put-post-rule"
  description = "Trigger on S3 PUT/POST events"
  event_pattern = jsonencode({
    source      = ["aws.s3"],
    detail_type = ["AWS API Call via CloudTrail"],
    detail = {
      eventSource = ["s3.amazonaws.com"],
      eventName   = ["PutObject", "PostObject"],
      requestParameters = {
        bucketName = [var.s3_bucket_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_put_post_rule.name
  target_id = "lambda-target"
  arn       = aws_lambda_function.ttc_lambda_terminate_ec2.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ttc_lambda_terminate_ec2.function_name
  principal     = "events.amazonaws.com"
  statement_id  = "AllowExecutionFromEventBridge"
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
