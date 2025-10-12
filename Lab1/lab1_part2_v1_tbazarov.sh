#!/bin/bash
select choice in 'New file' 'New dir' 'Zip' 'Unzip' 'Delete file or dir' 'Exit'
do
	case $choice in
		'New file' ) IFS= read -p "Enter new file name: " filename; if [ -e "$filename" ]; then echo -en "\033[41mFile already exists!\033[0m"; echo; else touch "$filename"; fi ;;
		'New dir' ) IFS= read -p "Enter new dir name: " dirname; if [ -e "$dirname" ]; then echo -en "\033[41mDirectory already exists!\033[0m"; echo; else mkdir "$dirname"; fi ;;
		'Zip' ) IFS= read -p "Enter name for new archive: " filename;  IFS= read -p "Enter path to archive content: " filenames; tar -cf "$filename.tar.gz" $filenames ;;
		'Unzip' ) IFS= read -p "Enter path to archive for extraction: " filename; tar -xf $filename ;;
		'Delete file or dir' ) IFS= read -p "Enter name to delete: " filename; if [ -e "$filename" ]; then rm -rf "$filename"; else echo -en "\033[41mNo such file or directory!\033[0m"; echo; fi ;;
		'Exit' ) break ;;
		* ) echo -en "\033[41mMenu option does not exist!\033[0m"; echo; ;;
	esac
done
