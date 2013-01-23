include_recipe "apache2::mod_python"

directory "create base storage directory" do
    owner node["apache"]["user"]
    group node["apache"]["group"]
    path node["graphite"]["carbon"]["data_path"]
    recursive true
    action :create
    mode '0755'
end

directory "create log directory" do
    owner node["apache"]["user"]
    group node["apache"]["group"]
    path "#{node["graphite"]["carbon"]["data_path"]}/log/webapp"
    recursive true
    action :create
    mode '0755'
end

[ "error.log", "access.log","exception.log","info.log" ].each do |filename|
  execute "touch #{node["graphite"]["carbon"]["data_path"]}/log/webapp/#{filename}" do
  end
end

[ "exception.log","info.log" ].each do |filename|
  execute "chown #{node["apache"]["user"]}:#{node["apache"]["group"]} #{node["graphite"]["carbon"]["data_path"]}/log/webapp/#{filename}" do
  end
end



if platform?("centos")
        [ "pycairo-devel", "Django", "django-tagging", "python-memcached", "rrdtool-python" ].each do |graphite_package|
          package graphite_package do
            action :install
          end
        end
else
        [ "python-cairo-dev", "python-django", "python-django-tagging", "python-memcache", "python-rrdtool" ].each do |graphite_package|
          package graphite_package do
            action :install
          end
        end
end
   


python_pip "graphite-web" do
  version node["graphite"]["version"]
  action :install
end

template "/opt/graphite/conf/graphTemplates.conf" do
  mode "0644"
  source "graphTemplates.conf.erb"
  owner node["apache"]["user"]
  group node["apache"]["group"]
  notifies :restart, "service[apache2]"
end

template "/opt/graphite/webapp/graphite/local_settings.py" do
  mode "0644"
  source "local_settings.py.erb"
  owner node["apache"]["user"]
  group node["apache"]["group"]
  variables(
    :timezone       => node["graphite"]["dashboard"]["timezone"],
    :memcache_hosts => node["graphite"]["dashboard"]["memcache_hosts"],
    :data_path      => node["graphite"]["carbon"]["data_path"]
  )
  notifies :restart, "service[apache2]"
end



apache_site "000-default" do
  enable false
end

web_app "graphite" do
  template "graphite.conf.erb"
  docroot "/opt/graphite/webapp"
  data_path node["graphite"]["carbon"]["data_path"] 
  server_name "graphite"
end

[ "log", "whisper" ].each do |dir|
  directory "#{node["graphite"]["carbon"]["data_path"]}/#{dir}" do
    owner node["apache"]["user"]
    group node["apache"]["group"]
  end
end

directory "#{node["graphite"]["carbon"]["data_path"]}/log/webapp" do
  owner node["apache"]["user"]
  group node["apache"]["group"]
end

cookbook_file "#{node["graphite"]["carbon"]["data_path"]}/graphite.db" do
  owner node["apache"]["user"]
  group node["apache"]["group"]
  action :create_if_missing
end

logrotate_app "dashboard" do
  cookbook "logrotate"
  path "#{node["graphite"]["carbon"]["data_path"]}/log/webapp/*.log"
  frequency "daily"
  rotate 7
  create "644 root root"
end
