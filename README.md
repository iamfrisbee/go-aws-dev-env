Create a .env file with the following values:

1. AWS_SSH_USER
1. AWS_ACCESS_KEY_ID
1. AWS_SECRET_ACCESS_KEY
1. AWS_DEFAULT_REGION
1. AWS_DEFAULT_OUTPUT
1. SSH_KEY_PATH

Then you can use the following docker-compose.yml to get a working environment

```yml
version: "3.1"
services:
  go:
    image: iamfrisbee/go-aws-dev-env
    environment:
      # needs your aws credentials in order to handle connections to aws
      - AWS_SSH_USER=${AWS_SSH_USER}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
      - AWS_DEFAULT_OUTPUT=${AWS_DEFAULT_OUTPUT}
    volumes:
      # needs to point your ssh key into the container
      - ${SSH_KEY_PATH}:/home/gouser/.ssh/id_rsa
```
