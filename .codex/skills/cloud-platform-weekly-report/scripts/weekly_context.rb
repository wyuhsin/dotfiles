#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "json"
require "open3"
require "optparse"
require "pathname"
require "yaml"

options = {
  project_root: "/Users/haiwell/cloud-platform-management",
  date: Date.today,
  live: false,
  show_report_ids: false
}

OptionParser.new do |parser|
  parser.banner = "Usage: weekly_context.rb [options]"
  parser.on("--project-root PATH", "Report project root") { |value| options[:project_root] = value }
  parser.on("--date YYYY-MM-DD", "Any date in the target ISO week") { |value| options[:date] = Date.iso8601(value) }
  parser.on("--live", "Read DingTalk inbox and outbox through DWS") { options[:live] = true }
  parser.on("--show-report-ids", "Include IDs for refreshing existing local reports") { options[:show_report_ids] = true }
end.parse!

root = Pathname(options[:project_root]).expand_path
abort("project root not found: #{root}") unless root.directory?

def load_yaml(path)
  YAML.safe_load(path.read, permitted_classes: [Date], aliases: false)
end

def as_date(value)
  value.is_a?(Date) ? value : Date.iso8601(value.to_s)
end

def local_report_status(path)
  return nil unless path.file?

  match = path.read.match(/^status:\s*(\S+)\s*$/)
  match ? match[1] : "unknown"
end

def parse_dws_json(stdout)
  start = stdout.index("{")
  raise "DWS returned no JSON" unless start

  JSON.parse(stdout[start..])
end

def dws_page(command)
  stdout, stderr, status = Open3.capture3(*command)
  raise "DWS failed: #{stderr.strip[0, 300]}" unless status.success?

  parse_dws_json(stdout)
end

def report_pages(kind, period_start, period_end)
  cursor = 0
  pages = []

  20.times do
    command = [
      "dws", "report", kind, "list",
      "--start", "#{period_start}T00:00:00+08:00",
      "--end", "#{period_end}T23:59:59+08:00",
      "--cursor", cursor.to_s,
      "--size", "20",
      "--format", "json"
    ]
    page = dws_page(command)
    pages << page
    break unless page["hasMore"]

    next_cursor = page["nextCursor"] || page["cursor"]
    break if next_cursor.nil? || next_cursor.to_i == cursor

    cursor = next_cursor.to_i
  end

  pages
end

def compact_reports(pages, source)
  pages.flat_map do |page|
    commands = Array(page["_internalDetailCommands"]).each_with_object({}) do |item, result|
      report_id = item["command"].to_s[/--report-id\s+([^\s]+)/, 1]
      result[item["index"].to_i - 1] = report_id if report_id
    end

    Array(page["result"]).each_with_index.each_with_object([]) do |(item, index), reports|
      title = item["标题"].to_s
      sender = item["发送人"].to_s
      next unless title.include?("周报")

      reports << {
        "sender" => sender,
        "title" => title,
        "date" => item["日期"].to_s,
        "report_id" => commands[index],
        "source" => source
      }
    end
  end
end

target_date = options[:date]
iso_year = target_date.cwyear
iso_week = target_date.cweek
period_start = Date.commercial(iso_year, iso_week, 1)
period_end = Date.commercial(iso_year, iso_week, 7)
week_key = format("%<year>d-W%<week>02d", year: iso_year, week: iso_week)

department = load_yaml(root.join("data/department.yaml")).fetch("department")
members = load_yaml(root.join("data/members.yaml")).fetch("members")
sources = load_yaml(root.join("config/data-sources.yaml")).fetch("sources")
excluded = Array(department["excluded_member_ids"])

active_members = members.select do |member|
  active_from = as_date(member.fetch("active_from"))
  active_to = member["active_to"] && as_date(member["active_to"])
  !excluded.include?(member.fetch("id")) &&
    active_from <= period_end &&
    (active_to.nil? || active_to >= period_start)
end

remote_reports = []
department_reports = []
if options[:live]
  remote_reports.concat(compact_reports(report_pages("inbox", period_start, period_end), "inbox"))
  department_reports.concat(compact_reports(report_pages("outbox", period_start, period_end), "outbox"))
end

member_rows = active_members.map do |member|
  member_id = member.fetch("id")
  display_name = member.fetch("display_name")
  local_path = root.join("reports/member-weekly", iso_year.to_s, week_key, "#{member_id}.md")
  local_status = local_report_status(local_path)
  remote = remote_reports
           .select { |report| report["sender"] == display_name }
           .max_by { |report| report["date"] }

  action =
    if remote && local_status.nil?
      "fetch"
    elsif remote && local_status
      "skip"
    elsif local_status
      "local_only"
    else
      "missing"
    end

  row = {
    "id" => member_id,
    "name" => display_name,
    "local_status" => local_status,
    "remote_found" => !remote.nil?,
    "remote_source" => remote && remote["source"],
    "remote_date" => remote && remote["date"],
    "action" => action
  }
  if remote && (action == "fetch" || options[:show_report_ids])
    row["report_id"] = remote["report_id"]
  end
  row
end

ops_source = sources.find { |source| source["id"] == "platform-ops-reports" }
ops_document_url = ops_source&.dig("weekly_report_sync_target", "url")

project_source = sources.find { |source| source["id"] == "project-progress" }
local_count = member_rows.count { |row| row["local_status"] }
remote_count = member_rows.count { |row| row["remote_found"] }
department_local_path = root.join("reports/department-weekly", iso_year.to_s, "#{week_key}.md")
department_remote = department_reports.max_by { |report| report["date"] }
department_action =
  if department_remote
    "fetch_authoritative"
  elsif options[:live]
    "generate_local_draft"
  else
    "check_outbox"
  end

result = {
  "period" => {
    "iso_year" => iso_year,
    "iso_week" => format("%02d", iso_week),
    "period_start" => period_start.iso8601,
    "period_end" => period_end.iso8601
  },
  "coverage" => {
    "active_members" => member_rows.length,
    "local_reports" => local_count,
    "local_percent" => member_rows.empty? ? 0 : (local_count * 100.0 / member_rows.length).round(1),
    "dingtalk_reports" => options[:live] ? remote_count : nil
  },
  "members" => member_rows,
  "project_progress" => {
    "configured" => !project_source.nil?,
    "name" => project_source && project_source["display_name"],
    "table_names" => project_source ? Array(project_source["tables"]).map { |table| table["name"] } : []
  },
  "platform_ops" => {
    "document_url" => ops_document_url
  },
  "department_report" => {
    "local_path" => department_local_path.to_s,
    "local_status" => local_report_status(department_local_path),
    "authoritative_source" => department.dig("report_author", "authoritative_source") || "dingtalk_outbox",
    "remote_found" => !department_remote.nil?,
    "remote_date" => department_remote && department_remote["date"],
    "report_id" => department_remote && department_remote["report_id"],
    "action" => department_action
  },
  "report_author" => department["report_author"],
  "live_queries" => options[:live] ? { "inbox" => 1, "outbox" => 1 } : { "inbox" => 0, "outbox" => 0 }
}

puts JSON.pretty_generate(result)
