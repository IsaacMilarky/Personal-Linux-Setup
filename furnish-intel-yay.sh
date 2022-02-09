#!/bin/bash

#Apparmor, encryption and stuff should have been configured before this point. Run as user
sudo pacman -Syyu
sudo pacman -S git base-devel intel-ucode openssh cmake extra-cmake-modules linux-zen-headers
grub-mkconfig -o /boot/grub/grub.cfg
mkdir Repos/
cd Repos
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd

sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
yay -Syy xorg xf86-video-intel mesa 

yay -Syy plasma-meta plasma-wayland-session sddm-kcm powertop gnome-keyring
sudo systemctl enable sddm

sudo tee -a /etc/systemd/system/powertop.service > /dev/null <<EOT
[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl enable powertop

#media
yay -S vlc rhythmbox pipewire pipewire-docs pipewire-alsa pipewire-pulse

pactl info || echo "Pactl not reachable!"

yay -S thermald

sudo systemctl enable thermald.service

#flatpaks
yay -S flatpak konsole 
flatpak install flathub com.spotify.Client
flatpak install flathub com.discordapp.Discord
flatpak install flathub com.slack.Slack
flatpak install flathub us.zoom.Zoom

yay -S ufw
sudo systemctl enable ufw.service

#fonts and libreoffice
yay -S ttf-dejavu ttf-droid libreoffice-still

#adminer
yay -S apache php adminer php-sqlite php-pgsql php-apache
sudo systemctl enable httpd

sudo tee /etc/httpd/conf/httpd.conf > /dev/null <<EOT
ServerRoot "/etc/httpd"


Listen 80

LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
LoadModule authn_file_module modules/mod_authn_file.so
LoadModule authn_core_module modules/mod_authn_core.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
LoadModule authz_user_module modules/mod_authz_user.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule access_compat_module modules/mod_access_compat.so
LoadModule auth_basic_module modules/mod_auth_basic.so
LoadModule reqtimeout_module modules/mod_reqtimeout.so
LoadModule include_module modules/mod_include.so
LoadModule filter_module modules/mod_filter.so
LoadModule mime_module modules/mod_mime.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule env_module modules/mod_env.so
LoadModule headers_module modules/mod_headers.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule version_module modules/mod_version.so
LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule status_module modules/mod_status.so
LoadModule autoindex_module modules/mod_autoindex.so
<IfModule !mpm_prefork_module>
</IfModule>
<IfModule mpm_prefork_module>
</IfModule>
LoadModule negotiation_module modules/mod_negotiation.so
LoadModule dir_module modules/mod_dir.so
LoadModule userdir_module modules/mod_userdir.so
LoadModule alias_module modules/mod_alias.so
LoadModule php_module modules/libphp.so
AddHandler php-script .php

<IfModule unixd_module>
User http
Group http

</IfModule>


ServerAdmin you@example.com


<Directory />
    AllowOverride none
    Require all denied
</Directory>


DocumentRoot "/srv/http"
<Directory "/srv/http">
    Options Indexes FollowSymLinks

    AllowOverride None

    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "/var/log/httpd/error_log"

LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>

    CustomLog "/var/log/httpd/access_log" common

</IfModule>

<IfModule alias_module>


    ScriptAlias /cgi-bin/ "/srv/http/cgi-bin/"

</IfModule>

<IfModule cgid_module>
</IfModule>

<Directory "/srv/http/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule headers_module>
    RequestHeader unset Proxy early
</IfModule>

<IfModule mime_module>
    TypesConfig conf/mime.types

    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz



</IfModule>






Include conf/extra/httpd-mpm.conf

Include conf/extra/httpd-multilang-errordoc.conf

Include conf/extra/httpd-autoindex.conf

Include conf/extra/httpd-languages.conf

Include conf/extra/httpd-userdir.conf





Include conf/extra/httpd-default.conf

<IfModule proxy_html_module>
Include conf/extra/proxy-html.conf
</IfModule>

Include conf/extra/php_module.conf
Include conf/extra/httpd-adminer.conf
<IfModule ssl_module>
SSLRandomSeed startup builtin
SSLRandomSeed connect builtin
</IfModule>
EOT

sudo tee /etc/php/php.ini > /dev/null <<EOT
[PHP]

engine = On

short_open_tag = Off

precision = 14

output_buffering = 4096

zlib.output_compression = Off



implicit_flush = Off

unserialize_callback_func =


serialize_precision = -1


disable_functions =

disable_classes =



zend.enable_gc = On

zend.exception_ignore_args = On

zend.exception_string_param_max_len = 0


expose_php = On


max_execution_time = 30

max_input_time = 60



memory_limit = 128M


error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT

display_errors = Off

display_startup_errors = Off

log_errors = On

log_errors_max_len = 1024

ignore_repeated_errors = Off

ignore_repeated_source = Off

report_memleaks = On



variables_order = "GPCS"

request_order = "GP"

register_argc_argv = Off

auto_globals_jit = On


post_max_size = 8M

auto_prepend_file =

auto_append_file =

default_mimetype = "text/html"

default_charset = "UTF-8"






doc_root =

user_dir =

extension_dir = "/usr/lib/php/modules/"


enable_dl = Off



file_uploads = On


upload_max_filesize = 2M

max_file_uploads = 20


allow_url_fopen = On

allow_url_include = Off



default_socket_timeout = 60



extension=curl
extension=mysqli
extension=pdo_mysql
extension=pdo_pgsql
extension=pdo_sqlite
extension=pgsql
extension=zip


[CLI Server]
cli_server.color = On

[Date]





[filter]


[iconv]



[imap]

[intl]

[sqlite3]


[Pcre]



[Pdo]

[Pdo_mysql]
pdo_mysql.default_socket=

[Phar]



[mail function]
SMTP = localhost
smtp_port = 25




mail.add_x_header = Off


[ODBC]




odbc.allow_persistent = On

odbc.check_persistent = On

odbc.max_persistent = -1

odbc.max_links = -1

odbc.defaultlrl = 4096

odbc.defaultbinmode = 1

[MySQLi]

mysqli.max_persistent = -1


mysqli.allow_persistent = On

mysqli.max_links = -1

mysqli.default_port = 3306

mysqli.default_socket =

mysqli.default_host =

mysqli.default_user =

mysqli.default_pw =

mysqli.reconnect = Off

[mysqlnd]
mysqlnd.collect_statistics = On

mysqlnd.collect_memory_statistics = Off



[OCI8]


[PostgreSQL]
pgsql.allow_persistent = On

pgsql.auto_reset_persistent = Off

pgsql.max_persistent = -1

pgsql.max_links = -1

pgsql.ignore_notice = 0

pgsql.log_notice = 0

[bcmath]
bcmath.scale = 0

[browscap]

[Session]
session.save_handler = files


session.use_strict_mode = 0

session.use_cookies = 1


session.use_only_cookies = 1

session.name = PHPSESSID

session.auto_start = 0

session.cookie_lifetime = 0

session.cookie_path = /

session.cookie_domain =

session.cookie_httponly =

session.cookie_samesite =

session.serialize_handler = php

session.gc_probability = 1

session.gc_divisor = 1000

session.gc_maxlifetime = 1440


session.referer_check =

session.cache_limiter = nocache

session.cache_expire = 180

session.use_trans_sid = 0

session.sid_length = 26

session.trans_sid_tags = "a=href,area=href,frame=src,form="


session.sid_bits_per_character = 5



[Assertion]
zend.assertions = -1

[COM]


[mbstring]






[gd]

[exif]






[Tidy]

tidy.clean_output = Off

[soap]
soap.wsdl_cache_enabled=1

soap.wsdl_cache_dir="/tmp"

soap.wsdl_cache_ttl=86400

soap.wsdl_cache_limit = 5

[sysvshm]

[ldap]
ldap.max_links = -1

[dba]

[opcache]





[curl]

[openssl]


[ffi]
EOT


#Appmenu stuff
yay -S appmenu-gtk-module-git
cd Repos
git clone https://github.com/psifidotos/applet-window-appmenu
cd applet-window-appmenu
sh install.sh

yay -S firefox-appmenu-bin vscodium-bin redshift


#misc
yay -S gimp musescore ark kate spectacle htop gping latte-dock vim dolphin timeshift okular weechat ktorrent gwenview krita
yay -S chatterino2-git signal-desktop
yay -S wireshark-qt


#end
yay
reboot
