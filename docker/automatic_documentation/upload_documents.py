# -*- coding: utf-8 -*-
from selenium import webdriver
from pyvirtualdisplay import Display
import time, yaml, os
import sys, traceback
import constants


class Uploader:
    def __init__(self):
        # This binary is to allow access to the web
        url_arm_dev_generic = "https://arm.lmera.ericsson.se/artifactory/proj-5g-cicd-generic-local"
        os.system("mkdir -p /tmp/binaries")
        os.system("/home/scripts/arm_download_file.sh \"/tmp/binaries/\" " + url_arm_dev_generic +
                  " \"geckodriver/1.0\" \"geckodriver.tar.gz\"")
        os.system("tar -zxvf /tmp/binaries/geckodriver/1.0/geckodriver.tar.gz -C /home/scripts")
        os.system("rm -rf /tmp/binaries")

        self.display = Display(visible=0, size=[800, 600])
        self.display.start()
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.base_url = "https://openalm.lmera.ericsson.se/projects/udm-5g-cicd-impl"
        self.verificationErrors = []
        self.accept_next_alert = True
        self.folders = yaml.load(open("configuration.yaml"))["folders"]

    def login(self, driver):
        driver.get(self.base_url + "/")
        driver.find_element_by_id("form_loginname").clear()
        driver.find_element_by_id("form_loginname").send_keys("esdccci")
        driver.find_element_by_id("form_pw").clear()
        driver.find_element_by_id("form_pw").send_keys("Pcdlcci1")
        driver.find_element_by_name("login").click()

    def upload_documents(self):
        driver = self.driver

        # Login
        self.login(driver)

        driver.get(self.base_url + "/projects/udm-5g-cicd-impl")
        driver.find_element_by_css_selector("span[title=\"Document Manager\"]").click()

        for folder in self.folders:
            # First, click in main option (Document Manager), and in main folder
            driver.get(self.base_url + "/projects/udm-5g-cicd-impl")
            driver.find_element_by_css_selector("span[title=\"Document Manager\"]").click()

            # Take all elements of folder - 1
            folders_to_click = str(folder['folder_name']).split("/")
            if len(folders_to_click) == 1:
                driver.find_element_by_link_text(folders_to_click[0]).click()
            else:
                for folder_to_click in folders_to_click[:-1]:
                    driver.find_element_by_link_text(folder_to_click).click()

            # Look for the folder where the files to upload go
            # Will be the last element in the list of folders
            folder_to_upload_to = str(folders_to_click[-1])
            driver.find_element_by_link_text(folder_to_upload_to).click()
            docs = folder['docs_to_upload']
            for doc in docs:
                # Upload the document
                doc_name = str(doc['name'])
                filename = str(doc['file'])

                print "==> UPLOADING \"" + filename + "\" TO \"" + folder_to_upload_to + "/" + doc_name + "\""

                doc_to_upload_link = driver.find_element_by_link_text(doc_name)
                document_href = str(doc_to_upload_link.get_property("href"))
                index = document_href.find("&id=")
                id = document_href[index + 4:]
                driver.find_element_by_id("docman_item_show_menu_" + id).click()
                driver.find_element_by_link_text("New version").click()

                driver.find_element_by_name("version[label]").clear()
                version = time.strftime("%d/%m/%Y") + " " + time.strftime("%H:%M:%S")
                driver.find_element_by_name("version[label]").send_keys(version)
                driver.find_element_by_name("file").clear()
                driver.find_element_by_name("file").send_keys(constants.EXPORT_FOLDER + filename)
                driver.find_element_by_css_selector("input[type=\"submit\"]").click()

    def teardown(self):
        self.driver.quit()
        self.display.stop()


def main():
    try:
        uploader = Uploader()
        uploader.upload_documents()
        uploader.teardown()
    except:
        print "THERE HAS BEEN AN ERROR UPLOADING DOCUMENTS"
        print '-' * 60
        traceback.print_exc(file=sys.stdout)
        print '-' * 60

if __name__ == "__main__": main()
