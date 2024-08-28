# Configure ADP CI/CD Dashboard chart

ADP CI/CD dashboard is a portable dashboard packed as a Helm chart meant to report the overall status of ADP end-to-end pipelines. The dashboard displays one summary page with all the ADP pipelines and one detailed information page for each pipeline.
The content of ADP CI/CD dashboard can be configured editing the values file in the chart. Two parameters in values file shall be edited to modify the dashboard content: 
- `pages`,
- `builds`.

Parameter `pages` contains the list of names of the pipelines to display in the dashboard. The dashboard will create a page named `<flow>_dashboard` for each item `<flow>` in this list.
Example:

```
pages:
  - log
  - cm
  - pm
  - fm
  - erikube
```

Parameter `builds` contains the detailed definition of the pipelines to show in the dashboard in JSON format. JSON structure is the following:

```
  {
    "flows" :
    [
      {
        "id": <string>,
        "builds":
        [
          {
            "id": <string> [mandatory],
            "url": <string> [mandatory],
            "server": <string> [mandatory],
            "user": <string>,
            "password": <string>,
            "job-name": <string>,
            "pretty-name": <string>,
            "stop-on-failure": <string>,
            "info": <string>,
            "filter": { "<key>" : "<value>" }
          }
        ],
        "lastStable":
        {
          "id": <string> [mandatory],
          "url": <string> [mandatory],
          "server": <string> [mandatory],
          "user": <string>,
          "password": <string>,
          "job-name": <string>,
          "pretty-name": <string>,
          "stop-on-failure": <string>,
          "info": <string>,
          "filter": { "<key>" : "<value>" }
        }
      }
    ],
    "criteria":
    [
      { 
        "id" : <string>,
        "text" : <string>
      }
    ]
  }
```

Description of each field:
- `flows`: array of pipelines to display in the summary page and in the detailed pipeline page. Each flow is described with following fields:
  - `id`: the unique identifier of the flow. It should match one of the names provided in `pages` in uppercases.
  - `builds`: ordered array of Jenkins builds polled by the dashboard. Each build will be represented as a tile in the corresponding pipeline. A build is made of following fields:
    - `id`: the unique identifier of the build. It shall be unique among all builds in all flows.
    - `url`: the url of the Jenkins server where the job is defined.
    - `server`: the name of the server (if no specific name just provide 'Jenkins').
    - `user`: the user name used to contact the Jenkins server. It shall be a user with read permissions. If no value is provided dashboard will try anonimous access.
    - `token`: the API token of the jenkins user. Only meaningful if `user` is provided.
    - `job-name`: the name of the job to poll on Jenkins. If no name is provided, dashboard will assume the name matches the `id` of the build.
    - `pretty-name`: the name to use when displaying the tile in the dashboard. If no name is provided, dashboard will use the `id` of the build.
    - `stop-on-failure`: indicates if dashboard shall consider the pipeline failed in case of failure on this job. Possible values are `true` or `false`, default value is `false`.
    - `info`: indicates if dashboard shall look for jobs metadata. If set to `artifacts`, dashboard will look for an artifact named `artifact.properties` containing the values `CHART_NAME` to report the name of the chart, and `CHART_VERSION` reporting the version of the chart. If set to `parameters` dashboard will look for the same parameters in job input parameters. If unset, Dashboard will not load any job metadata.
    - `filter`: indicates if dashboard should filter the builds for the specified job based on the input parameters. If specified dashboard will select only builds that have an input parameter named `<key>` matching the value of the `<value>`.

  - `lastStable`: a Jenkins build reporting the last stable release candidate for the flow. It contains the same fields of `builds`
- `criteria`: array of CI/CD criteria reported in the dashboard for each flow. Services shall indicate the compliance to these criteria in a Jenkins job artifact file named `adp-cicd-goals.properties`. A criterion is moda of following fields:
  - `id`: the unique identifier of the criterion. It should match the criteria identifiers reported in `adp-cicd-goals.properties`.
  - `text`: textual description of the criterion. The text will be visible in the dashboard detailed pipeline page.


# How to test the dashboard (with NodePort)

ADP CI/CD Dashboard can be launched just installing the chart:

Example on system with NodePort enabled (e.g. calipso):
```
helm install --name my-dashboard-5gcicd . --set service.nodePort=320xx --namespace my-namespace
```
Test new version
```
helm upgrade my-dashboard-5gcicd . --set service.nodePort=320xx
```

Note: default port is 30909, so choose another to test

# How to test the dashboard (with Ingress)

```
helm install --name dashboard-5gcicd-<namespace> . --set service.type=LoadBalancer --set ingress.host=dashboard-5gcicd.<namespace>.<systemname>.seli.gic.ericsson.se
```

Upgrade
```
helm upgrade dashboard-5gcicd-<namespace> . --set service.type=LoadBalancer --set ingress.host=dashboard-5gcicd.<namespace>.<systemname>.seli.gic.ericsson.se
```

# How to deploy to production (with NodePort)

Currently, calipso is the production system. Run the following command on calipso:
```
helm upgrade dashboard-5gcicd .
```

