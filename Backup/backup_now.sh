#!/bin/bash

GET_DATE=`date +%d-%m-%Y`;
GET_TIME=`date +%H-%M-%S`;
GET_TAR=`which tar`;

# Change the store and log file place
SET_BACKUP_STORAGE="/backups";
SET_LOGFILE="/var/log/backup_now.log";

# Change if you do a tar backup files
SET_TAR_BACKUP_STORAGE="${SET_BACKUP_STORAGE}/tar-backups";
SET_TAR_FOLDER_TO_COPY="/var/spool /etc /usr/bin"; # Where you can input some folders to backup, like /var/www /home.
SET_DAY_TO_BACKUP_FULL="1"; # Where 1 (mon), 2 (tue), 3 (wed), 4 (thu), 5 (fri) and 6 (sat).

echo "" >> ${SET_LOGFILE};
echo "##########################################" >> ${SET_LOGFILE};
echo "Starting backup ${GET_DATE} at ${GET_TIME}." >> ${SET_LOGFILE};
echo "" >> ${SET_LOGFILE};

function create_base_directories {

	echo "Checking if base directories exist." >> ${SET_LOGFILE};

        if [ -e "${SET_BACKUP_STORAGE}" ]; then

                echo "${SET_BACKUP_STORAGE} already exist." >> ${SET_LOGFILE};

        else

                echo "${SET_BACKUP_STORAGE} does not exist, creating..." >> ${SET_LOGFILE};
		mkdir ${SET_BACKUP_STORAGE};

        fi

        if [ -e "${SET_TAR_BACKUP_STORAGE}" ]; then

                echo "${SET_TAR_BACKUP_STORAGE} already exist." >> ${SET_LOGFILE};

        else

                echo "${SET_TAR_BACKUP_STORAGE} does not exist, creating..." >> ${SET_LOGFILE};
                mkdir ${SET_TAR_BACKUP_STORAGE};

        fi

	echo "" >> ${SET_LOGFILE};

}

function backup_with_tar {

	GET_DATE=`date +%d-%m-%Y`;
	GET_TIME=`date +%H-%M-%S`;
	echo "Starting tar backups at ${GET_DATE} ${GET_TIME}." >> ${SET_LOGFILE};

	for FOLDER in ${SET_TAR_FOLDER_TO_COPY}; do

		GET_FOLDER_NAME=`echo ${FOLDER} | sed 's/\///g'`;

		if [ -e ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME} ]; then

			echo "Folder ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME} already exist." >> ${SET_LOGFILE};

		else

			echo "${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME} does not exist, creating..." >> ${SET_LOGFILE};
			mkdir ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME};

		fi

		GET_DATE=`date +%d-%m-%Y`;
		GET_TIME=`date +%H-%M-%S`;
		GET_DAY=`date +%w`;

		if [ ${GET_DAY} = ${SET_DAY_TO_BACKUP_FULL} ]; then

			echo "Day is ${SET_DAY_TO_BACKUP_FULL}, moving last full backup to a temp file" >> ${SET_LOGFILE};

			mv  ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz  ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz.old;
			rm -rf ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}.snap

		fi

		echo "Starting backup of ${FOLDER} folder." >> ${SET_LOGFILE};
		tar -cvzf ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz ${FOLDER} --listed-incremental=${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}.snap --verbose
		echo "Backup folder ${FOLDER} finished." >> ${SET_LOGFILE};


		if [ -e ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz.old ]; then

			echo "Removing an old backup." >> ${SET_LOGFILE};
			rm -rf ${SET_TAR_BACKUP_STORAGE}${FOLDER}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz.old; 

		fi

	done
}

# Dependencies
create_base_directories;

# Backups type
backup_with_tar;
