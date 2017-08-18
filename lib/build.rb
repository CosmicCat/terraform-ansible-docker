require "thor"
require "aws-sdk"
require "mysql2"

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

  def self.maria_endpoint
    `terraform output -state=terraform-main/terraform.tfstate maria_endpoint`.strip
  end

  def self.manager_ip
    `terraform output -state=terraform-main/terraform.tfstate docker_manager_ip`.strip
  end

  def self.worker1_ip
    `terraform output -state=terraform-main/terraform.tfstate docker_worker_ip1`.strip
  end

  def self.worker2_ip
    `terraform output -state=terraform-main/terraform.tfstate docker_worker_ip2`.strip
  end

  def self.elb_endpoint
    `terraform output -state=terraform-main/terraform.tfstate elb_endpoint`.strip
  end
end

class Maria
  PASS = "supersecure"
  USER = "test"
  def initialized?
    c = Mysql2::Client.new(:host => Vars.maria_endpoint, :username => "test", :password => "supersecure")
    c.query("use vacasa;")
    return true;
  rescue Mysql2::Error
    return false
  end
  
  def populate
    puts "Initializing rds at: #{Vars.maria_endpoint}"
    if initialized?
      puts "db is already initialized"
    else
      puts "running this sql: #{File.read("initdb.sql")}"
      system "mysql -h #{Vars.maria_endpoint} -u test --password=supersecure < initdb.sql"
    end
  end
end

class ManageSwarm
  def generate_inventory
    File.write("hosts", <<HERE)
[swarm-manager]
#{Vars.manager_ip}
[swarm-workers]
#{Vars.worker1_ip}
#{Vars.worker2_ip}
HERE
  end

  def init_swarm
    generate_inventory
    clean
    token = init_manager
    join_workers_to_swarm(token)
    deploy_app
  end

  def clean
    # for now, drop the cluster and start over for simplicity
    system "ansible all -become -i hosts -a 'docker swarm leave -f' -u ubuntu"
  end
  
  def init_manager
    out = `ansible swarm-manager -become -i hosts -a "docker swarm init --advertise-addr #{Vars.manager_ip}" -u ubuntu`
    token = out.match(/join --token (\S+) /)
    raise "could not find token in '#{out}'" if token.nil?
    token[1]
  end
  
  def join_workers_to_swarm(token)
    system "ansible swarm-workers -become -i hosts -a 'docker swarm join --token #{token} #{Vars.manager_ip}:2377' -u ubuntu"
  end

  def deploy_app
    system("ansible swarm-manager -become -i hosts -a 'docker service create --publish 8080:80 --env MARIA=#{Vars.maria_endpoint} --replicas=2 --name hello cosmiccat/php-code-challenge' -u ubuntu")
  end
end

class BuildCli < Thor
  desc "all", "build the whole thing"
  def all
    image()
    vpc()
    database()
    swarm()
    endpoints()
  end

  desc "image", "build docker-ready ami using packer"
  def image
    if Vars.docker_image_id.nil?
      system "terraform apply -state=terraform-packer/terraform.tfstate terraform-packer"
      system "packer build -var 'subnet_id=#{Vars.packer_subnet_id}' -var security_group_id='#{Vars.packer_sg_id}' packer-templates/docker.json"
      system "terraform destroy -force -state=terraform-packer/terraform.tfstate terraform-packer"
    else
      puts "docker-ready image has already been built"
    end
  end

  desc "vpc", "build out full infrastructure using terraform"
  def vpc
    system "terraform apply -state=terraform-main/terraform.tfstate -var 'docker_ami=#{Vars.docker_image_id}' terraform-main"
  end

  desc "teardown", "blow away the whole thing"
  def teardown
    system "terraform destroy -force -state=terraform-main/terraform.tfstate -var 'docker_ami=#{Vars.docker_image_id}' terraform-main "
    Aws::EC2::Client.new.deregister_image({image_id: Vars.docker_image_id})
  end

  desc "database", "populate mariadb with tables/data"
  def database
    Maria.new.populate
  end

  desc "swarm", "initialize the docker swarm using ansible"
  def swarm
    ManageSwarm.new.init_swarm
  end

  desc "endpoints", "display the endpoints after everything is built"
  def endpoints
    puts "manager: #{Vars.manager_ip}"
    puts "worker1: #{Vars.worker1_ip}"
    puts "worker2: #{Vars.worker2_ip}"
    puts "maria: #{Vars.maria_endpoint}"
    puts "elb: #{Vars.elb_endpoint}"
  end

end

`export ANSIBLE_HOST_KEY_CHECKING=False`
BuildCli.start ARGV
