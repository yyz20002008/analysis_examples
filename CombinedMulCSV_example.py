# -*- coding: utf-8 -*-
"""
Created on Wed Jul 24 11:49:16 2019

@author: yyang
"""
import re
import datetime
import pandas as pd
import pandas.io.formats.excel

from os import listdir
from os.path import join

import csv

begin_time = datetime.datetime.now()
print (begin_time)


mypath = ""
#print(mypath)
csvfiles = [ join(mypath,f) for f in listdir(mypath) if '.csv' in f.lower()]
print(len(csvfiles))
#required columns
col_list=["MemberKey","SubMeasure","DENOMCNT","NUMERCNT","DENOMCT","NUMERCT"]
temp_col=set()

df = pd.DataFrame()

#Print all similar columns, check any columns are not considered
for cf in csvfiles:   
    with open(cf, 'r') as fin:
       reader = csv.DictReader(fin)
       all_col_names = reader.fieldnames
       for a in all_col_names:
           for b in col_list:              
               if b[:6] in a:
                   temp_col.add(a)
print("All Columns:")
print(temp_col)
   
for cf in csvfiles:   
    with open(cf, 'r') as fin:      
        reader = csv.DictReader(fin)
        all_col_names = reader.fieldnames
        selected_col=set(all_col_names).intersection(col_list)
       
        print(cf)
        print(selected_col)
        data = pd.read_csv(cf, usecols=selected_col)
        data.rename(columns = {'DENOMCT':'DENOMCNT',"NUMERCT":"NUMERCNT"}, inplace = True) 
        
        fn=os.path.basename(cf)
 #      print(fn)
        mk=fn.split('_')
 #       print(mk[len(mk)-2])
        data['Measure20'] = mk[len(mk)-2]
        data['org_filename'] = fn
        print("after")
        print(data.columns)
        df = df.append(data)
print(data.org_filename.value_counts())
#df.to_csv( "filesCombined.csv", index=False)

print(datetime.datetime.now())
print("Execution time:"+str(datetime.datetime.now() - begin_time) )   
