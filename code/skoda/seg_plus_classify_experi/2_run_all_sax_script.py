# -*- coding: utf-8 -*-
"""
Created on Oct 3 2018

@author: hangwei
"""

import os

cwd = os.getcwd()
################################### the part that you need to modify for different data sets ############################
numRuns = 6
numSaxs = [3, 4, 5, 6, 7, 8, 9, 10]

#########################################################################################################################
totalRuns = range(1, (numRuns + 1)) # 
name_of_methods = ['Binseg', 'BottomUp', 'KCpA', 'Pelt', 'Window', 'Dynp'] # 'Dynp'
# name_of_methods = ['Binseg', 'BottomUp', 'KCpA', 'Pelt', 'Window'] # 'Dynp'

frameFolders = []
frameStart = 'sax_'
nowFolders = [frameStart + now_method_name  for now_method_name in name_of_methods]
nowSubFolders = ['sax_' + str(numSax) + '_experi' for numSax in numSaxs]

for now_folder in nowFolders:
    for nowRun in totalRuns:
        frameFolders.append(now_folder+'_'+str(nowRun))        
number_subfolders = len(frameFolders)    


f_segBased = open(os.path.join(cwd, '2_runAllFolders_sax.sh'), 'w+')



for nowFolder in frameFolders:
    f_segBased.write('cd ' + nowFolder + '\n')
    for segmentSubFolder in nowSubFolders:
        f_segBased.write('cd ' + segmentSubFolder + '\n')
        f_segBased.write('./svm_single.sh\n')
        f_segBased.write('cd ..\n')
    f_segBased.write('cd .. \n')
  


'''
## debug in a non-parallel way
for now_folder in frameFolders:
    os.chdir(now_folder)
    subprocess.call(['./smm_seg_single.sh'])
    os.chdir(cwd)

'''