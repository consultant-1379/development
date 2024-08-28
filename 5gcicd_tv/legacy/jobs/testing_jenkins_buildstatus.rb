require 'net/http'
require 'json'

#FUNCTIONS TO GET THE JENKINS CONFIGURATION AND SAVE IN CONSTANTS
JENKINS_CONFIGURATION_FILENAME = '/config/jenkins_config.json'

def get_jenkins_data_build_status_testing(name_jenkins, key)
  file = File.read(JENKINS_CONFIGURATION_FILENAME)
  data_array = JSON.parse(file)
  $i = 0
  while $i < data_array['jenkins'].length do
    if data_array['jenkins'][$i]['name'] == name_jenkins
       return data_array['jenkins'][$i][key]
    end
    $i+=1
  end
  return ''
end

USER_BUILD_STATUS_TESTING = get_jenkins_data_build_status_testing('testing-jenkins', 'user')
PASS_BUILD_STATUS_TESTING = get_jenkins_data_build_status_testing('testing-jenkins', 'pass')
URI_SUFFIX_BUILD_STATUS_TESTING = get_jenkins_data_build_status_testing('testing-jenkins', 'uri_suffix')
JENKINS_URI_BUILD_STATUS_TESTING = URI.parse(get_jenkins_data_build_status_testing('testing-jenkins', 'uri'))

JENKINS_AUTH_BUILD_STATUS_STATUS_TESTING = {
  'name' => USER_BUILD_STATUS_TESTING,
  'password' => PASS_BUILD_STATUS_TESTING
}

def getNameFromCulprits_testing_testing(path)
  uri = URI.parse(path)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  if JENKINS_AUTH_BUILD_STATUS_STATUS_TESTING['name']
    request.basic_auth(JENKINS_AUTH_BUILD_STATUS_STATUS_TESTING['name'], JENKINS_AUTH_BUILD_STATUS_STATUS_TESTING['password'])
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

  json = getNameFromCulprits_testing_testing(JENKINS_URI_BUILD_STATUS_TESTING + '/#{JENKINS_URI_HISTORY_TESTING}/api/json?pretty=true')

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
      jobStatus = getNameFromCulprits_testing_testing(job['url'] + 'lastUnstableBuild/api/json')
    elsif job['color'] == 'aborted' || job['color'] == 'aborted_anime'
      jobStatus = getNameFromCulprits_testing_testing(job['url'] + 'lastUnsuccessfulBuild/api/json')
    else
      jobStatus = getNameFromCulprits_testing_testing(job['url'] + 'lastFailedBuild/api/json')
    end

    culprits = jobStatus['culprits']

    culpritName = getNameFromCulprits(culprits)
    if culpritName != ''
       culpritName = culpritName.partition('<').first
    end

    failedJobs.push({ label: job['name'], value: culpritName})
  }

  failed = failedJobs.size > 0

  send_event('jenkinsBuildStatus_testing', { failedJobs: failedJobs, succeededJobs: succeededJobs, failed: failed })
end
