require 'net/http'
require 'json'

#FUNCTIONS TO GET THE JENKINS CONFIGURATION AND SAVE IN CONSTANTS
JENKINS_CONFIGURATION_FILENAME = '/jobs/cfg/jenkins_config.json'

def get_jenkins_uri (uri)
  file = File.read(JENKINS_CONFIGURATION_FILENAME)
  data_array = JSON.parse(file)
  uri = URI.parse(data_array['jenkins'][0]['Jenkins_uri'])
end

def get_jenkins_usr (usr)
  file = File.read(JENKINS_CONFIGURATION_FILENAME)
  data_array = JSON.parse(file)
  usr = data_array['jenkins'][0]['Jenkins_user']
end

def get_jenkins_pwd (pwd)
  file = File.read(JENKINS_CONFIGURATION_FILENAME)
  data_array = JSON.parse(file)
  pwd = data_array['jenkins'][0]['Jenkins_pass']
end

uri = get_jenkins_uri(uri)
usr = get_jenkins_usr(usr)
pwd = get_jenkins_pwd(pwd)

JENKINS_URI = uri

JENKINS_AUTH = {
  'name' => usr,
  'password' => pwd
}

def getFromJenkins(path)

  uri = URI.parse(path)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  if JENKINS_AUTH['name']
    request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
  end
  response = http.request(request)

  json = JSON.parse(response.body)
  return json
end

def getNameFromCulprits(culprits)
  culprits.each {
    |culprit|
    return culprit['fullName']
  }
  return ''
end


SCHEDULER.every '40s' do

  json = getFromJenkins(JENKINS_URI + 'api/json?pretty=true')

  failedJobs = Array.new
  succeededJobs = Array.new
  array = json['jobs']
  array.each {
    |job|

    next if job['color'] == 'disabled'
    next if job['color'] == 'notbuilt'
    next if job['color'] == 'blue'
    next if job['color'] == 'blue_anime'

    jobStatus = '';
    if job['color'] == 'yellow' || job['color'] == 'yellow_anime'
      jobStatus = getFromJenkins(job['url'] + 'lastUnstableBuild/api/json')
    elsif job['color'] == 'aborted' || job['color'] == 'aborted_anime'
      jobStatus = getFromJenkins(job['url'] + 'lastUnsuccessfulBuild/api/json')
    else
      jobStatus = getFromJenkins(job['url'] + 'lastFailedBuild/api/json')
    end

    culprits = jobStatus['culprits']

    culpritName = getNameFromCulprits(culprits)
    if culpritName != ''
       culpritName = culpritName.partition('<').first
    end

    failedJobs.push({ label: job['name'], value: culpritName})
  }

  failed = failedJobs.size > 0

  send_event('jenkinsBuildStatus', { failedJobs: failedJobs, succeededJobs: succeededJobs, failed: failed })
end
