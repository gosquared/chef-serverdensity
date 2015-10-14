# ex: set tabstop=2 shiftwidth=2 expandtab:
#
# Cookbook Name:: serverdensity
# Recipe:: install

require('chef/json_compat')
require 'rest_client'

if node['serverdensity']['agent_key'].nil?
  # no agent key, try to read it out of the
  # file dropped in a Rackspace server
  if File::exist?('/etc/sd-agent-key')
    Chef::Log.info("Agent key file exists")
    agent_key = File.read('/etc/sd-agent-key')
    node.set['serverdensity']['agent_key'] = agent_key
  else
    # No agent key provided, try the API
    include_recipe 'serverdensity::api'
  end
end

case node[:platform]

when "debian", "ubuntu"
  include_recipe "apt"

  apt_repository "serverdensity" do
    key "https://www.serverdensity.com/downloads/boxedice-public.key"
    uri "https://www.serverdensity.com/downloads/linux/deb"
    distributions ["all"]
    components ["main"]
    action :add
  end

  # Update the local package list
  execute "serverdensity-apt-get-update" do
    command "apt-get update"
    action :nothing

  end
end

package "sd-agent" do
  action :install
end

if !node['serverdensity'].respond_to?('to_hash')
  # This is a massive hack so we can get an entire mutable hash out of the attributes in chef 11
  template_variables = Chef::JSONCompat.from_json(node['serverdensity'].to_json)
else
  template_variables = node['serverdensity'].to_hash
end
template_variables['main_plugin_options'] = {}
template_variables['section_plugin_options'] = {}

if !template_variables['plugin_options'].nil? and !template_variables['plugin_options'].empty?
  template_variables['plugin_options'].each_pair do |name, value|
    if value.is_a?(Hash)
      template_variables['section_plugin_options'][name] = value
    else
      template_variables['main_plugin_options'][name] = value
    end
  end
end

# Configure the sd-agent config
template "/etc/sd-agent/config.cfg" do
  source "config.cfg.erb"
  owner "root"
  group "root"
  mode "644"
  variables(template_variables)
  notifies :restart, "service[sd-agent]"
end

service "sd-agent" do
  supports :start => true, :stop => true, :restart => true
  # Starts the service if it's not running and enables it to start at system boot time
  action [:enable, :start]
end
