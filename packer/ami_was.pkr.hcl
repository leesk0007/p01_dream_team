# packer/ami_was.pkr.hcl

packer {
    # packer로 aws에 접속해서 작업하기 위한 플러그인
    required_plugins {
        amazon = {
            version = ">= 1.2.8"
            source = "github.com/hashicorp/amazon"
        }
        # packer로 ansible을 이용해서 AMI에 패키지를 설치를 할 수 있도록 설정
        ansible = {
            version = ">= 1.1.0"
            source = "github.com/hashicorp/ansible"
        }
    }
}

# 우리가 만든 ami 이미지는 aws의 ebs에 저장이된다
source "amazon-ebs" "project01_was_ami" {
    ami_name = "project01-was-ami-{{timestamp}}"
    instance_type = "t3.micro"
    region = "ap-northeast-2"
    source_ami = "ami-0b6cacee0430cdb2c" # 아마존 리눅스 최신 버전
    ssh_username = "ec2-user"
}

#build 정보
build {

    sources = ["source.amazon-ebs.project01_was_ami"]
    # ansible을 이용해서 nginx를 셋팅합니다

    provisioner "ansible" {
        playbook_file = "../ansible/playbooks/packer_was.yml"
        user = "ec2-user"
        use_proxy = false
        ansible_env_vars = [
        "ANSIBLE_CONFIG=../ansible/ansible.cfg" # ROLE 위치 명시
        ]
    }
}