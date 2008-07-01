#!/usr/bin/env ruby -wKU

require ENV['TM_SUPPORT_PATH']+'/lib/exit_codes'
require ENV['TM_SUPPORT_PATH']+'/lib/web_preview'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_class_parser'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_framework_parser'

STDOUT.sync = true;

html_header "ActionScript 3 Framework Language Generator"
puts "<h1>Starting parse</h1><pre>"

HTML_PATH = ENV['TM_SELECTED_FILE']

TextMate.exit_show_tool_tip( "Please Select a File to Parse" ) if HTML_PATH == nil

fp = AsdocFrameworkParser.new
fp.logging_enabled = true
fp.load_framework HTML_PATH

TextMate.exit_show_tool_tip( "No Class files found to parse." ) if fp.class_path_list.empty?

cp = AsdocClassParser.new
cp.logging_enabled = true
cp.framework = fp.framework_name
cp.load_classes fp.class_path_list

puts "</pre><br/><br/><pre>"

print cp.framework_language

puts "</pre>"

html_footer

# log