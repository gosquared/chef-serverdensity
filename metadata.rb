name               "serverdensity"
maintainer         "Server Density"
maintainer_email   "hello@serverdensity.com"
license            "MIT"
description        "Installs/configures Server Density sd-agent"
long_description   IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version            "1.0.1"

depends "apt"

supports "ubuntu"

recipe "serverdensity::default", "Default"
recipe "serverdensity::install", "Installs, configures and starts sd-agent"
