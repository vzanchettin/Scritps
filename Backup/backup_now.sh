#!/bin/bash

GET_DATE=`date +%d-%m-%Y`;
GET_TIME=`date +%H-%M-%S`;
GET_TAR=`which tar`;

# Change the store and log file place
SET_BACKUP_STORAGE="/backups";
SET_LOGFILE="/var/log/backup_now.log";

# Change if you do a tar backup files
SET_TAR_BACKUP_STORAGE="${SET_BACKUP_STORAGE}/tar-backups";
SET_TAR_FOLDER_TO_COPY="/var /etc";

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

		if [ -e ${SET_TAR_BACKUP_STORAGE}${FOLDER} ]; then

			echo "Folder ${SET_TAR_BACKUP_STORAGE}${FOLDER} already exist." >> ${SET_LOGFILE};

		else

			mkdir ${SET_TAR_BACKUP_STORAGE}${FOLDER};

		fi



		GET_DATE=`date +%d-%m-%Y`;
		GET_TIME=`date +%H-%M-%S`;
		GET_DAY=`date +%w`;

		if [ ${GET_DAY} = 5 ]; then

			echo "Day is 1, moving last full backup to a temp file" >> ${SET_LOGFILE};

			mv  ${SET_TAR_BACKUP_STORAGE}${FOLDER}${FOLDER}_${GET_DAY}.tar.gz  ${SET_TAR_BACKUP_STORAGE}${FOLDER}${FOLDER}_${GET_DAY}.tar.gz.old;
			rm -rf ${SET_TAR_BACKUP_STORAGE}${FOLDER}${FOLDER}.snap

		fi

		echo "Starting backup of ${FOLDER} folder." >> ${SET_LOGFILE};
		tar -cvzf ${SET_TAR_BACKUP_STORAGE}${FOLDER}${FOLDER}_${GET_DAY}.tar.gz ${FOLDER} --listed-incremental=${SET_TAR_BACKUP_STORAGE}${FOLDER}${FOLDER}.snap --verbose
		echo "Backup folder ${FOLDER} finished." >> ${SET_LOGFILE};


		if [ -e ${SET_TAR_BACKUP_STORAGE}${FOLDER}${FOLDER}_${GET_DAY}.tar.gz ]; then

			echo "Removing an old backup." >> ${SET_LOGFILE};
			rm -rf ${SET_TAR_BACKUP_STORAGE}${FOLDER}${FOLDER}_${GET_DAY}.tar.gz.old; 

		fi

	done
}

# Dependencies
create_base_directories;

# Backups type
backup_with_tar;
