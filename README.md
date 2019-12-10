# ibmcloud-dev image

## Development

The docker tag is determined from the version number in the package.json.

### Build the image

`npm run build`

### Test the image

`npm test`

The repo uses `gcr.io/gcp-runtimes/container-structure-test` to validate the image against the configuration defined in `config.yaml`. 

*Use TDD*

Before adding a new tool or script to the image, add the expected outcome to the `config.yaml` file following the patterns already established. Run the test and watch it fail, then update the image with the changes and run the test again.

### Start the image

`npm start`

### Push the image

. Log into docker hub with an id that has access to the `garagecatalyst` org with `docker login` 

. Update the version number in `package.json` with the new version number for the tag

. Commit the changes - `git commit`

. Tag the commit - `git tag v{version number}` where `{version number}` matches the version number in package.json

. Push the commit - `git push`

. Push the tag - `git push --tags`

. Push the image - `npm run push`

