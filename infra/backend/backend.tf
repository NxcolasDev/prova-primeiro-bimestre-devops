variable "bucket_name" {
  description = "Nome unico global do bucket S3 para armazenar o tfstate"
  type        = string
  default     = "tech-nova-tfstate-6325171"
}

provider "aws" {
  region = "us-east-1"
}

# 1. Cria o Bucket S3 via AWS CLI (contorna restricao de ObjectLock do Learner Lab)
resource "terraform_data" "create_s3_bucket" {
  triggers_replace = [var.bucket_name]

  provisioner "local-exec" {
    command     = "aws s3api create-bucket --bucket ${var.bucket_name} --region us-east-1 || true"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws s3api list-object-versions --bucket tech-nova-tfstate-6325171 \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json \
        | xargs -I{} aws s3api delete-objects --bucket tech-nova-tfstate-6325171 --delete '{}' 2>/dev/null || true
      aws s3 rm s3://tech-nova-tfstate-6325171 --recursive 2>/dev/null || true
      aws s3api delete-bucket --bucket tech-nova-tfstate-6325171 --region us-east-1 2>/dev/null || true
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# 2. Habilita Versionamento no Bucket
resource "terraform_data" "enable_versioning" {
  depends_on = [terraform_data.create_s3_bucket]

  provisioner "local-exec" {
    command     = "aws s3api put-bucket-versioning --bucket ${var.bucket_name} --versioning-configuration Status=Enabled --region us-east-1"
    interpreter = ["/bin/bash", "-c"]
  }
}

# 3. Tabela DynamoDB para State Locking
resource "aws_dynamodb_table" "tflock" {
  name         = "tech-nova-tflocks-6325171"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "tech-nova-tflocks"
  }
}
