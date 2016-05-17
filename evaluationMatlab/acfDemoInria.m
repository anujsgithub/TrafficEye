% Demo for aggregate channel features object detector on Inria dataset.
%
% See also acfReadme.m
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.40
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

%% extract training and testing images and ground truth
% cd(fileparts(which('acfDemoInria.m'))); dataDir='../../data/Inria/';
% for s=1:2, pth=dbInfo('InriaTest');
%   if(s==1), set='00'; type='train'; else set='01'; type='test'; end
%   if(exist([dataDir type '/posGt'],'dir')), continue; end
%   seqIo([pth '/videos/set' set '/V000'],'toImgs',[dataDir type '/pos']);
%   seqIo([pth '/videos/set' set '/V001'],'toImgs',[dataDir type '/neg']);
%   V=vbb('vbbLoad',[pth '/annotations/set' set '/V000']);
%   vbb('vbbToFiles',V,[dataDir type '/posGt']);
% end

%% set up opts for training detector (see acfTrain)
dataDir='/Users/koray/Desktop/toolbox/Inria/';
opts=acfTrain(); opts.modelDs=[40 40]; opts.modelDsPad=[45 45];
opts.posGtDir=[dataDir 'train/trafficSignGTAll']; opts.nWeak=[32 128 512 2048 4096];
opts.posImgDir=[dataDir 'train/All_Original_Images']; %opts.pJitter=struct('flip',1);
%opts.negImgDir=[dataDir 'train/neg']; 
opts.pBoost.pTree.fracFtrs=1/16;
opts.pLoad={'squarify',{3,.41}}; opts.name='/Users/koray/Desktop/toolbox/detector/models/AcfLBP';
opts.nPerNeg = 500;
opts.nNeg = 40000;
opts.nAccNeg = 80000;

%% optionally switch to LDCF version of detector (see acfTrain)
if( 1 )
  %opts.filters=[5 4]; 
  opts.pJitter=struct('mPhi',5,'nPhi',5);
  opts.pBoost.pTree.maxDepth=3; 
  opts.pBoost.discrete=0; opts.seed=2;
  %opts.pPyramid.pChns.shrink=2; %opts.name='models/LdcfInria';
  %opts.pPyramid.pChns.pCustom=struct{'enable',1,'name','Std02','hFunc',hFunc};
  hFunc=@(I) codeFunc(I);
  opts.pPyramid.pChns.pCustom=struct('name','Std02','hFunc',hFunc,'enabled',1);
  
end

%% train detector (see acfTrain)
detector = acfTrain( opts );

cascCalVal = 0;

%% modify detector (see acfModify)
pModify=struct('nOctUp',1.1);
detector=acfModify(detector,pModify);

%% run detector on a sample image (see acfDetect)
imgNms=bbGt('getFiles',{[dataDir 'test/pos']}); 
for l=1:numel(imgNms)
    I=imread(imgNms{l}); tic, bbs=acfDetect(I,detector); toc
    bbs2 = bbs(find(bbs(:,5)>20)',:);
    bbs3 =bbs2(find(bbs2(:,1)+bbs2(:,3)<size(I,2))',:);
    bbs4 =bbs3(find(bbs3(:,2)+bbs3(:,4)<size(I,1))',:);
    figure(); im(I); bbApply('draw',bbs4); pause(.1);
end

%Write video file
vidObj = VideoReader('/Users/koray/Desktop/trafficSignVideos/testVideos/EventID_18704652_Front.mp4');

vidHeight = vidObj.Height;
vidWidth = vidObj.Width;

s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);
vw = VideoWriter('/Users/koray/Desktop/trafficSignVideos/testVideos/Results/18704652out.mp4','MPEG-4');
open(vw);
k = 1;
tic
while hasFrame(vidObj)
    s(k).cdata = readFrame(vidObj);
    I=s(k).cdata;
    bbs=acfDetect(I,detector);
    bbs2 = bbs(find(bbs(:,5)>35)',:);
    bbs3 =bbs2(find(bbs2(:,1)+bbs2(:,3)<size(I,2))',:);
    bbs4 =bbs3(find(bbs3(:,2)+bbs3(:,4)<size(I,1))',:);
    bbs5 =bbs4(find(bbs4(:,1)>0)',:);
    bbs6 =bbs5(find(bbs5(:,2)>0)',:);
    J=bbApply('embed', I, floor(bbs6));
    writeVideo(vw,J);
    k = k+1;
end
toc
close(vw);

% %% test detector and plot roc (see acfTest)
% [miss,~,gt,dt]=acfTest('name',opts.name,'imgDir',[dataDir 'test/pos'],...
%   'gtDir',[dataDir 'test/posGt'],'pLoad',opts.pLoad,...
%   'pModify',pModify,'reapply',0,'show',2);
% 
% %% optional timing test for detector (should be ~30 fps)
% if( 0 )
%   detector1=acfModify(detector,'pad',[0 0]); n=60; Is=cell(1,n);
%   for i=1:n, Is{i}=imResample(imread(imgNms{i}),[480 640]); end
%   tic, for i=1:n, acfDetect(Is{i},detector1); end;
%   fprintf('Detector runs at %.2f fps on 640x480 images.\n',n/toc);
% end
% 
% %% optionally show top false positives ('type' can be 'fp','fn','tp','dt')
% if( 0 ), bbGt('cropRes',gt,dt,imgNms,'type','fp','n',50,...
%     'show',3,'dims',opts.modelDs([2 1])); end