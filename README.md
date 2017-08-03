# AWS Redis Migration

## Overview

arm copies over the keys from an AWS Elasticache Redis cluster to another, monitoring for any key updates and keeping the keys updated from the source to the destination until the script is stopped.  This is mainly useful where commands like SLAVEOF are not permitted and can be useful with "live" migration situations.

## Install

`gem install redis`

## Usage

On standard ports:

`./arm.rb source_host destination_host`

To change the ports:

`./arm.rb source_host source_port destination_host destination_port`
