## Introduction

Tired to modify your configuration files depending on the targeted computer? Turn them out into ERB templates and deploy them in one command.

The purpose is to implement a kind of shell with limited dependencies to automate configuration and deployment on various (Unix) environments.

Dependencies: net-ssh, highline

## Installation

`gem install cindy-cm`

## Available commands

* environment
    * list                                                              => list all known environments
    * create \<uri> as \<name>                                          => register a new environment
    * \<name>
        * update name = \<new name> and/or uri = \<new uri>             => modify environment named *name*, renaming it and/or changing its uri
        * delete                                                        => remove environment named *name*
* template
    * list                                                              => list all known templates
    * add \<file> as \<name>                                            => register template *file* with the mnemonic *name*
    * \<name>
        * delete                                                        => remove template named *name* (the template file is not deleted)
        * update name = \<new name> and/or file = \<new location>       => modify template named *name*: rename alias and/or change template location
        * environment \<name>
            * deploy                                                    => install the generated file on the given environment
            * print                                                     => display output configuration file as it would be deployed on the given environment
            * path = \<path>                                            => define path under which rendered output should be installed for the given environment
            * variable
                * list                                                  => list all applicable variables to the given template, their values and scopes
                * \<name>
                    * set|= \<value> (typed boolean|string|command|int) => (re)define a variable at environment level
        * variable \<name>
            * set|= \<value> (typed boolean|string|command|int)         => define a variable at template level, acts as default value
            * rename to \<new name>                                     => rename the given variable (in all scopes)
            * unset                                                     => unset the given variable in all scopes

## Example

Enter the following commands:
```
cindy
# create 2 environments named "production" and "development"
environment create file:/// as development
environment create ssh://root@www.xxx.tld/ as production
# register the template /home/julp/cindy/templates/nginx.conf.tpl (see below) for our nginx configuration
template add /home/julp/cindy/templates/nginx.conf.tpl as nginx
# define some variables for our nginx template according to the environment
template nginx environment development path = /etc/nginx.conf
template nginx environment production path = /usr/local/etc/nginx.conf
template nginx variable have_gzip_static set "nginx -V 2>&1 >/dev/null | grep -qF -- --with-http_gzip_static_module" typed command
template nginx environment production variable have_gzip_static set "(nginx -V > /dev/null) |& grep -qF -- --with-http_gzip_static_module" typed command
template nginx environment development variable root = /home/julp/app/public
template nginx environment production variable root = /home/julp/app/current/public
template nginx environment development variable server_name = www.xxx.lan
template nginx environment production variable server_name = www.xxx.tld
```

Or simply create ~/.cindy as follows:
```xml
<cindy>
    <environment name="development" uri="file:///"/>
    <environment name="production" uri="ssh://root@www.xxx.tld/"/>
    <template alias="nginx" file="/home/julp/cindy/templates/nginx.conf.tpl">
        <on environment="development" path="/etc/nginx.conf">
            <variable name="root" type="string">/home/julp/app/public</variable>
            <variable name="server_name" type="string">www.xxx.lan</variable>
        </on>
        <on environment="production" path="/usr/local/etc/nginx.conf">
            <variable name="root" type="string">/home/julp/app/current/public</variable>
            <variable name="server_name" type="string">www.xxx.tld</variable>
            <variable name="have_gzip_static" type="command">(nginx -V &gt; /dev/null) |&amp; grep -qF -- --with-http_gzip_static_module</variable> <!-- (t)csh -->
        </on>
        <variable name="have_gzip_static" type="command">nginx -V 2&gt;&amp;1 &gt;/dev/null | grep -qF -- --with-http_gzip_static_module</variable> <!-- (ba|k)sh -->
    </template>
</cindy>
```

With /home/julp/cindy/templates/nginx.conf.tpl as:
```
server {
    server_name <%= server_name %>;
    root <%= root %>;

    <% if have_gzip_static %>
        gzip_static on;
    <% end %>
}
```

By running `cindy template nginx environment production print`, we obtain:
```
server {
    server_name www.xxx.tld;
    root /home/julp/app/current/public;

        gzip_static on;
}
```
(if we admit that nginx is built, on production environment, with Gzip Precompression module)

After `cindy template nginx environment production deploy`, if we `ls -l /etc/nginx.conf*`:
```
lrwxrwxrwx [...] /usr/local/etc/nginx.conf -> /usr/local/etc/nginx.conf.201502262311
-rw-r--r-- [...] /usr/local/etc/nginx.conf.201502262209                              # file at previous deployment
-rw-r--r-- [...] /usr/local/etc/nginx.conf.201502262311                              # current version (1h02m later)
```

## Limitations

* `sudo` prompt to ask passwords is not handled (use a passwordless configuration)
* you need to configure your ssh keys in `~/.ssh/config`, eg:

```
Host www.domain.tld
User julp
IdentityFile /path/to/your/private/key
```