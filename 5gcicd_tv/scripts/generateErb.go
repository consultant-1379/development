package main

import (
    "encoding/json"
    "fmt"
    "io/ioutil"
    "os"
    "net/http"
    "flag"
    "regexp"
    "strings"
)
func check(e error) {
    if e != nil {
        panic(e)
    }
}

// Users struct which contains
// an array of jobs
type Jobs struct {
    Jobs []Job `json:"jobs"`
}

// Job struct which contains a job
// a type and a list of social links
type Job struct {
    Name    string `json:"name"`
    Url     string `json:"url"`
    Color   string `json:"color"`
}


// Functions

func curlPetition(url string) []byte {
    req, _ := http.NewRequest("GET", url, nil)
 
    res, _ := http.DefaultClient.Do(req)
 
    defer res.Body.Close()
    
    body, _ := ioutil.ReadAll(res.Body)

    return body
}

func secCurlPetition(url,jenkinsUser, jenkinsToken string) []byte {
    req, _ := http.NewRequest("GET", url, nil)

    req.SetBasicAuth(jenkinsUser, jenkinsToken)
 
    res, err1 := http.DefaultClient.Do(req)
    if err1 != nil {
        fmt.Print(err1)
    }
 
    defer res.Body.Close()
    
    body, err := ioutil.ReadAll(res.Body)
    if err != nil {
        fmt.Print(err)
    }

    return body
}

func readJsonFile(fileName string) []byte {

    body, err := ioutil.ReadFile(fileName)
    if err != nil {
        fmt.Print(err)
    }
    return body
}

func createDash(dashName, regexFilter string, body []byte) {
    
    // Create output file
    fileCurl, err := os.Create(dashName)
    check(err)
    defer fileCurl.Close()

    // initialize Jobs array and variables
    var jobsCurl Jobs
    var stringToWriteCurl string
    var initialString = "<div class=\"gridster\">\n<ul>\n"
    var finalString = "</ul>\n</div>"
    regexForServices, _ := regexp.Compile(regexFilter)
    // we unmarshal our byteArray which contains our
    // jsonFile's content into 'jobs' which we defined above
    json.Unmarshal(body, &jobsCurl)  

    // adding the style (override of default style)
    styleOverride, err := ioutil.ReadFile("styleOverride.erb") // just pass the file name
    if err != nil {
        fmt.Print(err)
    }

    strStyleOverride := string(styleOverride) // convert content to a 'string'

    fmt.Println(strStyleOverride) // print the content as a 'string'

    n2, err := fileCurl.WriteString(strStyleOverride)
    check(err)

    // adding style and headers
    fileCurl.WriteString(initialString)

    // adding body
    for i := 0; i < len(jobsCurl.Jobs); i++ {
        //If to check regex  r.MatchString("peach")
        if regexForServices.MatchString(jobsCurl.Jobs[i].Name) {
           formatedJobName := jobsCurl.Jobs[i].Name
           formatedUrlName := jobsCurl.Jobs[i].Url
           fmt.Println("URL Direction: ", formatedUrlName)
           strings.Replace(formatedJobName, "_", " ", -1)
           strings.Replace(formatedJobName, "-", " ", -1)
           fmt.Println("Formated Job Name: " + formatedJobName)
           stringToWriteCurl = "<li data-sizex=\"1\" data-sizey=\"1\">\n"+
               "<div data-id=\""+jobsCurl.Jobs[i].Name+"\", data-view=\"JenkinsBuild\", data-title=\""+formatedJobName+"\" data-min=\"0\" data-max=\"100\" , data-text=\"Jenkins\" onclick=\"window.open(\""+formatedUrlName+"\")\"></div>\n"+
               "</li>\n"
           n2, err = fileCurl.WriteString(stringToWriteCurl)
           check(err)
        }
    }

    // closing header tags
    _, err = fileCurl.WriteString(finalString)
    check(err)
    fmt.Printf("wrote: ", n2)
}
func main() {


    // Command line arguments
    url := flag.String("url", "", "Jenkins URL")
    
    dashboardName := flag.String("dash", "output.erb", "Name for the dashboard")
    
    userName := flag.String("user", "", "User name to access to Jenkins")

    apiToken := flag.String("token", "", "User token to access to Jenkins' API")

    regexFilter := flag.String("regex", ".*(AUSF|AUSF|NRF|NSSF|PCF|UDM|UDR|5G).*", "Regular expression used to filter Jenkins' Jobs")

    curlFile := flag.String("file", "", "File containing the result from the curl petition")     
    flag.Parse()
    


    // Getting all info with a curl petition
    if len(*url) > 0 {
       if (len(*userName) > 0) && (len(*apiToken) > 0){
         body := secCurlPetition(*url, *userName, *apiToken)
         // Create dashboard
         createDash (*dashboardName, *regexFilter, body)
       } else {
         body := curlPetition(*url)
         // Create dashboard
         createDash (*dashboardName, *regexFilter, body)
       }
    }

    //Getting all info from the file provided
    if len(*curlFile) > 0 {
        body := readJsonFile(*curlFile)
        // Create dashboard
       createDash (*dashboardName, *regexFilter, body)
    }
}