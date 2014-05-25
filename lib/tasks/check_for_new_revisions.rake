
task :check_for_new_revisions => :environment do
  since = 6.hours
  timestamp = Time.now - since
  trigger = 'cron'
  client = InchCI::Worker::Project::UpdateInfo::GitHubInfo.client

  projects = InchCI::Store::FindAllProjects.call()

  projects = projects.select do |project|
    if latest = InchCI::Store::FindLatestBuildInProject.call(project)
      latest.finished_at && latest.finished_at < timestamp
    end
  end

  enqueued_builds = []

  projects.each do |project|
    branch = project.default_branch
    last_commit = client.commits(project.name, branch.name).first
    rev = InchCI::Store::FindRevision.call(branch, last_commit.sha)
    if rev.nil?
      enqueued_builds << InchCI::Worker::Project::Build.enqueue(project.repo_url, branch.name, nil, trigger)
    end
  end

  puts [
        Time.now,
        "checked #{projects.size} projects",
        "enqueued #{enqueued_builds.size} builds:",
        enqueued_builds.map(&:id).inspect
      ].map(&:to_s).join("\t")
end
