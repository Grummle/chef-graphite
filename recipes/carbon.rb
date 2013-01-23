python_pip "carbon" do
  version node["graphite"]["version"]
  action :install
end

template "/opt/graphite/conf/carbon.conf" do
  mode "0644"
  source "carbon.conf.erb"
  owner node["apache"]["user"]
  group node["apache"]["group"]
  variables(
    :line_receiver_interface    => node["graphite"]["carbon"]["line_receiver_interface"],
    :pickle_receiver_interface  => node["graphite"]["carbon"]["pickle_receiver_interface"],
    :cache_query_interface      => node["graphite"]["carbon"]["cache_query_interface"],
    :log_updates                => node["graphite"]["carbon"]["log_updates"],
    :data_path                  => node["graphite"]["carbon"]["data_path"] 
  )
  notifies :restart, "service[carbon-cache]"
end

template "/opt/graphite/conf/storage-schemas.conf" do
  mode "0644"
  source "storage-schemas.conf.erb"
  owner node["apache"]["user"]
  group node["apache"]["group"]
  notifies :restart, "service[carbon-cache]"
end

if platform?("centos")
    template "/etc/init.d/carbon-cache" do
            mode "0755"
            source "carbon-cache.erb"
            notifies :restart, "service[carbon-cache]"
    end
end

template "/opt/graphite/conf/storage-aggregation.conf" do
  mode "0644"
  source "storage-aggregation.conf.erb"
  owner node["apache"]["user"]
  group node["apache"]["group"]
  notifies :restart, "service[carbon-cache]"
end

directory "create base storage directory" do
    owner node["apache"]["user"]
    group node["apache"]["group"]
    path node["graphite"]["carbon"]["data_path"]
    recursive true
    action :create
    mode '0755'
end

directory "whisper directory" do
    owner node["apache"]["user"]
    group node["apache"]["group"]
    mode '0755'
    path "#{node["graphite"]["carbon"]["data_path"]}/whisper"
    recursive true
    action :create
end

directory "log directory" do
    owner node["apache"]["user"]
    group node["apache"]["group"]
    mode '0755'
    path "#{node["graphite"]["carbon"]["data_path"]}/log"
    recursive true
    action :create
end

directory "rrd directory" do
    owner node["apache"]["user"]
    group node["apache"]["group"]
    mode '0755'
    path "#{node["graphite"]["carbon"]["data_path"]}/rrd"
    recursive true
    action :create
end

directory "lists directory" do
    owner node["apache"]["user"]
    group node["apache"]["group"]
    mode '0755'
    path "#{node["graphite"]["carbon"]["data_path"]}/lists"
    recursive true
    action :create
end

directory "carbon-cache log directory" do
    owner 'root'
    group 'root'
    mode '0755'
    path "#{node["graphite"]["carbon"]["data_path"]}/log/carbon-cache"
    recursive true
    action :create
end

directory "carbon whisper" do
    owner 'root'
    group 'root'
    mode '0755'
    path "#{node["graphite"]["carbon"]["data_path"]}/whisper/carbon"
    recursive true
    action :create
end

directory "carbon agents" do
    owner 'root'
    group 'root'
    mode '0755'
    path "#{node["graphite"]["carbon"]["data_path"]}/whisper/carbon/agents"
    recursive true
    action :create
end

#execute "chown" do
#  command "chown -R #{node["apache"]["user"]}:#{node["apache"]["group"]} /opt/graphite/storage"
#  only_if do
#    f = File.stat("/opt/graphite/storage")
#    f.uid == 0 && f.gid == 0
#  end
#end

template "/etc/init/carbon-cache.conf" do
  mode "0644"
  source "carbon-cache.conf.erb"
  variables(:user => node["apache"]["user"])
end

logrotate_app "carbon" do
  cookbook "logrotate"
  path "#{node["graphite"]["carbon"]["data_path"]}/log/carbon-cache/carbon-cache-a/*.log"
  frequency "daily"
  rotate 7
  create "644 root root"
end

service "carbon-cache" do
  provider Chef::Provider::Service::Init
  action [ :start ]
end
