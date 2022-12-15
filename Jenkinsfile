#!/bin/groovy

@Library('pipeline-library')
import io.polarpoint.workflow.*

properties([
    buildDiscarder(
      logRotator(
        artifactDaysToKeepStr: '30',
        artifactNumToKeepStr: '10',
        daysToKeepStr: '30',
        numToKeepStr: '10'
      )
    ),
])

invokeDockerPipeline("terraform-docs-gh-actions", "pipelines/configuration.json")
