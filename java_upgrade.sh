#################################################################################
# Author: Sampath Kunapareddy                                                   #
# sampath.a926@gmail.com                                                        #
#################################################################################
#!/bin/bash
#set -x
#Script to upgrade Java to latest version available and update jdk version references with softlink

export PROP_FILE="/software/scripts/middleware.properties"
export NEW_JAVA_VERSION="1.8.0_171"
export DATE=$(date +%m-%d-%Y-%H:%M)
export INSTALL_HOME=`grep "jdkupgrade" ${PROP_FILE} | awk -F'|' '{print $3}'`
export JAVA_HOME=`grep "jdkupgrade" ${PROP_FILE} | awk -F'|' '{print $4}'`
export OLD_JAVA_DIR="/app/java/jdk1.8.0_152"
export NEW_JAVA_DIR="/app/java/jdk1.8.0_192"
export MW_HOME=`grep -inr $1 ${PROP_FILE} | awk -F'|' '{print $6}'`
export ORACLE_HOME=$MW_HOME
export DOMAIN_HOME=`grep -inr $1 ${PROP_FILE} | awk -F'|' '{print $5}'`
export MAILLIST=`grep "jdkupgrade" ${PROP_FILE} | awk -F'|' '{print $6}'`
export JME=$(whoami)
export JUSER=$(ls -ld $JAVA_HOME | awk '{print $3}')

###########################
#  Logging / redirection  #
###########################
STDOUT=/tmp/$(basename $0 .sh)StdOut$$.log
STDERR=/tmp/$(basename $0 .sh)StdErr$$.log
touch $STDOUT; chmod 666 $STDOUT
touch $STDERR; chmod 666 $STDERR

#####################################################
#  Check User ID running Script & switch if needed  #
#####################################################
if [ $JME != $JUSER ]; then
  echo "ERROR: Please run the script as $JUSER user"
  exit 1
  if [ ! -e $INSTALL_HOME/${NEW_JAVA_DIR}".tar.gz" ]; then
    echo "Please check JDK binaries existance under \"$INSTALL_HOME\""
    exit 1
  fi
  if [[ ! -z $(ps -ef | grep $JAVA_HOME | grep -v grep) ]]; then
    clear
	ps -ef | grep "$JAVA_HOME" | grep -v grep
	echo -e "\n\nPlease kill all running processes related to \"$JAVA_HOME\" and re-run the script..\n"
	exit 1
  fi
  PRESENT_JAVA_VERSION=$($JAVA_HOME/bin/java -version 2>&1 | head -1 | awk -F\" '{print $2}')
  if [[ "$PRESENT_JAVA_VERSION" == "$NEW_JAVA_VERSION" ]] || [[ -f $JAVA_HOME/${NEW_JAVA_DIR}/bin/java ]]; then
    echo "Java is already installed in this server"
    exit 1
  else
    echo ""
    echo "Current Java Version : $PRESENT_JAVA_VERSION"
    echo "    New Java Version : $NEW_JAVA_VERSION"
    echo "         Oracle Home : $MW_HOME"
    echo "       WebLogic Home : $WLS_HOME"
    echo "    Installtion Home : $INSTALL_HOME"
	echo ""
	#Backup
	echo -e "\nTaking Backup of \"$JAVA_HOME\""
	tar -xcvf ${JAVA_HOME}_bkp_${DATE}.tar.gz ${JAVA_HOME} &>/dev/null
	ls -lrt ${JAVA_HOME}_bkp_${DATE}.tar.gz
	#Upgrade
	cd $JAVA_HOME
    echo "   Working Directory : `pwd`"
    tar -zxf $Install_HOME/${NEW_JAVA_DIR}.tar.gz
    RC=$?
    if [ $RC -ne 0 ]; then
	  echo "Error while unzipping \"${NEW_JAVA_DIR}.tar.gz\", please check file existance and permissions..."
      exit 1
    fi
    #Softlink for NEW_JAVA_VERSION
    unlink java
    ln -sfn ${NEW_JAVA_DIR} java
    ls -lrt $JAVA_HOME
    ##
    grep -R "${OLD_JAVA_DIR}" $DOMAIN_HOME | grep -vE "^[^:]*.log:|^[^:]*/logs/|^[^:]*/nohupLogs/|^[^:]*/.patch_storage/|^Binary file " > ~/listJavaBefore_DOMAIN_HOME
    grep -R "${OLD_JAVA_DIR}" $ORACLE_HOME | grep -vE "^[^:]*.log:|^[^:]*/logs/|^[^:]*/nohupLogs/|^[^:]*/.patch_storage/|^Binary file " > ~/listJavaBefore_ORACLE_HOME
    ##
    awk -F':' '{print $1}' ~/listJavaBefore_DOMAIN_HOME | sort -u; echo
    awk -F':' '{print $1}' ~/listJavaBefore_ORACLE_HOME | sort -u; echo
    ##
    while read line; do FILE_TO_UPDATE=`echo ${line} | awk -F':' '{print $1}'`; sed -i "s,${OLD_JAVA_DIR},${NEW_JAVA_DIR},g" ${FILE_TO_UPDATE}; done < ~/listJavaBefore_DOMAIN_HOME
    while read line; do FILE_TO_UPDATE=`echo ${line} | awk -F':' '{print $1}'`; sed -i "s,${OLD_JAVA_DIR},${NEW_JAVA_DIR},g" ${FILE_TO_UPDATE}; done < ~/listJavaBefore_ORACLE_HOME
    ##
    sed -i "s/${PRESENT_JAVA_VERSION}/${NEW_JAVA_VERSION}/g" properties
    grep -inr "$PRESENT_JAVA_VERSION" properties
    #Communication
	#Final check of Java Version
    PRESENT_JAVA_VERSION=$($JAVA_HOME/bin/java -version 2>&1 | head -1 | awk -F\" '{print $2}')
	if [[ "$PRESENT_JAVA_VERSION" == "$NEW_JAVA_VERSION" ]]; then
      mail -s "Java Upgrade Success on $(hostname) to ${NEW_JAVA_VERSION}" $MAILLIST  < $STDOUT
    else
      mail -s "Java is upgrade FAILED on $(hostname)" $MAILLIST < $STDERR
    fi
    exit $exitCode
fi

ignore() {
##IGNORE - TO FIND MW_HOME and DOMAIN_HOME
##
#find $MW_HOME -name commBaseEnv.sh
#find $MW_HOME -name commEnv.sh
#find $MW_HOME -name setNMJavaHome.sh
#find $MW_HOME -name nodemanager.properties
##
#find $DOMAIN_HOME -name setDomainEnv.sh
#find $DOMAIN_HOME -name setNMJavaHome.sh
#find $DOMAIN_HOME -name nodemanager.properties
##
##
##IGNORE - to update getProperty and setProperty
##Use the getProperty.sh|cmd script to display the path of the current JDK from the JAVA_HOME variable. For example:
#$ORACLE_HOME/oui/bin/getProperty.sh JAVA_HOME
##Back up the path of the current JDK to another variable such as OLD_JAVA_HOME in the .globalEnv.properties file by entering the following commands
#$ORACLE_HOME/oui/bin/setProperty.sh -name OLD_JAVA_HOME -value specify_the_path_of_current_JDK
##Set the new location of the JDK in the JAVA_HOME variable of the .globalEnv.properties file, by entering the following commands
#$ORACLE_HOME/oui/bin/setProperty.sh -name JAVA_HOME -value specify_the_location_of_new_JDK
}
