# UETOMAE Automata stage

This is a Docker image to run [UETOMAE Automata](https://github.com/uetomae/automata) testing,
containing a Robot Framework.

This installation also contains Chrome, Selenium and Appium library for Robot Framework. The test
cases should be mounted as volumes.

## Run the container

This container can be run using the command below;

```
docker run \
    -v <local path to the test cases>:/var/autotest/test:Z \
    uetomae/automata-stage:<version>
```
