require 'net/http'
require 'json'

#FUNCTIONS TO GET THE JENKINS CONFIGURATION AND SAVE IN CONSTANTS
JENKINS_CONFIGURATION_FILENAME = '/config/jenkins_config.json'

def get_jenkins_data_build_status_jnksnr(name_jenkins, key)
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

URI_SUFFIX_BUILD_STATUS_JNKSNR = get_jenkins_data_build_status_jnksnr('jnksnr-jenkins', 'uri_suffix')
JENKINS_URI_BUILD_STATUS_JNKSNR = URI.parse(get_jenkins_data_build_status_jnksnr('jnksnr-jenkins', 'uri'))
USER_BUILD_STATUS_JNKSNR = get_jenkins_data_build_status_jnksnr('jnksnr-jenkins', 'user')
PASS_BUILD_STATUS_JNKSNR = get_jenkins_data_build_status_jnksnr('jnksnr-jenkins', 'pass')

JENKINS_AUTH_BUILD_STATUS_STATUS_JNKSNR = {
  'name' => USER_BUILD_STATUS_JNKSNR,
  'password' => PASS_BUILD_STATUS_JNKSNR
}

def getFromJenkins_jnksnr(path)
  uri = URI.parse(path)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  if JENKINS_AUTH_BUILD_STATUS_STATUS_JNKSNR['name']
    request.basic_auth(JENKINS_AUTH_BUILD_STATUS_STATUS_JNKSNR['name'], JENKINS_AUTH_BUILD_STATUS_STATUS_JNKSNR['password'])
  end
  response = http.request(request)
  json_response = nil
  response = http.request(request)
  if response.code == '200'
    json = JSON.parse(response.body)
  end
  return json
end

def getNameFromCulprits_jnksnr(culprits)
  culprits.each {
    |culprit|
    return culprit['fullName']
  }
  return ''
end

SCHEDULER.every '40s' do

  json = getFromJenkins_fem101(JENKINS_URI_BUILD_STATUS_FEM101 + '/#{JENKINS_URI_HISTORY_FEM101}/api/json?pretty=true')
  unless json.nil?
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
        jobStatus = getFromJenkins_jnksnr(job['url'] + 'lastUnstableBuild/api/json')
      elsif job['color'] == 'aborted' || job['color'] == 'aborted_anime'
        jobStatus = getFromJenkins_jnksnr(job['url'] + 'lastUnsuccessfulBuild/api/json')
      else
        jobStatus = getFromJenkins_jnksnr(job['url'] + 'lastFailedBuild/api/json')
      end

      culprits = jobStatus['culprits']

      culpritName = getNameFromCulprits_jnksnr(culprits)
      if culpritName != ''
         culpritName = culpritName.partition('<').first
      end

      failedJobs.push({ label: job['name'], value: culpritName})
    }

    failed = failedJobs.size > 0
    send_event('jenkinsBuildStatus_jnksnr', { failedJobs: failedJobs, succeededJobs: succeededJobs, failed: failed })
  end
end
