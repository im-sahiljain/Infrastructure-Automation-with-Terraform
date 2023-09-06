# Configure AWS provider
provider "aws" {
  region = "ap-south-1" # Change to your desired region
}

# Generate a new SSH key pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
}

# Create an AWS key pair
resource "aws_key_pair" "generated_key" {
  key_name   = "aws_key" # Provide a name for your AWS key pair
  public_key = tls_private_key.example.public_key_openssh
}

# Create EC2 Instance
resource "aws_instance" "example_server" {
  ami           = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  tags = {
    Name = "MyServer"
  }

  # SSH connection information
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.example.private_key_pem
    host        = self.public_ip
  }

  # Provisioner block to install Jenkins
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",      # Update package manager
      "sudo yum install -y java", # Install Java (required for Jenkins)
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo", # Add Jenkins repository
      "sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key", # Import Jenkins GPG key
      "sudo yum install -y jenkins", # Install Jenkins
      "sudo systemctl start jenkins", # Start Jenkins
      "sudo systemctl enable jenkins" # Enable Jenkins to start on boot
    ]
  }
}

# Data blocks for external data sources
data "external" "jenkins_status" {
  program = ["bash", "${path.module}/jenkins_status.sh", aws_instance.example_server.public_ip, tls_private_key.example.private_key_pem]
}

data "external" "state_maintenance" {
  program = ["bash", "${path.module}/state_maintenance.sh"]
}

# Output to Display Server IP
output "server_ip" {
  value = aws_instance.example_server.public_ip
}

# Output to Display Jenkins Status
output "jenkins_status" {
  value = data.external.jenkins_status.result
}

# Output to Display State Maintenance Information
output "state_maintenance" {
  value = data.external.state_maintenance.result
}

# Configure S3 Backend for Terraform State (if not already configured)
terraform {
  backend "s3" {
    bucket = "sahilawsbucket"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

