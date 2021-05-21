# -*- coding: utf-8 -*-
"""
Created on Tue Jun  2 09:20:21 2020

@author: yyang

"""
import pandas as pd
import numpy as np
from os import listdir
from os.path import join
import shutil
import pyodbc
import os
import glob
import openpyxl 
import re
import time

import win32com.client as win32
from win32com.client.gencache import EnsureDispatch
from win32com.client import constants
from PIL import ImageGrab

#get CSM email list
CSMpath='\\Client CSM List.xlsx'
CSMEmail_df = pd.read_excel(CSMpath, sheet_name='Sheet1',skiprows= 1)

# print whole sheet data


    
#find initiation form
mypath = "\\InitiationAutomation\\"
textfiles = [ f for f in listdir(mypath) if '.xlsx' in f.lower()]
print (textfiles)


for t in textfiles:
    clientname=''
    lob=''
    month=''
    for i in CSMEmail_df['Client']:
        reg=re.compile("(.*)"+i+"(.*)")
        if bool(re.match(reg, t)):
            CSMemail=CSMEmail_df[CSMEmail_df['Client'].str.contains(i)]['Email'].values.astype(str)[0]
            CSMemail+=';'+CSMEmail_df[CSMEmail_df['Client'].str.contains(i)]['CSM Lead Email'].values.astype(str)[0]
            clientname=CSMEmail_df[CSMEmail_df['Client'].str.contains(i)]['OfficialName'].values.astype(str)[0]
            break
    
    print (CSMemail)
    print (clientname)
    #get LOB and Month
    xl = pd.ExcelFile(os.path.join(mypath+t))
    sheetname=xl.sheet_names[0]
    initia_df = pd.read_excel(xl, sheetname)
    lob_tp=np.where(initia_df.values == 'LOB')
    #print(xl.sheet_names)
    lob=initia_df.iloc[lob_tp[0],lob_tp[1]+1].values.astype(str)[0][0]
    
    mon_tp=np.where(initia_df.values == 'MMDM Month')
    month=initia_df.iloc[mon_tp[0],mon_tp[1]+1].values.astype(str)[0][0]
    
    if clientname!='' and lob!='' and month!='':
        outlook = win32.Dispatch('outlook.application')
        mail = outlook.CreateItem(0)
        # To attach a file to the email (optional):
        attachment  = mypath+t
        print(attachment)
        mail.Attachments.Add(attachment)
        #mail.From = 'RXU@inovalon.com'
        mail.To = 'XXX@XXX'
        
        mail.Cc='XXX@XXX'+CSMemail
        mail.Subject = 'Initiation : '+ clientname+' : '+lob+' '+ month
        
        xl = EnsureDispatch('Excel.Application')
        wb = xl.Workbooks.Open(mypath+t)
        
       
        ws = wb.Worksheets(1)
        ws.Range("A1:C50").Copy()
        

        mail.Display()
        #mail.Send()
        inspector = outlook.ActiveInspector()
        word_editor = inspector.WordEditor
        word_range = word_editor.Application.ActiveDocument.Content
        word_range.PasteExcelTable(False, False, True)
        wb.Close()
        
        #move files to archive
        dst="/Archive/"
        shutil.move(join(mypath,t), dst)
    else: continue
    time.sleep(3)   