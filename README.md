## About this script

This is a script that can help you auto renew let's encrypt wild-char certificates using DNS-01, if your domain is on namesilo.
Otherwise, this srcipt is not suitable for you, unless you wanna see how LE manual auth hook works.


You may encounter some errors like this while just simply run certbot renew:

```
Could not choose appropriate plugin: The manual plugin is not working; there may be problems with your existing configuration.
The error was: PluginError('An authentication script must be provided with --manual-auth-hook when using the manual plugin non-interactively.',)
Attempting to renew cert (blog.zengrong.net) from /etc/letsencrypt/renewal/blog.zengrong.net.conf produced an unexpected error: The manual plugin is not working; there may be problems with your existing configuration.
The error was: PluginError('An authentication script must be provided with --manual-auth-hook when using the manual plugin non-interactively.',). Skipping.

```

that means you have to specify a manual auth hook for certbot auto renew process.

a manual auth hook is a script allows you deals with non-interactive DNS-01 validation (remember the first LE certificate apply ?) in your own ways.
usually a pipeline like this:

* certbot checks if certificate is running out of date
* request for renew process
* calls for validation domains and tokens 
* put the domain and token infos into ENVIRONMENT VARIABLES starting with CERTBOT_ (You may find these variables in script's DEBUG function)
* You tries adds a challenge record into namesilo (your domain seller) by calling its api
* just polling until your challenge take effect.
* let your script quit normally or wait for timeout

And the script shows how what a DNS-01 validation pipeline is.


reference: 
https://certbot.eff.org/docs/using.html#pre-and-post-validation-hooks
for certbot logs: /var/log/letsencrypt/*.log 
they are usually here. :)



## Usage example: 

* get this file, and put it to somewhere you like.
* edit this file and fill in your namesilo API key. (you will easily find where it is in the script, the commented line!)
* test the script to see if there is some bug(optional)
* just run the renew process using this script like the following commandline:

./certbot-auto renew --manual --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory --manual-auth-hook {ABSOLUTE-PATH-TO-THIS-SCRIPT}

## requirements: 

bash support (you don't have a bash ?????)
dig (dns utility, just google how to install dig on ubuntu/debian/centos/arch .....)

# 中文：

这货是用来自动完成 namesilo DNS-01 验证的。
如果你遇到这样的错误：

```
Could not choose appropriate plugin: The manual plugin is not working; there may be problems with your existing configuration.
The error was: PluginError('An authentication script must be provided with --manual-auth-hook when using the manual plugin non-interactively.',)
Attempting to renew cert (blog.zengrong.net) from /etc/letsencrypt/renewal/blog.zengrong.net.conf produced an unexpected error: The manual plugin is not working; there may be problems with your existing configuration.
The error was: PluginError('An authentication script must be provided with --manual-auth-hook when using the manual plugin non-interactively.',). Skipping.
``` 

说明你需要自己指定验证钩子脚本
通常这脚本就是 读取环境变量 添加对应的validation，然后等待验证 的东西

嗯。脚本比较简单，也没什么依赖，应该能看懂。


使用方法参见如上
所需依赖见上
