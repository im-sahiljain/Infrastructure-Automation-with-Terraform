provider "aws" {
  region = "ap-south-1" 
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "aws_key"
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_instance" "example_server" {
  ami           = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  tags = {
    Name = "MyServer"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.example.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",      
      "sudo yum install -y java", 
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo", 
      "sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key", 
      "sudo yum install -y jenkins", 
      "sudo systemctl start jenkins", 
      "sudo systemctl enable jenkins" 
    ]
  }
}


data "external" "jenkins_status" {
  program = ["bash", "${path.module}/jenkins_status.sh", aws_instance.example_server.public_ip, tls_private_key.example.private_key_pem]
}

data "external" "state_maintenance" {
  program = ["bash", "${path.module}/state_maintenance.sh"]
}


output "server_ip" {
  value = aws_instance.example_server.public_ip
}


output "jenkins_status" {
  value = data.external.jenkins_status.result
}


output "state_maintenance" {
  value = data.external.state_maintenance.result
}


terraform {
  backend "s3" {
    bucket = "sahilawsbucket"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

