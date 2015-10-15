#
# Cookbook Name:: serverdensity
# Recipe:: default

include_recipe "serverdensity::install" if node['serverdensity']
