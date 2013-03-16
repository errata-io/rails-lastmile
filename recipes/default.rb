#
# Cookbook Name:: rails-bootstrap
# Recipe:: default
#
# Copyright 2013, 119 Labs LLC
#
# See license.txt for details
#
class Chef::Recipe
    # mix in recipe helpers
    include Chef::RubyBuild::RecipeHelpers
end

app_dir = node['rails-lastmile']['app_dir']

service "errata" do
  provider Chef::Provider::Service::Upstart
  supports :restart => true
end

directory "/var/www/errata" do
  owner "root"
  group "root"
  mode "777"
  recursive true
  action :create
end

template "/var/www/errata/index.html" do
  owner "root"
  group "root"
  mode  "644"
  source "index.html"
end

template "/etc/Procfile" do
  owner "root"
  group "root"
  mode  "644"
  source "procfile.erb"
end

file "/var/log/unicorn.log" do
  owner "root"
  group "root"
  mode "666"
  action :create_if_missing
end

template "/etc/unicorn.cfg" do
  owner "root"
  group "root"
  mode "644"
  source "unicorn.erb"
  variables( :app_dir => app_dir)
end

template "/etc/environment" do
  owner "root"
  group "root"
  mode "644"
  source "environment.erb"
  variables( :environment => node['rails-lastmile']['environment'])
end

directory "/root/.foreman/templates/upstart" do
  owner "root"
  group "root"
  mode "777"
  recursive true
  action :create
end

template "/root/.foreman/templates/upstart/master.conf.erb" do
  owner "root"
  group "root"
  mode "644"
  source "master.conf.erb"
end

rbenv_script "run-rails" do
  rbenv_version node['rails-lastmile']['ruby_version']
  cwd app_dir
  code <<-EOT
    bundle install
    bundle exec rake db:migrate
  EOT
end

bash "export-foreman" do
  cwd app_dir
  code <<-EOT
    bundle exec foreman export upstart /etc/init -a errata -u root -d "/vagrant" -f "/etc/Procfile"
  EOT
  notifies :restart, "service[errata]"
end

template "/etc/init/errata-web.conf" do
  owner "root"
  group "root"
  mode "644"
  source "web.conf.erb"
end

template "/etc/nginx/sites-enabled/default" do
  owner "root"
  group "root"
  mode "644"
  source "nginx.erb"
  variables( :static_root => "#{app_dir}/public")
  notifies :restart, "service[nginx]"
end

service "nginx"
