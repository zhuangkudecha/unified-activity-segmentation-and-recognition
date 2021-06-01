% this script is to generate data for ECDF feature extraction and SVM classification under various segmentation
% results.
% learn from experi_smm_classify_with_various_seg.m
% by Hangwei, 18-Oct-2018 17:13:54

clear all
clc
addpath(genpath(pwd));

numEcdfs = [5;15;30;45];

load('ps1_pocket_data.mat');
number_ind = bkps_true(size(bkps_true, 1), 1);
subfolder_str = './seg_results/';
win_size = 100;
rng('default');

% name_of_methods = {'Binseg'; 'BottomUp'; 'KCpA'; 'Pelt'; 'Window'; 'Dynp'};
name_of_methods = {'Binseg'; 'BottomUp'; 'KCpA'; 'Pelt'; 'Window'; 'Dynp'};

n_frames = size(bkps_true, 1);

% Window/Pelt/KCpA cannot make sure the # are the exact number
num_methods = size(name_of_methods, 1);
results_cell = cell(1,1);
for i = 1: num_methods
    now_method = name_of_methods{i, 1};
    if(strcmp(now_method, 'Window'))
        fID_segment = fopen(strcat(subfolder_str, now_method, '_', num2str(number_ind), '_', num2str(win_size), '.txt'),'r'); % 'Dynp_5000.txt', 'window1000_50.txt', 'Dynp_1000.txt'        
    else
        fID_segment = fopen(strcat(subfolder_str, now_method, '_', num2str(number_ind), '.txt'),'r'); % 'Dynp_5000.txt', 'window1000_50.txt', 'Dynp_1000.txt'
    end
    bkps_predict = textscan(fID_segment, '%d');
    bkps_predict = double(bkps_predict{1,1} + 1);
    if(size(bkps_predict, 1) ~= n_frames)
        bkps_predict = f_deal_with_insufficient_bkps(bkps_predict, n_frames);
    end
    unordered_seg_chunks = func_genearte_seg_chunks(bkps_predict, unordered_chunk_label, unordered_frame);
    
    % split different label's data into different cells
    for i = 1:size(allLabels, 1)
        nowLabel = allLabels(i);
        if(nowLabel < 0)
            tmpVar = strcat('unordered_seg_classMinus', int2str(-nowLabel));
        else
            tmpVar = strcat('unordered_seg_class', int2str(nowLabel));
        end
        nowInd = find(unordered_chunk_label(:,1) == nowLabel);
        assignin('base', tmpVar, unordered_seg_chunks(nowInd, :));
    end

% split train and test data based on subjects
numFeatures = 60;
trainTestSubjectsRatio = 0.7;
nowRatio = num2str(trainTestSubjectsRatio);
% get the size of different classes
for i = 1:length(allLabels)
    numEntrySet(i, 1) = length(find(unordered_chunk_label == allLabels(i, 1)));
end
numClass = length(allLabels);
numRuns = 6;
load(strcat('trainSubjects_pocket_', nowRatio,'.mat'));

experi_folder_str = './seg_plus_classify_experi'
if(~exist(experi_folder_str, 'dir'))
    mkdir(experi_folder_str);
    fileattrib(experi_folder_str, '+w');
end
cd(experi_folder_str);

for tmpFolderIndn = 1: numRuns    
    tmpFolderInd = int2str(tmpFolderIndn)
    tmpFolderPath = strcat('ecdf_', now_method, '_', tmpFolderInd);
    if(~exist(tmpFolderPath, 'dir'))
        mkdir(tmpFolderPath);
        fileattrib(tmpFolderPath, '+w');
    end
    cd(tmpFolderPath);

    trainCell = cell(1,1);
    testCell = cell(1,1);
    trainInd = 1;
    testInd = 1;
for tmpClass = 1: length(allLabels) % class
    trainDataPool = eval(strcat('unordered_seg_class', int2str(allLabels(tmpClass))));
    testDataPool = eval(strcat('class', int2str(allLabels(tmpClass))));   
    assert(size(trainDataPool, 1) == size(testDataPool, 1));
    trainSubject = trainEntryAll{tmpClass, 1}(tmpFolderIndn, :);% train/test split for this class, this folder
    for i = 1:size(trainDataPool, 1)
        if(ismember(i, trainSubject))
            trainCell{trainInd, 1} = trainDataPool{i, 1}; % data
            trainCell{trainInd, 2} = trainDataPool{i, 2}; % class label
            trainInd = trainInd + 1;
        else
            testCell{testInd, 1} = testDataPool{i, 1};
            testCell{testInd, 2} = testInd;
            testCell{testInd, 3} = testDataPool{i, 2};
            testInd = testInd + 1;
        end
    end
end
% sort the training data based on labels
trainR = size(trainCell, 1);
testR = size(testCell, 1);
actiLabel = zeros(trainR, 1);
for i = 1: trainR
    actiLabel(i,1) = trainCell{i,2};
end
[B, I] = sort(actiLabel);
sortedTrainCell = cell(trainR, 3);
for i = 1: trainR
    sortedTrainCell{i,1} = trainCell{I(i,1),1}; % chunked data
    sortedTrainCell{i,2} = i;
    sortedTrainCell{i,3} = trainCell{I(i,1),2}; % label
end

% start to modify codes for ECDF, by Hangwei, 29-Oct-2018 10:57:45

for nowInd_ecdf = 1:length(numEcdfs)  % modified by hangwei, 10-Sep-2017 11:25:26
    nowMoment = numEcdfs(nowInd_ecdf, 1);
    nowFolder = strcat('ecdf_',num2str(nowMoment), '_experi');
    if(~exist(nowFolder, 'dir'))
        mkdir(nowFolder);
        fileattrib(nowFolder, '+w');
    end
    cd(nowFolder);
firstInd = 1; 

label_ = [];
group_ = [];
data_ = [];
label_t = [];
group_t = [];
data_t = []; 
for i = 1: trainR
    tmpData = sortedTrainCell{i,1};
    label_(firstInd,1) = sortedTrainCell{i,3};
    group_(firstInd,1) = i;
    %%%%%%%%%%%%%%%%%%%%%%
    m_ecdf = mean(tmpData,1)'; 
    data_ecdf = sort(tmpData,1);
    data_ecdf = data_ecdf(round(linspace(1,size(data_ecdf,1), nowMoment)),:);
    data_ecdf = [data_ecdf(:) ; m_ecdf]; 
    data_(i, :) = data_ecdf';
    %%%%%%%%%%%%%%%%%%%%%%
    firstInd = firstInd + 1;
end


firstInd = 1;
for i = 1: testR
    tmpData = testCell{i,1};    
    label_t(firstInd,1) = testCell{i,3};
    group_t(firstInd,1) = i;
    
    %%%%%%%%%%%%%%%%%%%%%%
    m_ecdf = mean(tmpData,1)'; 
    data_ecdf = sort(tmpData,1);
    data_ecdf = data_ecdf(round(linspace(1,size(data_ecdf,1), nowMoment)),:);
    data_ecdf = [data_ecdf(:) ; m_ecdf]; 
    data_t(i, :) = data_ecdf';
    %%%%%%%%%%%%%%%%%%%%%%
    firstInd = firstInd + 1;
end



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%deal with NaN in data
%%% deal with NaN values in the training data
[R_data_, C_data_] = size(data_);
data_new = zeros(R_data_, C_data_);

for k = 1:length(allLabels)
    tmpInd = strcat('Ind', num2str(k));
    tmpMean = strcat('mean', num2str(k));
    tmpR = strcat('tmpR', num2str(k));
    tmpaa = strcat('aa', num2str(k));
    tmpMeanRep = strcat('mean',num2str(k),'Rep');
    assignin('base', tmpInd, find(label_(:,1) == allLabels(k)));
    assignin('base', tmpMean, mean(data_(eval(tmpInd),:), 'omitnan'));
    assignin('base', tmpR, size(eval(tmpInd),1));
    assignin('base', tmpMeanRep, repmat(eval(tmpMean), eval(tmpR), 1));
    assignin('base', tmpaa, isnan(data_(eval(tmpInd),:)));
    if k == 1
        data_(isnan(data_)) = 0;
    end
    data_new(eval(tmpInd),:) = data_(eval(tmpInd),:) + eval(tmpaa).*eval(tmpMeanRep);
end
% NaN in test data
[R_data_t, C_data_t] = size(data_t);
data_new_t = zeros(R_data_t, C_data_t);

for k = 1:length(allLabels)
    tmpInd = strcat('Ind', num2str(k),'t');
    tmpMean = strcat('mean', num2str(k),'t');
    tmpR = strcat('tmpR', num2str(k),'t');
    tmpaa = strcat('aa', num2str(k),'t');
    tmpMeanRep = strcat('mean',num2str(k),'Rept');
    assignin('base', tmpInd, find(label_t(:,1) == allLabels(k))); %%%%
    assignin('base', tmpMean, mean(data_t(eval(tmpInd),:), 'omitnan'));%%%%
    assignin('base', tmpR, size(eval(tmpInd),1)); %%%%
    %assignin('base', strcat('tmpC', num2str(k)), size(eval(tmpInd),2));
    assignin('base', tmpMeanRep, repmat(eval(tmpMean), eval(tmpR), 1));
    assignin('base', tmpaa, isnan(data_t(eval(tmpInd),:)));
    if k == 1
        data_t(isnan(data_t)) = 0;
    end
    data_new_t(eval(tmpInd),:) = data_t(eval(tmpInd),:) + eval(tmpaa).*eval(tmpMeanRep);
end


% do the PCA to train data and deal with test data with the same parameter
[n,m] = size(data_new);
trainMean = mean(data_new);
[p,q] = size(std(data_new));
trainStd = std(data_new); %+ repmat(0.01,p,q); % add a small number

% the calculated contains NaN because of the denominator has 0, and divide
% 0
trainData_std = (data_new - repmat(trainMean,[n,1]))./repmat(trainStd,[n,1]);

[pca_coeff, score, eigenvalues, ~, explained,mu] = pca(trainData_std); %princomp also works
pcaDim = 0;
for i = 1:length(explained)
    if(sum(explained(1:i)) >= 90)
        pcaDim = i
        break;
    end
end
if(pcaDim == 0)
    disp('Error: pcaDim == 0!!!!');
end
trainData_std_pca = score(:,1:pcaDim);

%testing data
[n2,m2] = size(data_new_t);
data_noClass0_std_t = (data_new_t - repmat(trainMean,[n2,1]))./repmat(trainStd,[n2,1]);
data_noClass0_std_t_tmp = data_noClass0_std_t * pca_coeff;
testData_std_pca = data_noClass0_std_t_tmp(:,1:pcaDim);

libsvmwrite('svm.train', label_, sparse(trainData_std_pca));
libsvmwrite('svm.test', label_t, sparse(testData_std_pca));

system('cp /home/hangwei/Documents/segment_Hangwei/code_final/skoda/seg_plus_classify_experi/svm-train ./');
system('cp /home/hangwei/Documents/segment_Hangwei/code_final/skoda/seg_plus_classify_experi/svm-predict ./');
system('cp /home/hangwei/Documents/segment_Hangwei/code_final/skoda/seg_plus_classify_experi/svm_single.sh ./');

save('train.mat', 'label_','group_','trainData_std_pca', 'allLabels');
save('test.mat','label_t','group_t', 'testData_std_pca', 'allLabels');

cd ..
% fileattrib(tmpFolderPath, '+w'); % remove the writing permission of the whole folder
end 
cd ..
end
cd ..
end


function [unordered_seg_chunks] = func_genearte_seg_chunks(bkps_predict, unordered_chunk_label, unordered_frame)
    unordered_seg_chunks = cell(1,1);
    for now_n_seg = 1:size(bkps_predict, 1)
        if(now_n_seg == 1)
            start_ind = 1;
        else
            start_ind = bkps_predict((now_n_seg-1), 1) + 1;
        end
        end_ind = bkps_predict(now_n_seg, 1);
        unordered_seg_chunks{now_n_seg, 1} = unordered_frame(start_ind:end_ind, :);
        unordered_seg_chunks{now_n_seg, 2} = unordered_chunk_label(now_n_seg, 1);
    end
end


function [bkps_predict] = f_deal_with_insufficient_bkps(bkps_predict, n_frames)
now_n_bkps = size(bkps_predict, 1);
max_frame = bkps_predict(now_n_bkps, 1);
if(now_n_bkps > n_frames) % need to delete several bkps
    n_more_bkps = now_n_bkps - n_frames;
    % delete_ind = randi([2, (now_n_bkps - 1)], [n_more_bkps, 1]);
    delete_ind = (randperm(now_n_bkps -1, n_more_bkps))';
    bkps_predict(delete_ind, :) = [];
else % need to add several bkps
    n_less_bkps = n_frames - now_n_bkps;
    
    while(n_less_bkps ~= 0)
        tmp_ind = randi([2, max_frame-1]);
        if(size(find(bkps_predict == tmp_ind), 1) == 0)
            bkps_predict = [bkps_predict; tmp_ind];
            n_less_bkps = n_less_bkps - 1;
        end
    end
    bkps_predict = sort(bkps_predict);
end
end




