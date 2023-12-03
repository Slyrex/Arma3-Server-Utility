#!/bin/bash

#########################################################
# Arma 3 Server Utility by Slyrex Linux Bash Edition for TFJ
#
# Special thanks to DementuZ, Freeman.
#
# This Bash script automates the process of downloading mods for an Arma 3 server.
# It utilizes steamCMD to download mods directly into the server directory, please note the paths are hardcoded; so you will have to set up your linux user as steam and have the directory listed as /home/steam/steamcmd/arma3 for full functionality.
#
# Usage:
# ./script_name.sh -f filename
# ./script_name.sh -p IDfilename paramfile
#
# -f filename: Specifies the file containing a list of mod IDs to download.
# -p IDfilename paramfile: Update the parameter file with mod IDs
# -l filename.html: Parses a html file extracting the ids and putting them into a text document seperating the ids by lines.
# Each mod ID should be on a new line in the file.
# 
# Example:
# To download mods listed in 'mod_list.txt', run:
# ./script_name.sh -f mod_list.txt
#
#########################################################

## Download mod function

download_mod() {
  mod_id=$1
  echo "Appending mod $mod_id to $mods2dl_file"

  # Append the workshop download command for this mod ID
  echo "workshop_download_item 107410 $mod_id validate" >> "$mods2dl_file"
}

# mods2dl file
mods2dl_file="/home/steam/mods2dl"
echo "force_install_dir /home/steam/modsdl" > "$mods2dl_file"
echo "login tfjhost" >> "$mods2dl_file"

# Update Param file function -p
update_param_file() {
  id_filename=$1
  param_file=$2
  ids_to_append=""
  mapfile -t mod_ids < "$id_filename"
  existing_param=$(grep -oP '(?<=-mod=").*(?=")' "$param_file")
  for mod_id in "${mod_ids[@]}"; do
    formatted_id="$mod_id;"
    if [[ ! "$existing_param" =~ "$formatted_id" ]]; then
      ids_to_append+="$formatted_id"
    fi
  done

  new_param="${existing_param}${ids_to_append}"
  sed -i "s|-mod=\"[^\"]*\"|-mod=\"$new_param\"|g" "$param_file"
  
  echo "Arma 3 parameter file updated."
}

# Parse HTML function -l
parse_html_to_txt() {
  html_file=$1
  txt_file="${html_file%.html}.txt"

  grep -o '?id=[0-9]*' "$html_file" | sed 's/?id=//' | sort -u > "$txt_file"

  echo "Mod IDs written to text file: $txt_file"
}

# Flags

# Check for -h
if [[ "$1" == "-h" ]]; then
  echo "-f filename: Specifies the file containing a list of mod IDs to download."
  echo "-p IDfilename paramfile: Update the parameter file with mod IDs"
  echo "-l filename.html: Parses a html file extracting the ids and putting them into a text document seperating the ids by lines."
  echo "-h: prints help"
  exit
fi

# Check for -l flag
if [[ "$1" == "-l" && -n "$2" ]]; then
  html_file=$2
  echo "Parsing HTML file: $html_file"
  parse_html_to_txt "$html_file"
  exit 0
fi

# Check for -p flag
if [[ "$1" == "-p" && -n "$2" && -n "$3" ]]; then
  id_filename=$2
  param_file=$3
  echo "Updating Arma 3 parameter file: $param_file with mod IDs from: $id_filename"
  update_param_file "$id_filename" "$param_file"
  exit 0
fi

# Check for -f flag
if [[ "$1" == "-f" && -n "$2" ]]; then
  filename=$2
  echo "Reading mod IDs from file: $filename"
  mapfile -t mod_ids < "$filename"
  for mod_id in "${mod_ids[@]}"; do
	download_mod $mod_id
  done
  
  echo "exit" >> "$mods2dl_file"
  
  screen -S steamcmd_session /home/steam/steamcmd/steamcmd.sh +runscript "$mods2dl_file"
  for mod_id in "${mod_ids[@]}"; do
	mod_path="/home/steam/modsdl/steamapps/workshop/content/107410/$mod_id"
	if [ -d "$mod_path" ]; then
	  echo "Recursively changing case to lowercase"
	  find "$mod_path" -depth | xargs -n 1 rename 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
	  find "$mod_path" -depth
	  echo "Copying mod $mod_id to /home/steam/steamcmd/arma3"
	  cp -R "$mod_path" "/home/steam/steamcmd/arma3/"
	  else
          echo "Directory for mod $mod_id does not exist. skipping"
	  fi
	done
  
  else
	echo "No file specified or Incorrect flag"
	exit 1
fi
