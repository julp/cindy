## Introduction

Tired to modify your configuration files depending on the targeted computer? Turn them out into ERB templates and deploy them in one command.

The purpose is to implement a kind of shell with limited dependencies to automate configuration and deployment on various (Unix) environments.

Dependencies: net-ssh, highline

## Installation

`gem install cindy-cm`

## Usage

* reload                                                                => force Cindy to reload its configuration file
* environment (shortcut: env)
    * list                                                              => list all known environments
    * create \<uri> as \<name>                                          => register a new environment
    * \<name>
        * update name = \<new name> and/or uri = \<new uri>             => modify environment named *name*, renaming it and/or changing its uri
        * delete                                                        => remove environment named *name*
* template (shortcut: tpl)
    * list                                                              => list all known templates
    * add \<file> as \<name>                                            => register template *file* with the mnemonic *name*
    * \<name>
        * delete                                                        => remove template named *name* (the template file is not deleted)
        * update name = \<new name> and/or file = \<new location>       => modify template named *name*: rename alias and/or change template location
        * environment \<name>
            * deploy                                                    => install the generated file on the given environment
            * print                                                     => display output configuration file as it would be deployed on the given environment
            * path = \<path>                                            => define path under which rendered output should be installed for the given environment
            * variable (shortcut: var)
                * list                                                  => list all applicable variables to the given template, their values and scopes
                * \<name>
                    * set|= \<value> (typed boolean|string|command|int) => (re)define a variable at environment level
        * variable \<name>
            * set|= \<value> (typed boolean|string|command|int)         => define a variable at template level, acts as default value
            * rename to \<new name>                                     => rename the given variable (in all scopes)
            * unset                                                     => unset the given variable in all scopes

## Example

Create ~/.cindy as follows:
```ruby
environment :development, 'file:///'
environment :production, 'ssh://root@www.xxx.tld/'

template :nginx, '/home/julp/cindy/templates/nginx.conf.tpl' do
    var :have_gzip_static, Command.new('nginx -V 2>&1 >/dev/null | grep -qF -- --with-http_gzip_static_module') # (ba|k)sh

    on :production, '/usr/local/etc/nginx.conf' do
        var :server_name, 'www.xxx.tld'
        var :root, '/home/julp/app/current/public'
        var :have_gzip_static, Command.new('(nginx -V > /dev/null) |& grep -qF -- --with-http_gzip_static_module') # (t)csh
    end

    on :development, '/etc/nginx.conf' do
        var :server_name, 'www.xxx.lan'
        var :root, '/home/julp/app/public'
    end
end
```

And /home/julp/cindy/templates/nginx.conf.tpl as:
```
# <%= _install_file_ %>

server {
    server_name <%= server_name %>;
    root <%= root %>;

    <% if have_gzip_static %>
        gzip_static on;
    <% end %>
}
```

Running `cindy template nginx environment production print`, result in:
```
# /usr/local/etc/nginx.conf

server {
    server_name www.xxx.tld;
    root /home/julp/app/current/public;

        gzip_static on;
}
```
(if we admit that nginx is built, on production environment, with Gzip Precompression module)

After `cindy template nginx environment production deploy`, output of `ls -l /etc/nginx.conf*` is:
```
lrwxrwxrwx [...] /usr/local/etc/nginx.conf -> /usr/local/etc/nginx.conf.201502262311
-rw-r--r-- [...] /usr/local/etc/nginx.conf.201502262209                              # file at previous deployment
-rw-r--r-- [...] /usr/local/etc/nginx.conf.201502262311                              # current version (1h02m later)
```

## What is a *command* typed variable?

It is a kind of dynamic variable: instead of hardcoding a value which depends on the remote host, we execute the associated command before each
time the template is rendered. It is more convenient mainly if this value can change at any time.

The result of the command is a boolean based on its exit status (0 => true, everithing else => false) if the command does not print anything on
standard output else a string with the content of standard output.

In the example above, `nginx -V 2>&1 >/dev/null | grep -qF -- --with-http_gzip_static_module` is intended to determine if nginx, on the remote
server, is compiled or not with the gzip_static module.

As you can see in this same example, note that commands may depend on the "remote shell" (redirections in particular) and also on the value of the
PATH environment variable.

## Predefined variables

* `_install_dir_`: directory in which output file will be deployed (equivalent to `File.dirname _install_file_` but more convenient)
* `_install_file_`: filename under which the file will be deployed

## Limitations

* `sudo` prompt to ask passwords is not handled: use a passwordless configuration
* you need to configure your ssh keys in `~/.ssh/config`, eg:

```
Host www.domain.tld
User julp
IdentityFile /path/to/your/private/key
```
