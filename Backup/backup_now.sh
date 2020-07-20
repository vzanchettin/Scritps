#!/bin/bash

# Global
GET_DATE=`date +%d-%m-%Y`;
GET_TIME=`date +%H-%M-%S`;
GET_DAY=`date +%w`;

SET_MV_BINARY=`which mv`;
SET_CP_BINARY=`which cp`;
SET_RM_BINARY=`which rm`;
SET_MKDIR_BINARY=`which mkdir`;
SET_SENDEMAIL_BINARY=`which sendemail`;

# Change the store and log file place
SET_BACKUP_STORAGE="/backups";
SET_LOGFILE="/var/log/backup_now.log";

# Change to send e-mails
SET_SMTP_HOST="webmail.cliente.com.br:587";
SET_SMTP_USER="backups@cliente.com.br";
SET_SMTP_PASS="HsuEc8scEd";
SET_SMTP_SUBJECT="Backup cliente";
SET_SMTP_BODY="Backup automatico do cliente";
SET_SMTP_SENDER="backups@cliente.com.br";
SET_SMTP_RECIPIENT="cliente@cliente.com.br";

# Change if you do a tar backup files
SET_TAR_BINARY=`which tar`;
SET_TAR_BACKUP_STORAGE="${SET_BACKUP_STORAGE}/tar-backups";
SET_TAR_FOLDER_TO_COPY="/home /etc"; # Where you can input some folders to backup, like /var/www /home.
SET_DAY_TO_BACKUP_FULL="1"; # Where 1 (mon), 2 (tue), 3 (wed), 4 (thu), 5 (fri) and 6 (sat).

# Change if you do a mysql backup
SET_MYSQL_BACKUP_STORAGE="${SET_BACKUP_STORAGE}/mysql-backups";
SET_MYSQL_BINARY=`which mysql`;
SET_MYSQLDUMP_BINARY=`which mysqldump`;
SET_MYSQL_HOST="localhost";
SET_MYSQL_USER="root";
SET_MYSQL_PASS="root123";
GET_MYSQL_DATABASES=`${SET_MYSQL_BINARY} -u${SET_MYSQL_USER} -h${SET_MYSQL_HOST} -p${SET_MYSQL_PASS} -e "SHOW DATABASES" | sort | sed '/Database\|information_schema\|performance_schema/d'`;

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
		${SET_MKDIR_BINARY} ${SET_BACKUP_STORAGE};

        fi

        if [ -e "${SET_TAR_BACKUP_STORAGE}" ]; then

                echo "${SET_TAR_BACKUP_STORAGE} already exist." >> ${SET_LOGFILE};

        else

                echo "${SET_TAR_BACKUP_STORAGE} does not exist, creating..." >> ${SET_LOGFILE};
                ${SET_MKDIR_BINARY} ${SET_TAR_BACKUP_STORAGE};

        fi

        if [ -e ${SET_MYSQL_BACKUP_STORAGE} ]; then

                echo "Folder ${SET_MYSQL_BACKUP_STORAGE} already exist." >> ${SET_LOGFILE};

        else

                echo "${SET_MYSQL_BACKUP_STORAGE} does not exist, creating..." >> ${SET_LOGFILE};
                ${SET_MKDIR_BINARY} ${SET_MYSQL_BACKUP_STORAGE};

        fi

	echo "" >> ${SET_LOGFILE};

}

function sendemail_to_admin {

	${SET_SENDEMAIL_BINARY} -xu ${SET_SMTP_USER} -xp ${SET_SMTP_PASS} -f ${SET_SMTP_SENDER} -t ${SET_SMTP_RECIPIENT} -o tls=auto \
	-s ${SET_SMTP_HOST} -u ${SET_SMTP_SUBJECT} -m ${SET_SMTP_BODY} -a $1 

}

function backup_with_tar {

	GET_DATE=`date +%d-%m-%Y`;
	GET_TIME=`date +%H-%M-%S`;
	echo "Starting tar backups at ${GET_DATE} ${GET_TIME}." >> ${SET_LOGFILE};
	echo "" >> ${SET_LOGFILE};

	for FOLDER in ${SET_TAR_FOLDER_TO_COPY}; do

		GET_FOLDER_NAME=`echo ${FOLDER} | sed 's/\///g'`;

		if [ -e ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME} ]; then

			echo "Folder ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME} already exist." >> ${SET_LOGFILE};

		else

			echo "${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME} does not exist, creating..." >> ${SET_LOGFILE};
			${SET_MKDIR_BINARY} ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME};

		fi

		GET_DATE=`date +%d-%m-%Y`;
		GET_TIME=`date +%H-%M-%S`;
		GET_DAY=`date +%w`;

		if [ ${GET_DAY} = ${SET_DAY_TO_BACKUP_FULL} ]; then

			echo "Day is ${SET_DAY_TO_BACKUP_FULL}, moving last full backup to a temp file" >> ${SET_LOGFILE};

			${SET_MV_BINARY}  ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz  ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz.old;
			${SET_RM_BINARY} -rf ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}.snap

		fi

		echo "Starting backup of ${FOLDER} folder." >> ${SET_LOGFILE};
		${SET_TAR_BINARY} -cvzf ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz ${FOLDER} --listed-incremental=${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}.snap --verbose
		echo "Backup folder ${FOLDER} is finished." >> ${SET_LOGFILE};

		GET_TAR_FILE_SIZE=`du -sh ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz |cut -f1`;
		echo "Backuped size of ${FOLDER} is ${GET_TAR_FILE_SIZE}." >> ${SET_LOGFILE};

		if [ -e ${SET_TAR_BACKUP_STORAGE}/${GET_FOLDER_NAME}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz.old ]; then

			echo "Removing an old backup." >> ${SET_LOGFILE};
			${SET_RM_BINARY} -rf ${SET_TAR_BACKUP_STORAGE}${FOLDER}/${GET_FOLDER_NAME}_${GET_DAY}.tar.gz.old;

		fi

	echo "" >> ${SET_LOGFILE};

	done
}

function backup_with_mysqldump {

        GET_DATE=`date +%d-%m-%Y`;
        GET_TIME=`date +%H-%M-%S`;
        echo "Starting MySQL backups at ${GET_DATE} ${GET_TIME}." >> ${SET_LOGFILE};
        echo "" >> ${SET_LOGFILE};


	for DATABASE in ${GET_MYSQL_DATABASES}; do

                GET_DATE=`date +%d-%m-%Y`;
                GET_TIME=`date +%H-%M-%S`;
                GET_DAY=`date +%w`;

                echo "Starting backup of ${DATABASE} mysql database." >> ${SET_LOGFILE};
		${SET_MYSQLDUMP_BINARY} -u${SET_MYSQL_USER} -h${SET_MYSQL_HOST} -p${SET_MYSQL_PASS} --databases ${DATABASE} | gzip > ${SET_MYSQL_BACKUP_STORAGE}/${DATABASE}_${GET_DAY}.sql.gz
                echo "Backup mysql database ${DATABASE} is finished." >> ${SET_LOGFILE};

		GET_MYSQL_FILE_SIZE=`du -sh ${SET_MYSQL_BACKUP_STORAGE}/${DATABASE}_${GET_DAY}.sql.gz |cut -f1`;
                echo "Backuped size of ${DATABASE} is ${GET_MYSQL_FILE_SIZE}." >> ${SET_LOGFILE};

		echo "Sending the database ${DATABASE} to mail." >> ${SET_LOGFILE};
		sendemail_to_admin ${SET_MYSQL_BACKUP_STORAGE}/${DATABASE}_${GET_DAY}.sql.gz;

		echo "" >> ${SET_LOGFILE};

	done

}

# Dependencies
create_base_directories;

# Uncoment the backups type you want to do
backup_with_tar;
backup_with_mysqldump;

