#!/usr/bin/env ruby -wKU

require ENV['TM_SUPPORT_PATH']+'/lib/exit_codes'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_class_parser'
require ENV['TM_BUNDLE_SUPPORT']+'/lib/asdoc_framework_parser'

HTML_PATH = ENV['TM_SELECTED_FILE']

TextMate.exit_show_tool_tip( "Please Select a File to Parse" ) if HTML_PATH == nil

fp = AsdocFrameworkParser.new
fp.load_framework HTML_PATH
frm_wk = fp.framework_name

TextMate.exit_show_tool_tip( "No Class files found to parse." ) if fp.class_path_list.empty?

# Utility Methods.

def create_from_template template, new_file
    
    template.each do |line|
        if line =~ /SUBSTITUTE_UUID_HERE/
            uuid = `uuidgen`.chomp
            line = line.sub( "SUBSTITUTE_UUID_HERE", uuid )
        end
        new_file.print line
    end
    
end

def make_info name
    info =  '<?xml version="1.0" encoding="UTF-8"?>'+"\n"
    info += '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'+"\n"
    info += '<plist version="1.0">'+"\n"
    info += '<dict>'+"\n"
    info += '<key>contactEmailRot13</key>'+"\n"
    info += '<string>znvagnvare@senzrjbex.bet</string>'+"\n"
    info += '<key>contactName</key>'+"\n"
    info += "<string>#{ENV['TM_FULLNAME']}</string>"+"\n"
    info += '<key>description</key>'+"\n"
    info += '<string>Description</string>'+"\n"
    info += '<key>name</key>'+"\n"
    info += "<string>#{name}</string>"+"\n"
    info += '<key>uuid</key>'+"\n"
    info += '<string>'+`uuidgen`.chomp+'</string>'+"\n"
    info += '</dict>'+"\n"
    info += '</plist>'
end

#Load the framework, parse the html and create data.

cp = AsdocClassParser.new
cp.framework = frm_wk
cp.load_classes fp.class_path_list

# Create the bundle, then write the collected data to file.

TEMPLATES          = ENV['TM_BUNDLE_SUPPORT']+'/data/templates'
DESKTOP            = ENV['HOME']+"/Desktop"
NEW_BUNDLE         = DESKTOP+"/#{frm_wk.capitalize}.tmbundle"
NEW_BUNDLE_SUPPORT = NEW_BUNDLE+"/Support"

Dir.mkdir NEW_BUNDLE
Dir.mkdir NEW_BUNDLE_SUPPORT 
Dir.mkdir NEW_BUNDLE_SUPPORT + "/data"
Dir.mkdir NEW_BUNDLE + "/Syntaxes"
Dir.mkdir NEW_BUNDLE + "/Commands"
Dir.mkdir NEW_BUNDLE + "/Preferences"

lang_file               = File.new( NEW_BUNDLE+"/Syntaxes/#{frm_wk.capitalize}.tmLanguage", "w" )
auto_completions_file   = File.new( NEW_BUNDLE+"/Preferences/Completions.tmPreferences", "w" )
method_completions_file = File.new( NEW_BUNDLE_SUPPORT+"/data/method_completions.txt", "w" )
doc_dictionary          = File.new( NEW_BUNDLE_SUPPORT+"/data/doc_dictionary.xml", "w" )
info_plist              = File.new( NEW_BUNDLE+"/info.plist", "w" )

auto_complete_method_template = File.new( TEMPLATES+"/Auto Complete Function.tmCommand.xml", "r" )
auto_complete_import_template = File.new( TEMPLATES+"/Auto Complete Import.tmCommand.xml", "r" )
help_template                 = File.new( TEMPLATES+"/Help.tmCommand.xml", "r" )

new_auto_complete_method = File.new( NEW_BUNDLE+"/Commands/Auto Complete Function.tmCommand", "w" )
new_auto_complete_import = File.new( NEW_BUNDLE+"/Commands/Auto Complete Import.tmCommand", "w" )
new_help                 = File.new( NEW_BUNDLE+"/Commands/Help.tmCommand", "w" )

create_from_template auto_complete_method_template, new_auto_complete_method
create_from_template auto_complete_import_template, new_auto_complete_import
create_from_template help_template, new_help

lang_file.print cp.framework_language
auto_completions_file.puts cp.auto_completions   
method_completions_file.puts cp.method_completions 
doc_dictionary.print fp.asdoc_dictionary

info_plist.print make_info( frm_wk.capitalize )

print "Complete"
