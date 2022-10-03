# Simulate Load / Stream

In order to create some fictional load and push to the deployed Azure Function responsible for the ingestion of the user activities, we will be using Artilery.io library. The following two commands are needed to start the process.

Replace the two values in `default.yaml` file for target (the ingestion function Url) and the respective code header (x-functions-key).

```sh
# Install npm package
npm install -g artillery

# Command line to run test
artillery run default.yaml
```