# AWS Redis Migration

## Overview
arm copies over the keys from an AWS Elasticache Redis cluster to another, monitoring for any key updates and keeping the keys updated from the source to the destination until the script is stopped.  This is mainly useful where commands like SLAVEOF are not permitted and can be useful with "live" migration situations.
