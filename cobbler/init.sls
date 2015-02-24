{% from "cobbler/map.jinja" import cobbler with context %}

{% set cfg_cobbler = pillar.get('cobbler', {}) -%}
{%- macro get_config(configname, default_value) -%}
{%- if configname in cfg_cobbler -%}
{{ cfg_cobbler[configname] }}
{%- else -%}
{{ default_value }}
{%- endif -%}
{%- endmacro -%}

include:
  - apache
  - apache.modules

cobbler-deps:
  pkg.installed:
    - pkgs: {{ cobbler['pkgs']|json }}

{% if grains['os_family'] == 'Debian' %}
cobbler-repo:
  pkgrepo.managed:
    - humanname: Cobbler Repo
    {% if grains['os'] == 'Ubuntu' %}
    - name: "deb http://download.opensuse.org/repositories/home:/libertas-ict:/cobbler26/x{{ grains['os'] }}_{{ grains['osrelease'] }} ./"
    {% else %}
    - name: "deb http://download.opensuse.org/repositories/home:/libertas-ict:/cobbler26/{{ grains['os'] }}_{{ grains['osrelease'] }} ./"
    {% endif %}
    - dist: ./
    - file: /etc/apt/sources.list.d/cobbler.list
    - key_url: salt://cobbler/files/Release.key
    - require_in:
      - pkg: cobbler
{% endif %}

cobbler:
  pkg.latest:
    - refresh: True
    - watch_in:
      - service: apache
  service.running:
    - name: cobblerd
    - enable: True

cobbler-settings-config:
  augeas.change:
    - context: /files/etc/cobbler/settings
    - changes:
      - set bind_master {{ get_config('bind_master', '127.0.0.1') }}
      - set next_server {{ get_config('next_server', '127.0.0.1') }}
      - set server {{ get_config('server', '127.0.0.1') }}
      - set manage_dhcp {{ get_config('manage_dhcp', '0') }}
      - set restart_dhcp {{ get_config('restart_dhcp', '0') }}
      - set manage_tftpd {{ get_config('manage_tftpd', 1) }}
      - set pxe_just_once {{ get_config('pxe_just_once', 0) }}
      - set default_virt_bridge {{ get_config('default_virt_bridge', 'xenbr0') }}
      - set default_virt_type {{ get_config('default_virt_type', 'xenpv') }}
      - set register_new_installs {{ get_config('register_new_installs', '0') }}
    - watch_in:
      - service: cobblerd
  require:
    - pkg: cobbler

cobbler-modules-config:
  augeas.change:
    - context: /files/etc/cobbler/modules.conf
    - changes:
      - set dns/module {{ get_config('dns_module', 'manage_isc') }}
      - set dhcp/module {{ get_config('dhcp_module', 'manage_isc') }}
      - set tftpd/module {{ get_config('tftpd_module', 'manage_in_tftpd') }}
    - watch_in:
      - service: cobblerd
  require:
    - pkg: cobbler

cobbler-dnsmasq-config:
  file.managed:
    - source: salt://cobbler/files/dnsmasq.template
    - name: /etc/cobbler/dnsmasq.template
    - template: jinja
  require:
    - pkg: cobbler

cobbler-tftpd-config:
  file.managed:
    - source: salt://cobbler/files/tftpd.template
    - name: /etc/cobbler/tftpd.template
    - template: jinja
  require:
    - pkg: cobbler

/var/lib/cobbler/webui_sessions:
  file.directory:
    - user: www-data

/tftpboot:
  file.directory

{% if grains['os'] == 'Ubuntu' %}
{% if grains['osrelease_info'][0] <= 12  %}
/usr/share/cobbler/web/cobbler_web/urls.py:
  file.replace:
    - pattern: "from django.conf.urls import patterns"
    - repl: "from django.conf.urls.defaults import *"
{% endif %}
{% endif %}

kickstarts:
  file.recurse:
    - source: salt://cobbler/files/kickstarts/
    - name: /var/lib/cobbler/kickstarts/

snippets:
  file.recurse:
    - source: salt://cobbler/files/snippets/
    - name: /var/lib/cobbler/snippets/

epel7:
  cmd.run:
    - name: cobbler repo add --name=epel7 --breed=yum --mirror=http://ftp.heanet.ie/pub/fedora/epel/7/x86_64 --mirror-locally=false
    - creates: /var/lib/cobbler/config/repos.d/epel7.json
  require:
    - service: cobblerd
