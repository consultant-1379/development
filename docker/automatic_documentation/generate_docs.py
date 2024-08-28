import os
import yaml
import sys, traceback
import subprocess
import constants


class DocGenerator:

    def __init__(self):
        # Add hosts to /etc/hosts
        os.system("cat /home/scripts/hosts.new >> /etc/hosts")

        # Where to export the documents generated
        subprocess.call(["mkdir", "-p", constants.EXPORT_FOLDER],
                        stdout=open(os.devnull, 'wb'))

        # Where to clone the repo
        subprocess.call(["mkdir", "-p", constants.REPO_FOLDER],
                        stdout=open(os.devnull, 'wb'))

        # We need the repo, so we clone it
        subprocess.call(["git", "clone", "https://esdccci:Pcdlcci1@gerrit.ericsson.se/a/5gcicd/development",
                        constants.REPO_FOLDER], stdout=open(os.devnull, 'wb'))

        # Read the docs to generate
        self.docs_to_generate = yaml.load(open("configuration.yaml"))["docs_to_generate"]

    def generate_docs(self):
        for howto in self.docs_to_generate:
            if howto != "make":
                docs = self.docs_to_generate.get(howto)
                for doc in docs:
                    infile = doc["folder"] + "/" + doc["input"]
                    outfile = doc["folder"] + "/" + doc["output"]
                    print "==> GENERATING " + infile + " IN " + outfile
                    subprocess.call([howto, infile, "-o", outfile],
                                    stdout=open(os.devnull, 'wb'),
                                    stderr=open(os.devnull, 'wb'))
                    print "    MOVING " + outfile + " TO " + constants.EXPORT_FOLDER
                    subprocess.call(["mv", outfile, constants.EXPORT_FOLDER],
                                    stdout=open(os.devnull, 'wb'),
                                    stderr=open(os.devnull, 'wb'))
            else:
                makewhats = self.docs_to_generate.get(howto)
                for makewhat in makewhats:
                    inputfolder = makewhat.values()[0].get("inputfolder")
                    outputfolder = makewhat.values()[0].get("outputfolder")
                    outfiles = makewhat.values()[0].get("outputfiles")
                    print "==> EXECUTING make " + str(dict(makewhat).keys()[0]) + " IN " + inputfolder
                    os.system("cd " + inputfolder + " && make " + str(dict(makewhat).keys()[0]) +
                              "> /dev/null 2>&1")
                    for outfile in outfiles:
                        outfile = outputfolder + "/" + outfile
                        print "    MOVING " + outfile + " TO " + constants.EXPORT_FOLDER
                        subprocess.call(["mv", outfile, constants.EXPORT_FOLDER],
                                        stdout=open(os.devnull, 'wb'),
                                        stderr=open(os.devnull, 'wb'))

def main():
    try:
        generator = DocGenerator()
        generator.generate_docs()
        return 0
    except:
        print "THERE HAS BEEN AN ERROR GENERATING DOCUMENTS"
        print '-' * 60
        traceback.print_exc(file=sys.stdout)
        print '-' * 60
        return 1

if __name__ == "__main__":
    ret = main()
    sys.exit(ret)
