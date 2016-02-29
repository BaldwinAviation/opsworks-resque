#
# Cookbook Name:: opsworks-resque
# Recipe:: default
#
# Copyright (C) 2014 PEDRO AXELRUD
#
# All rights reserved - Do Not Redistribute
#

node[:deploy].each do |application, deploy|

  Chef::Log.info("Configuring resque for application #{application}")

  template "/etc/init/resque-#{application}.conf" do
    source "resque.conf.erb"
    mode '0644'
    variables deploy: deploy
  end
  
  #clean up any existing resque upstart files
  execute "Deleting resque upstart files ... " do
    command "find . -name 'resque-#{application}-*.conf' -delete"
    cwd "/etc/init/"
    action :run
  end

  settings = node[:resque][application]
  # configure rails_env in case of non-rails app
  rack_env = deploy[:rails_env] || settings[:rack_env] || settings[:rails_env]
  settings[:workers].each_with_index do |worker, worker_index|
    queue = worker[0]
    quantity = worker[1]
    quantity.times do |idx|
      idx = idx + 1 # make index 1-based
      template "/etc/init/resque-#{application}-#{worker_index}#{idx}.conf" do
        source "resque-n.conf.erb"
        mode '0644'
        variables application: application, rack_env: rack_env, deploy: deploy, queue: queue, instance: idx
      end
    end
  end
end
