AuthProxy
=========

This is an HTTP proxy server that will log into specific web servers for
you so that you can work with a client that has troubles with basic
authentication. I developed it specifically for testing a server that
required basic authentication with Selenium, which has a real hard time
working right with basic authentication. It should also work on a server
with digest authentication, although I haven't tested it against a real
server using digest authentication.

To use it, create a file called authinfo.yml with your login credentials
in the config directory. An example is shown in
config/authinfo.example.yml. Then run the proxy like this:

    ruby lib/proxy.rb

You'll need to tell your client to use the proxy. To do that in
selenium, you can use something like this:

    require 'rubygems'
    require 'selenium-webdriver'

    profile = Selenium::WebDriver::Firefox::Profile.new
    profile["network.proxy.type"] = 1
    profile["network.proxy.http"] = "localhost"
    profile["network.proxy.http_port"] = 9090
    driver = Selenium::WebDriver.for(:firefox, :profile => profile)
    driver.navigate.to 'http://my-basic-auth-server.com'

It runs on port 9090. Changing it to use another port is left as an
exercise for the reader.

Unit tests can be run by typing `rake` from the project root folder.