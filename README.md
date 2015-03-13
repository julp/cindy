## Introduction

Tired to modify your configuration files depending on the targeted host? Turn them out into ERB templates and deploy them in one command.

The purpose is to implement a kind of shell with limited dependencies to automate configuration and deployment on various (Unix) environments.

Dependencies: net-ssh, highline

## Installation

`gem install cindy-cm`

## Usage of cindy command

* reload                        => force Cindy to reload its configuration file
* environment (shortcut: env)
    * list                      => list all known environments
* template (shortcut: tpl)
    * list                      => list all known templates
    * \<name>
        * environment \<name>
            * deploy            => install the generated file on the given environment
            * print             => display output configuration file as it would be deployed on the given environment
            * details           => list all applicable variables to the given template, their values and scopes

## Example

Create ~/.cindy as follows:

```ruby
# create 2 environments named "production" and "development"
environment :development
environment :production, 'ssh://root@www.xxx.tld/'

# register the template ~/cindy/templates/nginx.conf.tpl (see below) for our nginx configuration
template :nginx, '~/cindy/templates/nginx.conf.tpl' do
    # default variables

    # have_gzip_static will be set to true or false depending on the result of the following command
    var :have_gzip_static, Command.new('nginx -V 2>&1 >/dev/null | grep -qF -- --with-http_gzip_static_module') # (ba|k)sh

    on :production, '/usr/local/etc/nginx.conf' do
        # define and/or override some variables for nginx when on our production environment
        var :server_name, 'www.xxx.tld'
        var :root, '/home/julp/app/current/public'
        var :have_gzip_static, Command.new('(nginx -V > /dev/null) |& grep -qF -- --with-http_gzip_static_module') # (t)csh
    end

    on :development, '/etc/nginx.conf' do
        # (re)define variables for nginx when in development
        var :server_name, 'www.xxx.lan'
        var :root, '/home/julp/app/public'
    end

    # after deployment, check syntax
    postcmd 'nginx -tc $INSTALL_FILE'
    # if no error, reload configuration
    postcmd 'nginx -s reload'
end
```

And ~/cindy/templates/nginx.conf.tpl as:

```
# <%= _install_file_ %>

server {
    server_name <%= server_name %>;
    root <%= root %>;

    <% if false %>
        this content never appears
    <% end %>

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

## What is a *Command* object?

It is a kind of dynamic variable: instead of hardcoding a value which depends on the remote host, we execute the associated command before each
time the template is rendered. It is more convenient mainly if this value can change at any time.

The result of the command is a boolean based on its exit status (0 => true, everything else => false) if the command does not print anything on
standard output else a string with the content sent on standard output.

In the example above, `nginx -V 2>&1 >/dev/null | grep -qF -- --with-http_gzip_static_module` is intended to determine if nginx, on the remote
server, is compiled or not with the gzip_static module.

As you can see in this same example, note that commands may depend on the "remote shell" (redirections in particular) and also on the value of the
PATH environment variable.

## Predefined variables in templates

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
