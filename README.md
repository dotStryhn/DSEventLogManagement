# DSEventLogManagement

Basically you can save your configuration of your different EvenLogs in XML and compare at a later point, to make sure that
your configuration havent changed, when using -Verbose you will be able to see the differences, otherwise it will just return
true or false.

I made this since I needed a quick and easy way to manage forwarded events logs, since ForwardedEvents isn't handled the same
way as normal EventLogs, but these functions are useable on all the eventlogs, and when using verbose, you will also see
warnings if they dont exist, or you don't have access.
