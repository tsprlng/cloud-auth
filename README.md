Strategies for "cloud" CLI authentication
-----------------------------------------

Well, there's already an obvious strategy, but I don't like it.

Both the standard `aws` and `gcloud` tools, not to mention `kubectl`, like to give you a global configuration that applies to your whole session.

For me, this is a disaster waiting to happen -- I like to be very clear about the difference between messing about in general and doing stuff on a production environment.

Instead I like to use a wrapper script for using tools / scripts with temporary authorization in a particular account or project.

Having built essentially the same thing a few times now, this is an example of a way to get that kind of thing done.

You would use it a bit like this:

```
$ aws-environment production acm list-certificates
$ aws-environment production -- ./terraform-wrapper plan
$ aws-account production ec2 describe-vpcs
```

This relates to a typical abstraction where a project might have various different "environments" representing different versions of a product (sandbox, production, etc.) as well as perhaps different active regions within a given version.

The aws-environment script is a lot like the aws-account script, except it also sets an "environment variable" with the given name, to make it easier to pick up from other tools -- and also sets the standard AWS_DEFAULT_REGION and AWS_REGION variables to the given environment's primary region, as a convenience.

Both of these tools rely on shared config files, `accounts.yml` and `environments.yml` in a particular format to tell them what all these things are.

There would also be a user-specific config file at `~/.config/company.yml` to hold per-user config, such as the username to log in with.


Caveat
------

This repo isn't actual code that has actually been used or tested, it's a sort of half-baked extraction of one version of it from one company, so it's more of an example / documentation (for my future self, even) than anything else.


Actual strategy
---------------

The AWS example here is the better one, as it actually has legit security benefits over doing things the simpler way.

A kind of normal (perhaps not the _most_ normal) way of laying stuff out in AWS: have a root account which you physically log into with a normal IAM user, and then have a separate account for production services which you can only access by switching role into it.

You can also set restrictions so that this role-switching requires 2FA, and then even for command line access you will need a one-time password (classic 6-digit TOTP) and your computer will only hold a temporary token.

This is what the `aws-account` example here shows. The named account is the one to switch role into -- the basic login, out of which the role is switched, is always to a fixed root account, and a standard command line credential for that account is in that `~/.config/company.yml` file.

The key is that the credential itself, without 2FA being provided, only grants the permission to provide 2FA and switch to a different role which has actual permissions. This kind of thing is widely documented, generally quite awkwardly, so I'm not going to try and do a better job myself.

Sadly the U2F implementation in AWS leaves a lot to be desired (like multiple devices) and still doesn't have any command line support at the time of my writing this, so TOTP is the best we can practically do.

These days you can probably accomplish the same thing but better using AWS "single sign on", although I've never even made it through the documentation while staying awake, let alone actually trying to use the thing and risking messing everything up.


Bonus crap
----------

I've also included some similar gcloud scripts, although these don't work quite as well as they just share a single login. Which project to use is more of a "suggestion" as the user actually has access to everything the user has access to -- so a tool can decide to access a different project, and this method actually does nothing to prevent it.

However, it does at least make a convenient wrapper for switching automatically between different configurations, also preventing the default config being affected, and therefore should eliminate most typical accidents.

To get real, full isolation, I guess you'd need something like the AWS roles except with GCP service accounts. I don't really know as I've never had to use GCP in as serious of a context as AWS.
