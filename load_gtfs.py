import sys
import glob
import os
import csv
import datetime
import linuxUtils

MIN_NUM_ARGS = 5
DEF_UPDATED_GTFS_FOLDER_NAME = "updated-gtfs"
DEF_GTFS_FILE_EXT = ".txt"
base_mysql_cmd = "mysql -D gtfs -u {db_username} -p{db_password} -ss -e \"{mysql_cmd}\""
base_insert_city_cmd = "INSERT INTO city (city_name,insertion_date) VALUES ('{cityname}','{insert_date}'); SELECT LAST_INSERT_ID();"
base_insert_csv_into_table_cmd = "LOAD DATA LOCAL INFILE '{file_path}' INTO TABLE {table_name} FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES ({columns_names});"

get_columns_name = "mysql -D gtfs -u {db_username} -p{db_password} -ss -e \"SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = '{table_name}';\""

#gtfs_files = ["trips"]
gtfs_files = ["agency","stops","routes","calendar","shapes","trips","stop_times","calendar_dates","fare_attributes","fare_rules","frequencies","transfers","feed_info"]

def printUsage():
    print "load_gtfs.py <gtfs_folder_path> <db_username> <db_password> <city_name>" 

def csv_row_to_str(row):
	return ','.join(row)

def get_csv_header(csv_filepath):
	header = ""
	with open(csv_filepath, 'rb') as csv_file:
		reader = csv.reader(csv_file)
		header = ','.join(next(reader))
	return header

def insersection_between_attributes(csv_path, db_user,db_pwd,table):
	get_column_name_cmd = get_columns_name.format(db_username=db_user,db_password=db_pwd,table_name=table)
	csv_header = get_csv_header(csv_path)

	cmd1 = linuxUtils.LinuxUtils.runLinuxCommand(get_column_name_cmd)
	
	attributes = cmd1[0][0].split()
	list_csv_header = csv_header.split(',')
		
	header = []
	for field in list_csv_header:
		if field in attributes:
			header.append(field)
	
	updated_header = ','.join(header)

	return updated_header


def prepare_insert_city_statement(city_name):
    insertion_date = datetime.date.today().strftime("%Y-%m-%d")
    insert_city_cmd =  base_insert_city_cmd.format(cityname=city_name,insert_date=insertion_date)
    return insert_city_cmd

def prepare_mysql_cmd(db_user,db_pwd,cmd):
	mysql_cmd = base_mysql_cmd.format(db_username=db_user,db_password=db_pwd,mysql_cmd=cmd)
	return mysql_cmd

def prepare_insert_csv_into_table_statement(csv_path,tab_name, field_names):
	insert_csv_into_table_cmd = base_insert_csv_into_table_cmd.format(file_path=csv_path, table_name=tab_name, columns_names=field_names)
	return insert_csv_into_table_cmd

def update_csv_with_city_id(old_csv_filepath,new_csv_filepath,city_id):
	row_num = 0
	with open(old_csv_filepath, 'rb') as f:
		with open(new_csv_filepath, 'w') as f2:
			reader = csv.reader(f)
			writer = csv.writer(f2)			
			
			for row in reader:	
				new_column = []
				if row_num == 0:
					new_column = ["city_id"]
				else:
					new_column = [city_id]
				writer.writerow(new_column + row)
				row_num += 1


if len(sys.argv) < MIN_NUM_ARGS: 
    print "Wrong Usage!"
    printUsage()
    exit(1)

gtfs_folder_path = sys.argv[1]
db_user = sys.argv[2]
db_pwd = sys.argv[3]
city_name = sys.argv[4]

res = linuxUtils.LinuxUtils.runLinuxCommand(prepare_mysql_cmd(db_user,db_pwd,prepare_insert_city_statement(city_name)))
city_id = int(res[0][0])

updated_gtfs_folder = gtfs_folder_path + os.sep + DEF_UPDATED_GTFS_FOLDER_NAME

if not os.path.exists(updated_gtfs_folder):
	os.mkdir(updated_gtfs_folder)

for gtfs_file in gtfs_files:
	print "Processing file: ", gtfs_file
	gtfs_file_path = gtfs_folder_path + os.sep + gtfs_file + DEF_GTFS_FILE_EXT
	new_gtfs_file_path = updated_gtfs_folder + os.sep + gtfs_file + DEF_GTFS_FILE_EXT
	if os.path.isfile(gtfs_file_path):
		update_csv_with_city_id(gtfs_file_path,new_gtfs_file_path,city_id)
		field_names = insersection_between_attributes(new_gtfs_file_path,db_user,db_pwd,gtfs_file)
		insert_table_cmd = prepare_mysql_cmd(db_user,db_pwd,prepare_insert_csv_into_table_statement(new_gtfs_file_path,gtfs_file, field_names))
		print linuxUtils.LinuxUtils.runLinuxCommand(insert_table_cmd)
	else:
		print "GTFS file:", gtfs_file, "not found."

