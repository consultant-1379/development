# Container
This docker container generates SD Documentation and stores it into OpenALM.

## Configure how and what to generate
There are two sections in the file docker/automatic_documentation/configuration.yaml:

- docs_to_generate: documents to generate and how to generate it:
    - raml2html and rst2pdf: indicate folder and file(s) to generate
    - latexpdf: invoked by make. One input folder, one output folder and one or many output files
    
    Obviously, could be more commands to generate the documentation, if that is the case, it must be
    set in the configuration file. 

- folders: Documents to upload to OpenALM
    Physical files MUST be the same as the generated documents in the previous step, except the path to the file.
    The script move all files, once are generated, to a folder where the upload process take all of them
    
    - folder_name: the breadcrumb as it is in OpenALM, without "Project Documentation"
        I.e. if you go to OpenALM, and click in SD Micro-Service 1.1.0, you will see, in the upper zone, 
        "Location:  Project Documentation / SD Micro-Service 1.1.0". The folder_name will be SD Micro-Service 1.1.0.  

## How to build
Build the image named automatic-documentation for the repository. 

The docker environment needs the 5gcicd development git repository's base path to build the image, so it is needed to be executed from this path. 

```sh
$ docker build --no-cache -t armdocker.rnd.ericsson.se/<armdocker_repository>/automatic-documentation:<version> -f docker/automatic_documentation/Dockerfile .
```

## How to run
To run the built image use the following command:

```sh
$ docker run -i --rm armdocker.rnd.ericsson.se/<armdocker_repository>/automatic-documentation:<version>
```