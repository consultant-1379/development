require 'net/http'
require 'json'
require 'time'

#FUNCTIONS TO GET THE JENKINS CONFIGURATION AND SAVE IN CONSTANTS
JENKINS_CONFIGURATION_FILENAME = '/config/jenkins_config.json'

# The key of this mapping must be a unique identifier for your job,
# the according value must be the name that is specified in jenkins
job_mapping_jnksnr = {}

def get_jenkins_data_build_jnksnr(name_jenkins, key)
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

JENKINS_URI_BUILD_JNKSNR = URI.parse(get_jenkins_data_build_jnksnr('jnksnr-jenkins', 'uri'))
URI_SUFFIX_BUILD_JNKSNR = get_jenkins_data_build_jnksnr('jnksnr-jenkins', 'uri_suffix')
USER_BUILD_JNKSNR = get_jenkins_data_build_jnksnr('jnksnr-jenkins', 'user')
PASS_BUILD_JNKSNR = get_jenkins_data_build_jnksnr('jnksnr-jenkins', 'pass')
URI_SUFFIX_BUILD_JNKSNR = get_jenkins_data_build_jnksnr('jnksnr-jenkins', 'uri_suffix')
JENKINS_URI_BUILD_JNKSNR = URI.parse(get_jenkins_data_build_jnksnr('jnksnr-jenkins', 'uri'))

JENKINS_AUTH_BUILD_JNKSNR = {
  'name' => USER_BUILD_JNKSNR,
  'password' => PASS_BUILD_JNKSNR
}

# Getting all the jobs
def get_all_jenkins_jobs_jnksnr
  http = Net::HTTP.new(JENKINS_URI_BUILD_JNKSNR.host, JENKINS_URI_BUILD_JNKSNR.port)
  request = Net::HTTP::Get.new("/#{URI_SUFFIX_BUILD_JNKSNR}/api/json?tree=jobs[name]")
  if JENKINS_AUTH_BUILD_JNKSNR['name']
    request.basic_auth(JENKINS_AUTH_BUILD_JNKSNR['name'], JENKINS_AUTH_BUILD_JNKSNR['password'])
  end
  http.use_ssl = (JENKINS_URI_BUILD_JNKSNR.scheme == "https")
  response = http.request(request)
  all_jobs = {}
  if response.code == '200'
    parsed = JSON.parse(response.body)
    $i = 0
    while  $i < parsed["jobs"].length  do
      data_name = parsed["jobs"][$i]["name"]
      #puts data_name
      $i +=1
      all_jobs[data_name] = {:job => data_name}
    end
  end
  return all_jobs
end

def get_number_of_failing_tests_jnksnr(job_name)
  info = get_json_for_job_jnksnr(job_name, 'lastCompletedBuild')
  info['actions'][4]['failCount']
end

def get_completion_percentage_jnksnr(job_name)
  build_info = get_json_for_job_jnksnr(job_name)
  prev_build_info = get_json_for_job_jnksnr(job_name, 'lastCompletedBuild')
  return 0 if not build_info["building"]
  last_duration = (prev_build_info["duration"] / 1000).round(2)
  current_duration = (Time.now.to_f - build_info["timestamp"] / 1000).round(2)
  if current_duration >= last_duration
    return 99
  else
    return ((current_duration * 100) / last_duration).round(0)
  end
end

def get_json_for_job_jnksnr(job_name, build = 'lastBuild')
  job_name = URI.encode(job_name)
  http = Net::HTTP.new(JENKINS_URI_BUILD_JNKSNR.host, JENKINS_URI_BUILD_JNKSNR.port)
  request = Net::HTTP::Get.new("/#{URI_SUFFIX_BUILD_JNKSNR}/job/#{job_name}/#{build}/api/json")
  if JENKINS_AUTH_BUILD_JNKSNR['name']
    request.basic_auth(JENKINS_AUTH_BUILD_JNKSNR['name'], JENKINS_AUTH_BUILD_JNKSNR['password'])
  end
  http.use_ssl = (JENKINS_URI_BUILD_JNKSNR.scheme == "https")
  response = http.request(request)
  json_response = nil
  if response.code == '200'
    json = JSON.parse(response.body)
  end
  return json
end

job_mapping_jnksnr = get_all_jenkins_jobs_jnksnr

job_mapping_jnksnr.each do |title, jenkins_project|
  current_status = nil
  SCHEDULER.every '30s', :first_in => 0 do |job|
    last_status = current_status
    build_info = get_json_for_job_jnksnr(jenkins_project[:job])
    unless build_info.nil?
      current_status = build_info["result"]
      current_percent = 0
      if build_info["building"]
        current_status = "BUILDING"
        current_percent = get_completion_percentage_jnksnr(jenkins_project[:job])
      elsif jenkins_project[:pre_job]
        pre_build_info = get_json_for_job_jnksnr(jenkins_project[:pre_job])
        current_status = "PREBUILD" if pre_build_info["building"]
        current_percent = get_completion_percentage_jnksnr(jenkins_project[:pre_job])
      end
      title_jnksnr = "#{title}_jnksnr"
      send_event(title_jnksnr, {
        currentResult: current_status,
        lastResult: last_status,
        timestamp: build_info["timestamp"],
        value: current_percent
      })
    end
  end
end
