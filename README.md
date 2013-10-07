# shipper

Shipper is scriptable deployment for Docker containers.

## Overview

Shipper abstracts your stack to *servers* and *applications*. A server is
something that runs a Docker daemon. It could be an EC2 instance, a vagrant
box, or even another Docker container. An application is just a Docker
container.

Once you follow this abstraction, deploying and scaling your stack becomes
incredibly simple. Instead of baking and deploying machine images like AMIs,
you can just deploy an application to any running server.

Need another web server to handle an influx of requests in Japan? Just
```boot``` a new server and ```start``` your ```server.tar```.

## Installation

    $ npm install -g shipper

## Usage

### Images

Shipper currently uses Docker container images. You can generate an image by
running:

    $ docker export container > image.tar

### Shipfiles

Shipfiles are standalone scripts for deploying your servers and applications.
Simply create a file named ```Shipfile``` and run ```ship``` from the terminal.
Shipfiles are written in CoffeeScript.

#### Shipfile

````coffee
SIMPLE_SERVER =
  ec2:
    ami:             'ami-53aef83a'
    accessKey:       process.env.AWS_ACCESS_KEY
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    region:          'us-east-1'
    type:            't1.micro'
    securityGroups:  [ 'shipper' ]
    ssh:
      user: 'ubuntu'
      name: 'shipper'
      key:  '~/shipper.pem'

ship 'release', ->
  boot 'ec2', SIMPLE_SERVER, (err, server) ->
    server.start 'docker_image.tar', ['echo', 'hello world'], (err) ->
      console.log "upload: #{err}"

    server.start 'docker_image.tar', ['echo', 'hello world'], (err) ->
      console.log "upload: #{err}"
````

### Library

You can also use shipper as a node library. Just ```require('shipper')```
and use the same API as Shipfiles.

### CoffeeScript Example

````coffee
shipper = require 'shipper'
monitor = require './monitor'

monitor.on 'heavy traffic', ->
  shipper.boot 'ec2', WEB_SERVER, (err, server) ->
    server.start 'web server.tar', ['node', './server.js'], (err) ->
      console.log 'automatically scaled'
````

## API

### boot(provider, server, [overrides], callback)

* provider ```String``` The provider (e.g. ```ec2```) to use.
* server ```Object```
  * ec2 ```Object``` Amazon EC2 Configuration. (See below)
* overrides ```Object``` Any additional overrides. (See below)
* callback ```Function``` called when the server starts or an error occurs.
  * error ```Error```
  * server ```Server``` object

Provisions a new server on the specified provider. The provider, server, and
overrides arguments are split up so that you can define a semantic server and
then provision it across different providers without changing your code.

#### Amazon EC2

* ami ```String``` (See below)
* accessKey ```String```
* secretAccessKey ```String```
* region ```String``` (e.g. ```us-east-1```)
* type ```String``` (e.g. ```t1.micro```)
* securityGroups ```Array``` Security groups to apply. (See below)
* ssh ```Object``` SSH Configuration
    * user ```String``` SSH user
    * name ```String``` AWS key-pair name.
    * key ```String``` Path to private key file.
    * port ```Integer``` (default: 22)

Launches an Amazon EC2 instance of the given AMI, connects to it via SSH
and creates a tunnel to the Docker daemon. Note that ```securityGroups```
must contain a group that allows inbound access to ```ssh.port```.

The AMI must be running Linux 3.8 or above, and have an SSH and Docker daemon
installed and configured. We created ```ami-53aef83a``` on us-east-1 that you
can use for now.

### Class: Server

```Server``` is not intended to be used directly. Use the ```boot()``` method
to create a new Server instance.

#### server.start(image, command, [options], callback)

* image ```String``` Path to a Docker container image.
* command ```Array``` The command to execute on the container.
* callback ```Function``` called when the application has started.
  * error ```Error```

The specified image will be uploaded to the server, and a new container will
be created and started.

## License

Copyright (c) 2013 Gerald Monaco. See the LICENSE.md file for license rights
and limitations (MIT).