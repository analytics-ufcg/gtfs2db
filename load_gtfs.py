import sys
import glob
import os
import csv
import datetime
import linuxUtils

MIN_NUM_ARGS = 5
DEF_GTFS_FILE_EXT = ".txt"
base_mysql_insert_cmd = "mysql -D gtfs -u {db_username} -p{db_password} -e \"LOAD DATA LOCAL INFILE '{file_path}' INTO TABLE {table_name} FIELDS TERMINATED BY ',' IGNORE 1 LINES ({columns_names});\""

gtfs_files = ["agency","stops","routes","calendar","shapes","trips","stop_times","calendar_dates","fare_attributes","fare_rules","frequencies","transfers","feed_info"]

def printUsage():
    print "load_gtfs.py <gtfs_folder_path> <db_username> <db_password> <city_name>" 

def insertCity(linux_utils,city_name,db_user,db_pwd):
    insertion_date = datetime.date.today().strftime("%Y-%m-%d")
    mysql_insert_city_cmd = "mysql -D gtfs -u {db_username} -p{db_password} -ss -e \"INSERT INTO city (city_name,insertion_date) VALUES ('{cityname}','{insert_date}'); SELECT LAST_INSERT_ID();\""
    res = linux_utils.runLinuxCommand(mysql_insert_city_cmd.format(db_username=db_user,db_password=db_pwd,cityname=city_name,insert_date=insertion_date))
    city_id = int(res[0][0])
    return city_id

if len(sys.argv) < MIN_NUM_ARGS: 
    print "Wrong Usage!"
    printUsage()
    exit(1)

gtfs_folder_path = sys.argv[1]
db_user = sys.argv[2]
db_pwd = sys.argv[3]
city_name = sys.argv[4]

#gtfs_files = glob.glob(gtfs_folder_path + os.sep + "*.txt")

city_id = insertCity(linuxUtils.LinuxUtils,city_name,db_user,db_pwd)

for gtfs_file in gtfs_files:
    print "Processing file: ", gtfs_file
    header = ""
    gtfs_file_path = gtfs_folder_path + os.sep + gtfs_file + DEF_GTFS_FILE_EXT
    if os.path.isfile(gtfs_file_path): 
        with open(gtfs_file_path, 'rb') as f:
            reader = csv.reader(f)
            header = ','.join(next(reader))
        insert_cmd = base_mysql_insert_cmd.format(db_username=db_user, db_password=db_pwd, file_path=gtfs_file_path, table_name=gtfs_file, columns_names=header)
        linuxUtils.LinuxUtils.runLinuxCommand(insert_cmd)
    else:
        print "GTFS file:", gtfs_file, "not found."
    
    
