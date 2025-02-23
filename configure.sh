#!/bin/bash

## | Variables | ##

UNMOUNTED_DISK_ARR=();  ## | Detected Unmounted Disks in System | ##


## | Functions | ##

diskList(){	## | Disk detection and filling function DISK_ARR | ##

	## | LOCAL Variables | ##

	local COUNTER=1;
	local OUTPUT=$(lsblk -d -n -o NAME | grep "^sd[a-z]$")
	DISK_ARR=($OUTPUT)

	## | FUNCTION Script | ##

	echo -e "\033[34mINFO: \033[0mDisks Detected:\033[0m"

	for i in "${DISK_ARR[@]}"; do
		echo -e "\033[34mINFO: \033[0mBLOCK DEVICE $COUNTER: \033[32m$i\033[0m"
		COUNTER=$((COUNTER + 1))
	done

}

detectUnmountedDisks(){       ## | Detecting unmounted disks | ##

	## | LOCAL Variables | ##

	local DISK="$1";
	local PARTITIONS=$(getPartitions "$DISK");

	## | FUNCTION Script | ##

	if [[ -n "$PARTITIONS" ]]; then
		echo -e "\033[32mPARTITIONS FOUND (Disk \"/dev/$DISK\" is unmounted):\033[0m"
		for PART in $PARTITIONS; do
			echo -e "\033[32m  /dev/$PART\033[0m"
		done
	else
		if isMounted "/dev/$DISK"; then
			echo -e "\033[32mTRUE (Disk \"/dev/$DISK\" is mounted but has no partitions)\033[0m"
		else
			echo -e "\033[31mERROR: \033[0m(Disk \033[35m\"/dev/$DISK\"\033[0m is unmounted and has no partitions)"
			UNMOUNTED_DISK_ARR+=("$DISK")
		fi
	fi


}

printUnmountedDisks() {      ## | Printing Unmounted DISKS and DISKS without partitions for User | ##

	## | LOCAL Variables | ##

	local PRINT=$1;

	## | FUNCTION Script | ##

	echo -e "\033[34mINFO:\033[0m DISKS UNMOUNTED WITHOUT PARTITIONS: \033[35m$PRINT\033[0m";
}

printNullLine() {           ## |Function for correcting script output for user| ##

	## |FUNCTION Script| ##

	echo -e "";
}

isMounted() {   ## | Check if mount in System | ##

	## | LOCAL Variables | ##

	local CHECK="$1";

	## | FUNCTION Script | ##

	mount | grep " $CHECK " > /dev/null ;

	return $?;

}

getPartitions() {    ## | Getting  Partitions on Selected Disk | ##

	## | LOCAL Variable | ##

	local disk="$1";

	## | FUNCTION Script | ##

	lsblk -n -o NAME "/dev/$disk" | grep -P "${disk}[0-9]+$"

}

createZpool() {

	if [[ ${#SELECTED_DISKS[@]} -gt 0 ]]; then
		DISK_LIST=$(printf "/dev/%s " "${SELECTED_DISKS[@]}")
		echo -e "\033[34mINFO: \033[0mСоздание zpool на дисках: $DISK_LIST"
		sudo zpool create mypool $DISK_LIST
		echo -e "\033[32mSUCCESS: \033[0mZpool создан."
	else
		echo -e "\033[31mERROR: \033[0mНе выбраны диски для создания zpool." >&2
	fi
}

## | Script | ##
printNullLine
diskList
printNullLine
for DISK in "${DISK_ARR[@]}"; do
	detectUnmountedDisks "$DISK"
done
printNullLine
for PRINT in "${UNMOUNTED_DISK_ARR[@]}"; do
	printUnmountedDisks $PRINT
done
printNullLine
echo -e "Выберите диски для создания zpool (введите номера через пробел):"
if [ ${#UNMOUNTED_DISK_ARR[@]} -eq 0 ]; then
	echo -e "\033[31mERROR: \033[0mНет доступных дисков без разделов для создания zpool." >&2
	exit 1 # Завершение скрипта, если нет доступных дисков.
else
	select DISK in "${DISK_ARR[@]}"; do
		if [[ -n "$DISK" ]]; then
			SELECTED_DISKS+=("$DISK")
			echo "Диск $DISK добавлен. Выберите еще один или нажмите Enter для завершения выбора."

			read -p "Хотите выбрать еще один диск? (y/n): " choice
			if [[ "$choice" != "y" ]]; then
				break
			fi

		else
			echo "Неверный выбор. Пожалуйста, выберите номер из списка."
		fi
	done
fi
printNullLine
createZpool

