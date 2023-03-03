# splunk-index-auto-argocd

```

Here's what this kustomization.yaml file does:

The namespace field specifies the namespace to deploy the Argo CD Application into.
The resources field specifies the YAML files that make up the Argo CD Application, in this case the namespace-annotations.yaml file we created earlier.
The patchesStrategicMerge field specifies a patch file to apply to the Argo CD Application. In this example, we'll create a patch file called patch-argocd-application.yaml that will add some additional metadata to the Argo CD Application.

In this case, the REPOSITORY_URL environment variable is set using the export command, which makes the variable available to the namespace-annotations.sh script.

I hope this clarifies things! Let me know if you have any further questions.

```

```

For example, to use the default input file (namespaces.txt), annotation key (splunk.com/index), and perform an actual annotation (not a dry run), you would execute the script without any arguments:

./annotate-namespaces.sh


To specify a different input file, annotation key, and annotation value, you could execute the script like this:

./annotate-namespaces.sh --file my-namespaces.txt --annotation-key mycompany.com/index --annotation-value myindexname


Note that you can use the --help option to see the available command-line arguments and their descriptions:

./annotate-namespaces.sh --help


you can skip passing the --annotation-value argument, and the script will read the annotation value from the input file for each namespace. If you don't specify the --annotation-value argument, the script will check each namespace to see if it already has the specified annotation key, and if it does, it will skip annotating that namespace. Otherwise, it will use the index name from the input file to annotate the namespace.

```

```bash

An example of what my-namespaces.txt might look like:

my-namespace-1 index1
my-namespace-2 index2
my-namespace-3 index3


```