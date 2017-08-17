require "thor"
require "aws-sdk"

class Vars
  def self.packer_sg_id
    `terraform output -state=terraform-packer/terraform.tfstate packer_sg`.strip
  end

  def self.packer_subnet_id
    `terraform output -state=terraform-packer/terraform.tfstate packer_subnet`.strip
  end

  def self.docker_image_id
    r = Aws::EC2::Client.new.describe_images({ filters: [ {name: "name", values: ["docker-ready"] } ]})
    if r.images.empty?
      return nil
    end
    r.images.first.image_id
  end
end

class Build

end

class BuildCli < Thor
  desc "all", "build the whole thing"
  def all
    packer_vpc()
    image()
    vpc()
  end

  desc "packer_vpc", "step 1, build the packer barebones vpc"
  def packer_vpc
    system "terraform apply -state=terraform-packer/terraform.tfstate terraform-packer"
  end

  desc "image", "step 2, build the packer image"
  def image
    if Vars.docker_image_id.nil?
      system "packer build -var 'subnet_id=#{Vars.packer_subnet_id}' -var security_group_id='#{Vars.packer_sg_id}' packer-templates/docker.json"
    else
      puts "docker-ready image has already been built"
    end
  end

  desc "vpc", "step 3, build out full vpc"
  def vpc
    system "terraform apply -state=terraform-main/terraform.tfstate -var 'docker_ami=#{Vars.docker_image_id}' terraform-main"
  end

  desc "teardown", "blow away the whole thing"
  def teardown
    system "terraform destroy -force -state=terraform-main/terraform.tfstate -var 'docker_ami=#{Vars.docker_image_id}' terraform-main "
    system "terraform destroy -force -state=terraform-packer/terraform.tfstate terraform-packer"
    Aws::EC2::Client.new.deregister_image({image_id: Vars.docker_image_id}) if Vars.docker_image_id
  end
end

BuildCli.start ARGV
