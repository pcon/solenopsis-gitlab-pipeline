# Gitlab Pipelines

The gitlab pipelines for this project provides the following functionality

* [Merge Requests](README.md#merge-requests)
    * Quality Assurance
    * Test Deployment
* [Main Branch Commit](README.md#merge-to-main-branch)
    * Quality Assurance
    * Dev Deployment
    * Dev Tests
* [Tag Commit](README.md#tag-creation)
    * Quality Assurance
    * QA & Stage Deployment
    * QA & Stage Tests
    * Quick Deployment to Prod

## File Structure
The deployment process is initialized by the `.gitlab-ci.yml` file that utilizes data in the `.gitlab` folder.  In the `.gitlab` folder there are several key sub-folders

### `.gitlab-ci.yml`
All of the pipelines run using a custom image called `sfdc-base` that contains Solenopsis and nodeJS.  This file then defines the base jobs for each [pipeline stage](README.md#pipeline-stages).  It then includes each environment's template from the [template directory](README.md#gitlabtemplates) to simplify the main file.  This does lead to issues where aliases defined in the main file cannot be referenced in the later template files.

### `.gitlab/config`
The config folder contains configuration files for Solenopsis deployments.  This provides the `solenopsis.properties` file as well as credential files for each environment.  These credential files **SHOULD NOT** include usernames, passwords or tokens.  They should only include Solenopsis data that is used for substitutions or API version information.  Username, passwords and tokens are set during the `buildSecrets` step in the deployment.  Read below for more information on how [credentials are handled](README.md#buildsecretssh).

### `.gitlab/scripts`
The scripts folder contains various scripts to make the Gitlab YAML more readable as well as to make it so that Solenopsis errors can cause the pipeline stages to fail.  Additionally, the `slack` sub-folder contains scripts to notify Slack about the status of various jobs.  Read below more on how [Slack notifications](README.md#slack-notifications) work.

### `.gitlab/templates`
The templates folder breaks out each type of the pipeline into its own manageable chunk to reduce the complexity of the main `.gitlab-ci.yml` file.  The `slack` folder contains JSON templates used by the Slack scripts to send [Slack notifications](README.md#slack-notifications).

### `.gitlab/vars`
The vars folder contains encrypted data for each environment.  This provides the data to the [buildSecrets](README.md#buildsecretssh) script

## Pipeline stages
### `quality`
#### before_script
In the before, we setup the directories so that the Slack scripts can use the `TEMP_DIR` for its [templates](templates/slack/) and then sends the first message to Slack saying that the deployment has started.  Read below on how [Slack notifications](README.md#slack-notifications) handle threading between jobs.

#### script
Calls the [`qa.sh`](scripts/qa.sh) script to run the `@TestClasses` annotation checker and PMD.

#### after_script
Calls `notifySlackAfter` to either set the reaction of `sunny` or `no_entry_sign` depending on if the script is successful or fails.

### `deploy`
#### before_script
Sends a threaded notification to Slack that the job is starting.

#### script
Sets up Solenopsis and its credential file.  Then runs the [`deploy.sh`](scripts/deploy.sh) script to push the repo to the environment.

#### after_script
Calls `notifySlackAfter` to either set the reaction of `check` or `no_entry_sign` depending on if the script is successful or fails.

### `tests`
#### before_script
Sends a threaded notification to Slack that the job is starting.

#### script
Sets up Solenopsis and its credential file.  Then runs the [`runtests.sh`](scripts/runtests.sh) script to run all the tests in the environment.

#### after_script
Calls `notifySlackAfter` to either set the reaction of `mortar_board` or `no_entry_sign` depending on if the script is successful or fails.

### `prod_deploy`
#### before_script
Sends a threaded notification to Slack that the job is starting.

#### script
Sets up Solenopsis and its credential file.  Then runs the [`deploy_fast.sh`](scripts/deploy_fast.sh) script to do a fast deployment to production and to stage the deployment for release.

#### after_script
Calls `notifySlackAfter` to either set the reaction of `tada` or `no_entry_sign` depending on if the script is successful or fails.

## Pipeline script notes
### buildSecrets.sh
Credentials are stored on disk in the [`.gitlab/config`](config) folder and are encrypted.  These are then decrypted inside the [`buildSecrets.sh`](scripts/buildSecrets.sh) script.  This script utilizes an openshift container to decode the credentials and export them as environment variables.  Because of how bash works, this file must be called with `source` to access the exported variables.

### createDeploymentProperties.sh
The [`createDeploymentProperties.sh`](scripts/createDeploymentProperties.sh) script copies the config for the provided `ENV` variable to a environment called `instance` and then appends the username, password and token from the [buildSecrets.sh](README.md#buildsecretssh) script to the `.solenopsis/credentials/instance.properties` file.

## Pipeline Entry Points
### Merge Requests
**Template -** [`mr.yml`](templates/mr.yml) ~ **Environment -** [`dev`](config/credentials/dev.properties)

| Stage | Name |
| :---: | :--: |
| quality | `mr_quality` |
| deploy | `mr_deploy` |
| tests | - |
| prod_deploy | - |

Merge request deploy stage differs from other deploy stages as it utilizes the `--dryrun` flag in Solenopsis to only test the deployment.  Currently this is of some limited use because the dry run does not do a "compile" of the code against Salesforce.  It only validates that the `package.xml` and `deploy.zip` can be created.  In the future we may be able to do something with the Sandbox API and [Quick Clone](https://developer.salesforce.com/blogs/2022/09/sandboxes-on-hyperforce-quick-clone-is-generally-available).  This will require our dev sandbox to be on Hyperforce.

### Merge to main branch
**Template -** [`dev.yml`](templates/dev.yml) ~ **Environment -** [`dev`](config/credentials/dev.properties)

| Stage | Name |
| :---: | :--: |
| quality | `dev_quality` |
| deploy | `dev_deploy` |
| tests | `dev_tests` |
| prod_deploy | - |

The tests stage for dev differs from QA and Stage in that it does not run for every deployment.  Instead, `dev_tests` is a scheduled job that is run nightly.

### Tag creation
When a tag is created, three separate pipelines are available.  One for QA, Stage and Prod.  Each of these pipelines are initiated by a manual start of the job from the pipeline or tag page.

#### QA
**Template -** [`qa.yml`](templates/qa.yml) ~ **Environment -** [`qa`](config/credentials/qa.properties)

| Stage | Name |
| :---: | :--: |
| quality | - |
| deploy | `qa_deploy` |
| tests | `qa_tests` |
| prod_deploy | `qa_prod_deploy` |

#### Stage
**Template -** [`stage.yml`](templates/stage.yml) ~ **Environment -** [`stage`](config/credentials/stage.properties)

| Stage | Name |
| :---: | :--: |
| quality | - |
| deploy | `stage_deploy` |
| tests | `stage_tests` |
| prod_deploy | `stage_prod_deploy` |

#### Prod
**Template -** [`prod.yml`](templates/prod.yml) ~ **Environment -** [`prod`](config/credentials/prod.properties)

| Stage | Name |
| :---: | :--: |
| quality | - |
| deploy | `prod_deploy` |
| tests | - |
| prod_deploy | - |

This pipeline is drastically different from the QA and Stage pipelines.  The only stage in this pipeline is a deploy.  It _does not_ use the same deploy process as the other pipelines.  While it is labeled as a `deploy` stage, it extends the `deployProd` job.  Also, since it does not have a `quality` stage, it has a custom `before_script` to make a notification to Slack when it starts.

## Slack Notifications
Slack notifications are handled by making a cURL request to the Slack API.  This is passed a bot token that is stored as a project level variable of `SLACK_BOT_TOKEN`.  Additionally, the specific channel the notifications go to are stored in the project level variable `SLACK_CHANNEL`

### Scripts
There are three wrapper scripts that encompass all of the Slack notifications.

#### notifySlackBefore.sh
The [`notifySlackBefore.sh`](scripts/slack/notifySlackBefore.sh) script is called by before the job starts in a pipeline.  If the `FIRST_JOB` environment variable is supplied then the a pipeline message will be created to thread against and will be formatted containing the commit message and various links.  This will then store the timestamp response (`.ts`) for later use.  It will then call the `notifySlackThread.sh` script to thread the job specific message.

#### notifySlackThread.sh
The [`notifySlackThread.sh`](scripts/slack/notifySlackThread.sh) script is called by the `notifySlackBefore.sh` script from subsequent jobs running in a pipeline.  It puts messages in a thread provided by the `notifySlackBefore.sh` script.  This script relies on the `THREAD_MESSAGE` variable being set and sends its content.  This data can be formatted with markdown.

#### notifySlackAfter.sh
The [`notifySlackAfter.sh`](scripts/slack/notifySlackAfter.sh) script is called at the end of every job.  This script then looks at the job's status and then either adds the appropriate emoji (see each [pipeline entry point](README.md#pipeline-entry-points) for specific emojis) for success or failure.

### Timestamp Persistence
Because each job in a Gitlab pipeline is run on it's own runner without access to the previous jobs environment variables, the slack timestamp of the original message must be passed from job to job.  This is done by defining a `.env` file and storing that as an artifact to use in subsequent jobs.

### Disabling Notifications Per Job
Some jobs do not need to send notifications to Slack.  For example each merge request should not send it's status to Slack.  To disable Slack notifications for a given job set the `SLACK_SKIP` to `true`.  See the [merge request pipeline](templates/mr.yml) for an example.

## Maintenance Tasks
### Increasing `apiVersion` / `version`
When the version of Salesforce being deployed to needs to be bumped, this is simply done by changing the `apiVersion` and `version` field in the `.gitlab/config/credentials` file for the appropriate environment.  Typically these are all done at the same time but if a out of band deployment has to happen while some are being changed the tag that is being pushed should have the older version set in whatever environments are being pushed to.

### Changing Passwords or Tokens
The secrets stored in the various YAML files in `vars` are decrypted using the (PaaS Secret Encrypter CLI](https://gitlab.corp.redhat.com/paas/paas-encryption-cli).

To update a token run the following command and place the base64 data into the appropriate YAML file replacing.

```bash
echo -n "n3wP@ssword" | paas-secret-encryption-cli --env=preprod --tenant=sfdc --raw --raw-base64 --from-file=/dev/stdin
```

_NOTE: When generating tokens for pre-prod, leave `preprod` in the command above.  When generating tokens for prod, change `preprod` to `prod`._