require 'net/http'
require 'json'
require 'time'

#FUNCTIONS TO GET THE JENKINS CONFIGURATION AND SAVE IN CONSTANTS
JENKINS_CONFIGURATION_FILENAME = '/config/jenkins_config.json'

# The key of this mapping must be a unique identifier for your job,
# the according value must be the name that is specified in jenkins
job_mapping_fem101 = {}

def get_jenkins_data_build_fem101(name_jenkins, key)
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

USER_BUILD_FEM101 = get_jenkins_data_build_fem101('fem101-eiffel012-jenkins', 'user')
PASS_BUILD_FEM101 = get_jenkins_data_build_fem101('fem101-eiffel012-jenkins', 'pass')
URI_SUFFIX_BUILD_FEM101 = get_jenkins_data_build_fem101('fem101-eiffel012-jenkins', 'uri_suffix')
JENKINS_URI_BUILD_FEM101 = URI.parse(get_jenkins_data_build_fem101('fem101-eiffel012-jenkins', 'uri'))

JENKINS_AUTH_BUILD_FEM101 = {
  'name' => USER_BUILD_FEM101,
  'password' => PASS_BUILD_FEM101
}

# Getting all the jobs
def get_all_jenkins_jobs_fem101
  http = Net::HTTP.new(JENKINS_URI_BUILD_FEM101.host, JENKINS_URI_BUILD_FEM101.port)
  request = Net::HTTP::Get.new("/#{URI_SUFFIX_BUILD_FEM101}/api/json?tree=jobs[name]")
  if JENKINS_AUTH_BUILD_FEM101['name']
    request.basic_auth(JENKINS_AUTH_BUILD_FEM101['name'], JENKINS_AUTH_BUILD_FEM101['password'])
  end
  response = http.request(request)
  parsed = JSON.parse(response.body)
  $i = 0
  all_jobs_fem101 = {}
  while  $i < parsed["jobs"].length  do
    data_name = parsed["jobs"][$i]["name"]
    #puts data_name
    $i +=1
    all_jobs_fem101[data_name] = {:job => data_name}
  end
  return all_jobs_fem101
end

def get_number_of_failing_tests_fem101(job_name)
  info = get_json_for_job_fem101(job_name, 'lastCompletedBuild')
  info['actions'][4]['failCount']
end

def get_completion_percentage_fem101(job_name)
  build_info = get_json_for_job_fem101(job_name)
  prev_build_info = get_json_for_job_fem101(job_name, 'lastCompletedBuild')

  return 0 if not build_info["building"]
  last_duration = (prev_build_info["duration"] / 1000).round(2)
  current_duration = (Time.now.to_f - build_info["timestamp"] / 1000).round(2)
  return 99 if current_duration >= last_duration
  ((current_duration * 100) / last_duration).round(0)
end

def get_json_for_job_fem101(job_name, build = 'lastBuild')
  job_name = URI.encode(job_name)
  http = Net::HTTP.new(JENKINS_URI_BUILD_FEM101.host, JENKINS_URI_BUILD_FEM101.port)
  request = Net::HTTP::Get.new("/#{URI_SUFFIX_BUILD_FEM101}/job/#{job_name}/#{build}/api/json")
  if JENKINS_AUTH_BUILD_FEM101['name']
    request.basic_auth(JENKINS_AUTH_BUILD_FEM101['name'], JENKINS_AUTH_BUILD_FEM101['password'])
  end
  response = http.request(request)
  JSON.parse(response.body)
end

job_mapping_fem101 = get_all_jenkins_jobs_fem101

job_mapping_fem101.each do |title, jenkins_project|
  current_status = nil
  SCHEDULER.every '20s', :first_in => 0 do |job|
    last_status = current_status
    build_info = get_json_for_job_fem101(jenkins_project[:job])
    current_status = build_info["result"]
    if build_info["building"]
      current_status = "BUILDING"
      percent = get_completion_percentage_fem101(jenkins_project[:job])
    elsif jenkins_project[:pre_job]
      pre_build_info = get_json_for_job_fem101(jenkins_project[:pre_job])
      current_status = "PREBUILD" if pre_build_info["building"]
      percent = get_completion_percentage_fem101(jenkins_project[:pre_job])
    end

    send_event("#{title}_fem101", {
      currentResult: current_status,
      lastResult: last_status,
      timestamp: build_info["timestamp"],
      value: percent
    })
  end
end