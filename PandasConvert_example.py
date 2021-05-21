# -*- coding: utf-8 -*-
"""
Created on Thu Jun  6 13:40:55 2019

@author: yyang
"""
import pandas as pd
import pandas.io.formats.excel
mypath = "P:\\"
#print(mypath)
from os import listdir
from os.path import join
#print (listdir(mypath))
textfiles = [ join(mypath,f) for f in listdir(mypath) if '.txt' in f.lower()]
#textfiles2= [join(mypath,f) for f in listdir(mypath) if '.txt' in f]
#print(textfiles2)
#textfiles.extend(textfiles2)
print(textfiles)

df = pd.DataFrame()

for textfile in textfiles:
    df = pd.read_csv(textfile,sep='|', dtype=str)
    #df.dtypes
    #df.ROW = df.ROW.astype(str)
    #print(df.iloc[1])
    #print(df.iloc[2])
    filename=textfile.split('.')[0]
    # Create a Pandas Excel writer  
    # object using XlsxWriter as the engine.  
    writer_object = pd.ExcelWriter(filename+'.xlsx', 
                                    engine ='xlsxwriter') 
    # Write a dataframe to the worksheet.  
    # we turn off the default header 
    # and skip one row because we want 
    # to insert a user defined header there. 

    df.to_excel(writer_object, 'Sheet1', index=False) 
    # Create xlsxwriter workbook object . 
    workbook_object = writer_object.book 
    # Create xlsxwriter worksheet object 
    worksheet_object = writer_object.sheets['Sheet1'] 
    
    # Create a new Format object to formats cells  
    # in worksheets using add_format() method . 
    
   # worksheet_object.conditional_format('B:B', {'type': 'text'})
    
    
    # here we create a format object for header. 
    header_format_object = workbook_object.add_format({ 
                                    'bold': False, 
                                    'border': 0}) 
    # Write the column headers with the defined format. 
    for col_number, value in enumerate(df.columns.values): 
        worksheet_object.write(0, col_number , value,  
                                  header_format_object) 
      
    # Close the Pandas Excel writer  
    # object and output the Excel file.  
    writer_object.save() 