#!/bin/bash /etc/rc.common
. /lib/functions.sh

REAL_LOG="/usr/share/clash/clash_real.txt"
lang=$(uci get luci.main.lang 2>/dev/null)
config_type=$(uci get clash.config.config_type 2>/dev/null)
create=$(uci get clash.config.create 2>/dev/null)
load_from=$(uci get clash.config.loadfrom 2>/dev/null)
config_name=$(uci get clash.config.create_tag 2>/dev/null)
CONFIG_YAML="/usr/share/clash/config/custom/${config_name}.yaml" 
check_name=$(grep -F "${config_name}.yaml" "/usr/share/clashbackup/create_list.conf") 
same_tag=$(uci get clash.config.same_tag 2>/dev/null)

if  [ $config_name == "" ] || [ -z $config_name ];then

	if [ $lang == "en" ] || [ $lang == "auto" ];then
				echo "Tag Your Config" >$REAL_LOG
	elif [ $lang == "zh_cn" ];then
				echo "标记您的配置" >$REAL_LOG
	fi
	sleep 5
	echo "Clash for OpenWRT" >$REAL_LOG
	exit 0	
	
fi

if [ ! -z $check_name ] && [ "${same_tag}" -eq 0 ];then

	if [ $lang == "en" ] || [ $lang == "auto" ];then
				echo "Config with same name exist, please rename tag and create again" >$REAL_LOG
	elif [ $lang == "zh_cn" ];then
				echo "已存在同名配置，请重命名标记,重新创建配置" >$REAL_LOG
	fi
	sleep 5
	echo "Clash for OpenWRT" >$REAL_LOG
	exit 0	

   
else


if [ "$load_from" == "sub" ];then 
        load=$(uci get clash.config.config_path_sub 2>/dev/null)	
elif [ "$load_from" == "upl" ];then
	load=$(uci get clash.config.config_path_up 2>/dev/null)
fi

if [ "${create}" -eq 1 ];then

 	if [ $lang == "en" ] || [ $lang == "auto" ];then
		echo "Strating to Create Custom Config.. " >$REAL_LOG 
	elif [ $lang == "zh_cn" ];then
    	 echo "开始创建自定义配置..." >$REAL_LOG
	fi
	
CONFIG_YAML_RULE="/usr/share/clash/custom_rule.yaml"
SERVER_FILE="/tmp/servers.yaml"
TEMP_FILE="/tmp/dns_temp.yaml"
Proxy_Group="/tmp/Proxy_Group"
GROUP_FILE="/tmp/groups.yaml"
CONFIG_FILE="/tmp/y_groups"
CFG_FILE="/etc/config/clash"
DNS_FILE="/usr/share/clash/dns.yaml" 
PROVIDER_FILE="/tmp/yaml_provider.yaml"

   gcount=$( grep -c "config groups" $CFG_FILE 2>/dev/null)
   scount=$( grep -c "config servers" $CFG_FILE 2>/dev/null)
   pcount=$( grep -c "config provider" $CFG_FILE 2>/dev/null)
   if [ $gcount -eq 0 ];then
 	if [ $lang == "en" ] || [ $lang == "auto" ];then
		echo "No policy group found. Aborting Operation .." >$REAL_LOG 
		sleep 2
		echo "Clash for OpenWRT" >$REAL_LOG
	elif [ $lang == "zh_cn" ];then
    	 echo "找不到策略组。中止操作..." >$REAL_LOG
		 sleep 2
		echo "Clash for OpenWRT" >$REAL_LOG
	fi
	exit 0	
   fi


set_http_path()
{
   if [ -z "$1" ]; then
      return
   fi
cat >> "$SERVER_FILE" <<-EOF
      - '$1'
EOF
}


yml_proxy_provider_set()
{
   local section="$1"

   config_get "type" "$section" "type" ""
   config_get "name" "$section" "name" ""
   config_get "path" "$section" "path" ""
   config_get "pathh" "$section" "pathh" ""
   config_get "provider_url" "$section" "provider_url" ""
   config_get "provider_interval" "$section" "provider_interval" ""
   config_get "health_check" "$section" "health_check" ""
   config_get "health_check_url" "$section" "health_check_url" ""
   config_get "health_check_interval" "$section" "health_check_interval" ""
   
	if [ "$type" == "http" ];then
		ppath="path: $path"
	elif [ "$type" == "file" ];then
	    ppath="path: $pathh"
	fi
	  

   if [ -z "$type" ]; then
      return
   fi
   
   if [ -z "$name" ]; then
      return
   fi

   
   if [ -z "$health_check" ]; then
      return
   fi

   
   echo "$name" >> /tmp/Proxy_Provider
   
cat >> "$PROVIDER_FILE" <<-EOF
  $name:
    type: $type
    $ppath
EOF
   if [ ! -z "$provider_url" ]; then
cat >> "$PROVIDER_FILE" <<-EOF
    url: $provider_url
    interval: $provider_interval
EOF
   fi
cat >> "$PROVIDER_FILE" <<-EOF
    health-check:
      enable: $health_check
      url: $health_check_url
      interval: $health_check_interval
EOF

}

if [ $pcount -gt 0 ];then
config_load "clash"
config_foreach yml_proxy_provider_set "provider"
fi

if [ -f $PROVIDER_FILE ];then 
sed -i "1i\   " $PROVIDER_FILE 2>/dev/null 

sed -i "2i\proxy-provider:" $PROVIDER_FILE 2>/dev/null

#echo "proxy-provider:" >$PROVIDER_FILE
rm -rf /tmp/Proxy_Provider

fi

set_alpn()
{
   if [ -z "$1" ]; then
      return
   fi
cat >> "$SERVER_FILE" <<-EOF
    - $1
EOF
}


set_groups()
{
  if [ -z "$1" ]; then
     return
  fi

	if [ "$1" = "$3" ]; then
	   set_group=1
	   echo "  - \"${2}\"" >>$GROUP_FILE
	fi

}



servers_set()
{
   local section="$1"
   config_get "type" "$section" "type" ""
   config_get "name" "$section" "name" ""
   config_get "server" "$section" "server" ""
   config_get "port" "$section" "port" ""
   config_get "cipher" "$section" "cipher" ""
   config_get "password" "$section" "password" ""
   config_get "securitys" "$section" "securitys" ""
   config_get "udp" "$section" "udp" ""
   config_get "obfs" "$section" "obfs" ""
   config_get "obfs_vmess" "$section" "obfs_vmess" ""
   config_get "host" "$section" "host" ""
   config_get "custom" "$section" "custom" ""
   config_get "tls" "$section" "tls" ""
   config_get "tls_custom" "$section" "tls_custom" ""
   config_get "skip_cert_verify" "$section" "skip_cert_verify" ""
   config_get "path" "$section" "path" ""
   config_get "alterId" "$section" "alterId" ""
   config_get "uuid" "$section" "uuid" ""
   config_get "auth_name" "$section" "auth_name" ""
   config_get "auth_pass" "$section" "auth_pass" ""
   config_get "mux" "$section" "mux" ""
   config_get "protocol" "$section" "protocol" ""
   config_get "protocolparam" "$section" "protocolparam" ""
   config_get "obfsparam" "$section" "obfsparam" ""
   config_get "obfs_ssr" "$section" "obfs_ssr" ""
   config_get "cipher_ssr" "$section" "cipher_ssr" ""
   config_get "psk" "$section" "psk" ""
   config_get "obfs_snell" "$section" "obfs_snell" ""
   config_get "sni" "$section" "sni" ""
   config_get "alpn" "$section" "alpn" ""
   config_get "http_path" "$section" "http_path" ""
   config_get "keep_alive" "$section" "keep_alive" ""
   
   if [ -z "$type" ]; then
      return
   fi
    
   if [ -z "$server" ]; then
      return
   fi

   if [ ! -z "$mux" ]; then
      muxx="mux: $mux"
   fi
   if [ "$obfs_snell" = "none" ]; then
      obfs_snell=""
   fi
   
   if [ -z "$name" ]; then
      name="Server"
   fi
   
   if [ -z "$port" ]; then
      return
   fi
   
   if [ ! -z "$udp" ] && [ "$obfs" = "none" ] && [ "$type" = "ss" ]; then
      udpp=", udp: $udp"
   fi

   if [ ! -z "$udp" ] && [ "$type" != "trojan" ] && [ "$type" != "ss" ]; then
      udpp=", udp: $udp"
   fi
   
   if [ "$obfs" != "none" ] && [ "$type" = "ss" ]; then
      if [ "$obfs" = "websocket" ]; then
         obfss="plugin: v2ray-plugin"
      else
         obfss="plugin: obfs"
      fi
   fi
   
   if [ "$obfs_vmess" = "websocket" ]; then
      obfs_vmess="network: ws"
   fi
   
   if [ "$obfs_vmess" = "http" ]; then
      obfs_vmess="network: http"
   fi
   
   if [ ! -z "$custom" ] && [ "$type" = "vmess" ]; then
      custom="Host: $custom"
   fi
   
   if [ ! -z "$path" ]; then
      if [ "$type" != "vmess" ]; then
         path="path: '$path'"
      elif [ "$obfs_vmess" = "network: ws" ]; then
         path="ws-path: $path"
      fi
   fi

   if [ ! -z "$auth_name" ] && [ ! -z "$auth_pass" ]; then
      auth_psk=", username: $auth_name, password: $auth_pass"
   fi
   
   
   if [ -z "$password" ]; then
   	 if [ "$type" = "ss" ] || [ "$type" = "trojan" ]; then
        return
     fi
   fi

   
   if [ "$type" = "ss" ] && [ "$obfs" = " " ]; then
      echo "- { name: \"$name\", type: $type, server: $server, port: $port, cipher: $cipher, password: "$password"$udpp }" >>$SERVER_FILE
   elif [ "$type" = "ss" ] && [ "$obfs" = "websocket" ] || [ "$obfs" = "tls" ] ||[ "$obfs" = "http" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
  cipher: $cipher
  password: "$password"
EOF
  if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
  udp: $udp
EOF
  fi
  if [ ! -z "$obfss" ]; then
cat >> "$SERVER_FILE" <<-EOF
  $obfss
  plugin-opts:
    mode: $obfs
EOF
  fi
  
   if [ "$host" ]; then
cat >> "$SERVER_FILE" <<-EOF
    host: $host
EOF
  fi 
  
  if [ "$tls_custom" = "true" ] && [ "$type" = "ss" ]; then
cat >> "$SERVER_FILE" <<-EOF
    tls: true
EOF
  fi
   if [ "$skip_cert_verify" = "true" ] && [ "$type" = "ss" ]; then
cat >> "$SERVER_FILE" <<-EOF
    skip-cert-verify: true
EOF
  fi

    if [ ! -z "$path" ]; then
cat >> "$SERVER_FILE" <<-EOF
    $paths
EOF
  fi
  
      if [ "$mux" = "true" ]; then
cat >> "$SERVER_FILE" <<-EOF
    $muxx
EOF
  fi

  if [ ! -z "$custom" ]; then
cat >> "$SERVER_FILE" <<-EOF
    headers:
      custom: $custom
EOF
  fi
   fi

if [ "$type" = "trojan" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
  password: "$password"
EOF
if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
  udp: $udp
EOF
fi
if [ ! -z "$sni" ]; then
cat >> "$SERVER_FILE" <<-EOF
  sni: $sni
EOF
fi
if [ ! -z "$alpn" ]; then
cat >> "$SERVER_FILE" <<-EOF
  alpn:
EOF
config_list_foreach "$section" "alpn" set_alpn
fi
if [ "$skip_cert_verify" = "true" ] && [ "$type" = "trojan" ]; then
cat >> "$SERVER_FILE" <<-EOF
  skip-cert-verify: true
EOF
  fi
fi
   
#vmess
   if [ "$type" = "vmess" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
  uuid: $uuid
  alterId: $alterId
  cipher: $securitys
EOF
      if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
  udp: $udp
EOF
      fi
      if [ "$tls" = "true" ]; then
cat >> "$SERVER_FILE" <<-EOF
  tls: $tls
EOF
      fi
      if [ "$skip_cert_verify" = "true" ]; then
cat >> "$SERVER_FILE" <<-EOF
  skip-cert-verify: $skip_cert_verify
EOF
      fi
      if [ "$obfs_vmess" != "none" ]; then
cat >> "$SERVER_FILE" <<-EOF
  $obfs_vmess
EOF
         if [ ! -z "$path" ] && [ "$obfs_vmess" = "network: ws" ]; then
cat >> "$SERVER_FILE" <<-EOF
  $path
EOF
         fi
         if [ ! -z "$custom" ] && [ "$obfs_vmess" = "network: ws" ]; then
cat >> "$SERVER_FILE" <<-EOF
  ws-headers:
    $custom
EOF
         fi
         if [ ! -z "$http_path" ] && [ "$obfs_vmess" = "network: http" ]; then
cat >> "$SERVER_FILE" <<-EOF
  http-opts:
    method: "GET"
    path:
EOF
            config_list_foreach "$section" "http_path" set_http_path
         fi
         if [ "$keep_alive" = "true" ] && [ "$obfs_vmess" = "network: http" ]; then
cat >> "$SERVER_FILE" <<-EOF
    headers:
      Connection:
        - keep-alive
EOF
         fi
      fi
   fi

#socks5
   if [ "$type" = "socks5" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
EOF
      if [ ! -z "$auth_name" ]; then
cat >> "$SERVER_FILE" <<-EOF
  username: $auth_name
EOF
      fi
      if [ ! -z "$auth_pass" ]; then
cat >> "$SERVER_FILE" <<-EOF
  password: $auth_pass
EOF
      fi
      if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
  udp: $udp
EOF
      fi
      if [ "$skip_cert_verify" = "true" ]; then
cat >> "$SERVER_FILE" <<-EOF
  skip-cert-verify: $skip_cert_verify
EOF
      fi
      if [ "$tls" = "true" ]; then
cat >> "$SERVER_FILE" <<-EOF
  tls: $tls
EOF
      fi
   fi

#http
   if [ "$type" = "http" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
EOF
      if [ ! -z "$auth_name" ]; then
cat >> "$SERVER_FILE" <<-EOF
  username: $auth_name
EOF
      fi
      if [ ! -z "$auth_pass" ]; then
cat >> "$SERVER_FILE" <<-EOF
  password: $auth_pass
EOF
      fi
      if [ "$skip_cert_verify" = "true" ]; then
cat >> "$SERVER_FILE" <<-EOF
  skip-cert-verify: $skip_cert_verify
EOF
      fi
      if [ "$tls" = "true" ]; then
cat >> "$SERVER_FILE" <<-EOF
  tls: $tls
EOF
      fi
   fi


#snell
   if [ "$type" = "snell" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
  psk: $psk
EOF
   if [ "$obfs_snell" != "none" ] && [ ! -z "$host" ]; then
cat >> "$SERVER_FILE" <<-EOF
  obfs-opts:
    mode: $obfs_snell
    host: $host
EOF
   fi
   fi

if [ "$type" = "ssr" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
  cipher: $cipher_ssr
  password: "$password"
  protocol: "$protocol"
  protocolparam: "$protocolparam"
  obfs: "$obfs_ssr"
  obfsparam: "$obfsparam"
EOF
fi


}


if [ $scount -gt 0 ];then
config_load clash
config_foreach servers_set "servers"
fi

if [ ! -z "${scount}" ] || [ "${scount}" -ne 0 ];then

sed -i "1i\   " $SERVER_FILE 2>/dev/null 

sed -i "2i\Proxy:" $SERVER_FILE 2>/dev/null 

egrep '^ {0,}-' $SERVER_FILE |grep name: |awk -F 'name: ' '{print $2}' |sed 's/,.*//' >$Proxy_Group 2>&1

sed -i "s/^ \{0,\}/    - /" $Proxy_Group 2>/dev/null 
fi


yml_servers_add()
{
	
	local section="$1"
	config_get "name" "$section" "name" ""
	config_list_foreach "$section" "groups" set_groups "$name" "$2"
	config_get "relay_groups" "$section" "relay_groups" ""
}



set_other_groups()
{
set_group=1
   if [ "${1}" = "DIRECT" ]||[ "${1}" = "REJECT" ];then
   echo "    - ${1}" >>$GROUP_FILE 2>/dev/null 
   elif [ "${1}" = "ALL" ];then
   cat $Proxy_Group >> $GROUP_FILE 2>/dev/null
   else
   echo "    - \"${1}\"" >>$GROUP_FILE 2>/dev/null 
   fi

}

set_proxy_provider()
{
	local section="$1"
	config_get "name" "$section" "name" ""
	config_list_foreach "$section" "groups" set_provider_groups "$name" "$2"

}

set_provider_groups()
{
	if [ -z "$1" ]; then
		return
	fi

	if [ "$1" = "$3" ]; then
	   set_proxy_provider=1
	   echo "    - ${2}" >>$GROUP_FILE
	fi

}


yml_groups_set()
{

   local section="$1"
   config_get "type" "$section" "type" ""
   config_get "name" "$section" "name" ""
   config_get "old_name" "$section" "old_name" ""
   config_get "test_url" "$section" "test_url" ""
   config_get "test_interval" "$section" "test_interval" ""

   if [ -z "$type" ]; then
      return
   fi
   
   if [ -z "$name" ]; then
      return
   fi
   
   echo "- name: $name" >>$GROUP_FILE 2>/dev/null 
   echo "  type: $type" >>$GROUP_FILE 2>/dev/null 
   group_name="$name"
   echo "  proxies: " >>$GROUP_FILE

   #if [ "$type" == "url-test" ] || [ "$type" == "load-balance" ] || [ "$type" == "fallback" ] ; then
   #  echo "  proxies:" >>$GROUP_FILE 2>/dev/null 
   #   cat $Proxy_Group >> $GROUP_FILE 2>/dev/null
   #else
   #  echo "  proxies:" >>$GROUP_FILE 2>/dev/null 
   #fi       
 
   if [ "$name" != "$old_name" ]; then
      sed -i "s/,${old_name}$/,${name}#d/g" $load 2>/dev/null
      sed -i "s/:${old_name}$/:${name}#d/g" $load 2>/dev/null
      sed -i "s/\'${old_name}\'/\'${name}\'/g" $CFG_FILE 2>/dev/null
      config_load "clash"
   fi
   
   set_group=0
   set_proxy_provider=0   
   

    config_list_foreach "$section" "other_group" set_other_groups #加入其他策略组
   

   config_foreach yml_servers_add "servers" "$name" "$type" #加入服务器节点

   
   if [ "$( grep -c "config provider" $CFG_FILE )" -ne 0 ];then
   
		echo "  use: $group_name" >>$GROUP_FILE
	   
	   
	   
	    if [ "$type" != "relay" ]; then
			 config_foreach set_proxy_provider "provider" "$group_name" #加入代理集
	    fi

	   if [ "$set_group" -eq 1 ]; then
		  sed -i "/^ \{0,\}proxies: ${group_name}/c\  proxies:" $GROUP_FILE
	   else
		  sed -i "/proxies: ${group_name}/d" $GROUP_FILE 2>/dev/null
	   fi

	   if [ "$set_proxy_provider" -eq 1 ]; then
		  sed -i "/^ \{0,\}use: ${group_name}/c\  use:" $GROUP_FILE
	   else
		  sed -i "/use: ${group_name}/d" $GROUP_FILE 2>/dev/null
	   fi
   
   fi
   
   
   [ ! -z "$test_url" ] && {
   	echo "  url: $test_url" >>$GROUP_FILE 2>/dev/null 
   }
   [ ! -z "$test_interval" ] && {
   echo "  interval: \"$test_interval\"" >>$GROUP_FILE 2>/dev/null 
   }
}


config_load clash
config_foreach yml_groups_set "groups"


if [ "$(ls -l $GROUP_FILE|awk '{print $5}')" -ne 0 ]; then
sed -i "1i\  " $GROUP_FILE 2>/dev/null 
sed -i "2i\Proxy Group:" $GROUP_FILE 2>/dev/null 

fi



mode=$(uci get clash.config.mode 2>/dev/null)
da_password=$(uci get clash.config.dash_pass 2>/dev/null)
redir_port=$(uci get clash.config.redir_port 2>/dev/null)
http_port=$(uci get clash.config.http_port 2>/dev/null)
socks_port=$(uci get clash.config.socks_port 2>/dev/null)
dash_port=$(uci get clash.config.dash_port 2>/dev/null)
bind_addr=$(uci get clash.config.bind_addr 2>/dev/null)
allow_lan=$(uci get clash.config.allow_lan 2>/dev/null)
log_level=$(uci get clash.config.level 2>/dev/null)
subtype=$(uci get clash.config.subcri 2>/dev/null)

		
cat >> "$TEMP_FILE" <<-EOF
#config-start-here
EOF

		sed -i "1i\port: ${http_port}" $TEMP_FILE 2>/dev/null
		sed -i "/port: ${http_port}/a\socks-port: ${socks_port}" $TEMP_FILE 2>/dev/null 
		sed -i "/socks-port: ${socks_port}/a\redir-port: ${redir_port}" $TEMP_FILE 2>/dev/null 
		sed -i "/redir-port: ${redir_port}/a\allow-lan: ${allow_lan}" $TEMP_FILE 2>/dev/null 
		if [ $allow_lan == "true" ];  then
		sed -i "/allow-lan: ${allow_lan}/a\bind-address: \"${bind_addr}\"" $TEMP_FILE 2>/dev/null 
		sed -i "/bind-address: \"${bind_addr}\"/a\mode: Rule" $TEMP_FILE 2>/dev/null
		sed -i "/mode: Rule/a\log-level: ${log_level}" $TEMP_FILE 2>/dev/null 
		sed -i "/log-level: ${log_level}/a\external-controller: 0.0.0.0:${dash_port}" $TEMP_FILE 2>/dev/null 
		sed -i "/external-controller: 0.0.0.0:${dash_port}/a\secret: \"${da_password}\"" $TEMP_FILE 2>/dev/null 
		sed -i "/secret: \"${da_password}\"/a\external-ui: \"/usr/share/clash/dashboard\"" $TEMP_FILE 2>/dev/null 
		sed -i "external-ui: \"/usr/share/clash/dashboard\"/a\  " $TEMP_FILE 2>/dev/null 
		sed -i "   /a\   " $TEMP_FILE 2>/dev/null
		else
		sed -i "/allow-lan: ${allow_lan}/a\mode: Rule" $TEMP_FILE 2>/dev/null
		sed -i "/mode: Rule/a\log-level: ${log_level}" $TEMP_FILE 2>/dev/null 
		sed -i "/log-level: ${log_level}/a\external-controller: 0.0.0.0:${dash_port}" $TEMP_FILE 2>/dev/null 
		sed -i "/external-controller: 0.0.0.0:${dash_port}/a\secret: \"${da_password}\"" $TEMP_FILE 2>/dev/null 
		sed -i "/secret: \"${da_password}\"/a\external-ui: \"/usr/share/clash/dashboard\"" $TEMP_FILE 2>/dev/null 
		fi
		sed -i '/#config-start-here/ d' $TEMP_FILE 2>/dev/null

		
cat $DNS_FILE >> $TEMP_FILE  2>/dev/null

if [ -f $SERVER_FILE ];then
cat $SERVER_FILE >> $TEMP_FILE  2>/dev/null
fi

if [ -f $PROVIDER_FILE ];then 
cat $PROVIDER_FILE >> $TEMP_FILE 2>/dev/null
fi

cat $GROUP_FILE >> $TEMP_FILE 2>/dev/null

if [ -f $CONFIG_YAML ];then
	rm -rf $CONFIG_YAML
fi

cat $TEMP_FILE $CONFIG_YAML_RULE > $CONFIG_YAML 2>/dev/null

sed -i "/Rule:/i\     " $CONFIG_YAML 2>/dev/null

if [ -z $check_name ] && [ "${same_tag}" -eq 1 ];then
echo "${config_name}.yaml" >>/usr/share/clashbackup/create_list.conf
elif [ -z $check_name ] && [ "${same_tag}" -eq 0 ];then
echo "${config_name}.yaml" >>/usr/share/clashbackup/create_list.conf
fi

rm -rf $TEMP_FILE $GROUP_FILE $Proxy_Group $CONFIG_FILE $PROVIDER_FILE 
rm -rf /tmp/relay_server.list 2>/dev/null

 	if [ $lang == "en" ] || [ $lang == "auto" ];then
		echo "Completed Creating Custom Config.. " >$REAL_LOG 
		 sleep 2
			echo "Clash for OpenWRT" >$REAL_LOG
	elif [ $lang == "zh_cn" ];then
    	echo "创建自定义配置完成..." >$REAL_LOG
		sleep 2
		echo "Clash for OpenWRT" >$REAL_LOG
	fi

rm -rf $SERVER_FILE
fi
fi



